import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/features/guard/domain/bible_passages.dart';
import 'package:unchained/features/guard/lock_visibility.dart';
import 'package:unchained/features/guard/uninstall_guard_service.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';
import 'package:unchained/features/prayer/domain/prayer_strings.dart';
import 'package:unchained/features/prayer/domain/prayers.dart';

/// Why the lock is showing.
enum LockMode {
  /// The watchdog caught an uninstall / force-stop attempt. Passing earns a grace
  /// window and backgrounds the app so the user can proceed if they're determined.
  block,

  /// The user asked, inside the app, to turn protection off. Passing disables it.
  disable,
}

/// Full-screen, back-proof gate: copy out 800 characters of Scripture within four
/// minutes. Run out of time and what you typed is wiped and a fresh passage begins.
/// There is no other way off this screen (except Cancel in [LockMode.disable]).
class ScriptureLockScreen extends ConsumerStatefulWidget {
  const ScriptureLockScreen({super.key, this.mode = LockMode.block});

  final LockMode mode;

  @override
  ConsumerState<ScriptureLockScreen> createState() =>
      _ScriptureLockScreenState();
}

class _ScriptureLockScreenState extends ConsumerState<ScriptureLockScreen> {
  static const Duration _limit = Duration(minutes: 4);
  /// How many characters of the passage the user must copy to pass. Every
  /// passage in [BiblePassages] is longer than this, so it is always reachable.
  static const int _requiredChars = 800;
  static const Color _accent = Color(0xFF1E5FFF);
  static const Color _good = Color(0xFF34C759);
  static const Color _bad = Color(0xFFFF4D4F);
  static const Color _dim = Color(0xFF55606F);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// Which of the (language-independent) passages this attempt uses. The text
  /// shown is [BiblePassages.at] of this index in the current [_lang], so
  /// switching language keeps the same passage.
  late int _passageIndex;

  /// The language of the passage the user is copying. Kept in sync with the
  /// shared [appLanguageProvider] on every build; defaults to Spanish.
  Lang _lang = Lang.es;

  /// The current passage in the selected language.
  String get _passage => BiblePassages.at(_passageIndex, _lang);

  Timer? _timer;
  int _secondsLeft = _limit.inSeconds;
  bool _passed = false;

  @override
  void initState() {
    super.initState();
    // Hide the app's footer chrome for the whole lifetime of the lock, so the
    // user sees only the 800 letters. The watchdog path sets this synchronously
    // before navigating (no first-frame footer); here we defer to a post-frame
    // callback so toggling the ancestor listener never fires during build. Both
    // are idempotent — this also covers the in-app "turn off" path.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scriptureLockActive.value = true;
    });
    _passageIndex = BiblePassages.randomIndex();
    _controller.addListener(_onChanged);
    _startTimer();
  }

  @override
  void dispose() {
    // Lock is leaving the screen — restore the footer on every other route.
    // Defer so we don't mark an ancestor dirty mid-teardown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scriptureLockActive.value = false;
    });
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = _limit.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _restart();
    });
  }

  /// Time's up: wipe everything and begin again with a fresh passage.
  void _restart() {
    _controller.clear();
    setState(() =>
        _passageIndex = BiblePassages.randomIndex(previous: _passageIndex));
    _startTimer();
  }

  void _onChanged() {
    if (_passed) return;
    if (_isComplete) _succeed();
    setState(() {}); // refresh progress / highlight
  }

  /// The slice of the current passage the user must copy: the first
  /// [_requiredChars] characters, extended forward to the next word boundary so
  /// the challenge never ends mid-word. Always at least [_requiredChars] long
  /// because every passage is longer than that (defensive fallback to the whole
  /// passage if a shorter one is ever added, so the screen can never soft-lock).
  String get _challenge {
    final passage = _passage;
    if (_requiredChars >= passage.length) return passage;
    var end = _requiredChars;
    while (end < passage.length && passage.codeUnitAt(end) != 0x20) {
      end++;
    }
    return passage.substring(0, end);
  }

  bool get _isComplete => _matched >= _challenge.length;

  /// Number of leading characters of [_challenge] typed correctly
  /// (case-insensitive).
  int get _matched {
    final input = _controller.text.toLowerCase();
    final target = _challenge.toLowerCase();
    final n = input.length < target.length ? input.length : target.length;
    var i = 0;
    while (i < n && input.codeUnitAt(i) == target.codeUnitAt(i)) {
      i++;
    }
    return i;
  }

  Future<void> _succeed() async {
    if (_passed) return;
    _passed = true;
    _timer?.cancel();
    _focus.unfocus();

    if (widget.mode == LockMode.disable) {
      await UninstallGuardService.setGuardEnabled(false);
      // Lift the OS-level hard block and step down as device admin, now that the
      // challenge has been passed.
      await UninstallGuardService.removeDeviceAdmin();
      if (mounted) Navigator.of(context).maybePop();
      return;
    }

    // block mode: open the grace window, then step out of the way.
    await UninstallGuardService.challengePassed();
    await SystemNavigator.pop();
  }

  String get _clock {
    final m = (_secondsLeft ~/ 60).toString();
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Drive the passage + UI language from the same setting the prayer screens
    // use, so a change in either place carries over. When the user switches
    // language mid-challenge, wipe what they typed (it was in the old language).
    ref.listen(appLanguageProvider, (prev, next) {
      final was = prev?.asData?.value;
      final now = next.asData?.value;
      if (now != null && was != null && now != was) _controller.clear();
    });
    _lang = ref.watch(appLanguageProvider).asData?.value ?? Lang.es;

    final matched = _matched;
    final total = _challenge.length;
    final urgent = _secondsLeft <= 20;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: _accent, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.mode == LockMode.disable
                            ? PS.turnOffProtection(_lang)
                            : PS.stayUnchained(_lang),
                        style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    _languageButton(),
                    const SizedBox(width: 8),
                    Text(
                      _clock,
                      style: GoogleFonts.robotoMono(
                        color: urgent ? _bad : Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  PS.copyScripture(_lang),
                  style: GoogleFonts.inter(color: _dim, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1B2435)),
                    ),
                    child: SingleChildScrollView(
                      child: _highlightedPassage(matched),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _progressBar(matched, total),
                const SizedBox(height: 10),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: true,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.none,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 15, height: 1.4),
                    cursorColor: _accent,
                    decoration: InputDecoration(
                      hintText: PS.typePassageHere(_lang),
                      hintStyle: GoogleFonts.inter(color: _dim),
                      filled: true,
                      fillColor: const Color(0xFF070A12),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1B2435)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1B2435)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _accent),
                      ),
                    ),
                  ),
                ),
                if (widget.mode == LockMode.disable)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(
                        PS.cancel(_lang),
                        style: GoogleFonts.inter(color: _dim),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Compact chip in the header that opens the language picker, so a user who
  /// can't read/pronounce one language can copy the passage in another.
  Widget _languageButton() {
    return InkWell(
      onTap: _pickLanguage,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF1B2435)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: _dim, size: 16),
            const SizedBox(width: 6),
            Text(
              PS.langName(_lang),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _pickLanguage() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0A0E18),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(
                PS.language(_lang),
                style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 8),
              for (final l in Lang.values)
                ListTile(
                  leading: Icon(Icons.language,
                      color: l == _lang ? _accent : _dim),
                  title: Text(
                    PS.langName(l),
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  trailing: l == _lang
                      ? const Icon(Icons.check, color: _accent)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    // Persist to the shared setting; the provider watch rebuilds
                    // this screen with the passage in the new language.
                    ref.read(prayerRepositoryProvider).setLanguage(l);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  /// The challenge text with the correctly-copied prefix in green and the rest
  /// dimmed.
  Widget _highlightedPassage(int matched) {
    final challenge = _challenge;
    final style = GoogleFonts.inter(fontSize: 15, height: 1.5);
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(
            text: challenge.substring(0, matched),
            style: style.copyWith(color: _good),
          ),
          TextSpan(
            text: challenge.substring(matched),
            style: style.copyWith(color: const Color(0xFFC9D2E0)),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(int matched, int total) {
    final fraction = total == 0 ? 0.0 : matched / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
            backgroundColor: const Color(0xFF1B2435),
            valueColor: const AlwaysStoppedAnimation<Color>(_good),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          PS.charactersCount(_lang, matched, total),
          style: GoogleFonts.robotoMono(color: _dim, fontSize: 12),
        ),
      ],
    );
  }
}
