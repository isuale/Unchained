import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/features/guard/domain/bible_passages.dart';
import 'package:unchained/features/guard/uninstall_guard_service.dart';

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
class ScriptureLockScreen extends StatefulWidget {
  const ScriptureLockScreen({super.key, this.mode = LockMode.block});

  final LockMode mode;

  @override
  State<ScriptureLockScreen> createState() => _ScriptureLockScreenState();
}

class _ScriptureLockScreenState extends State<ScriptureLockScreen> {
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

  late String _passage;
  Timer? _timer;
  int _secondsLeft = _limit.inSeconds;
  bool _passed = false;

  @override
  void initState() {
    super.initState();
    _passage = BiblePassages.random();
    _controller.addListener(_onChanged);
    _startTimer();
  }

  @override
  void dispose() {
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
    setState(() => _passage = BiblePassages.random(previous: _passage));
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
                            ? 'Turn off protection'
                            : 'Stay unchained',
                        style: GoogleFonts.dmSerifDisplay(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                    ),
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
                  'Copy these 800 letters of Scripture exactly to continue. If the '
                  'timer runs out, it clears and you start over.',
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
                      hintText: 'Type the passage here…',
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
                        'Cancel',
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
          '$matched / $total characters',
          style: GoogleFonts.robotoMono(color: _dim, fontSize: 12),
        ),
      ],
    );
  }
}
