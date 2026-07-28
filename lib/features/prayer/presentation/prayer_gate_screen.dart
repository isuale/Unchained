import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/features/guard/lock_visibility.dart';
import 'package:unchained/features/prayer/data/app_lock_service.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';
import 'package:unchained/features/prayer/domain/prayer_strings.dart';
import 'package:unchained/features/prayer/domain/prayers.dart';

/// Why the gate is up.
enum PrayerGateMode {
  /// Opened voluntarily from "Rezar ahora". Only a finished prayer counts.
  voluntary,

  /// Raised by opening a locked app (native, wired in a later phase). No way
  /// off until the prayer is finished; finishing opens the 24h window.
  enforced,
}

/// Arguments passed to the gate via the router's `extra`.
class PrayerGateArgs {
  const PrayerGateArgs({
    this.mode = PrayerGateMode.voluntary,
    this.prayerType,
    this.triggerPackage,
  });

  final PrayerGateMode mode;

  /// 'rosary' | 'thanksgiving', or null to let the user choose on the gate
  /// itself (used when a locked app raises the gate with no prior choice).
  final String? prayerType;
  final String? triggerPackage;
}

/// Full-screen, back-proof prayer session. A countdown runs while the screen is
/// foreground (it pauses if the app is backgrounded, so leaving freezes
/// progress). The Rosary must be prayed in full; thanksgiving unlocks its
/// finish button after a 2-minute minimum for those who pray faster.
class PrayerGateScreen extends ConsumerStatefulWidget {
  const PrayerGateScreen({super.key, required this.args});

  final PrayerGateArgs args;

  @override
  ConsumerState<PrayerGateScreen> createState() => _PrayerGateScreenState();
}

class _PrayerGateScreenState extends ConsumerState<PrayerGateScreen>
    with WidgetsBindingObserver {
  static const _accent = Color(0xFF1E5FFF);
  static const _gold = Color(0xFFE9B949);
  static const _good = Color(0xFF34C759);
  static const _card = Color(0xFF0A0E18);
  static const _border = Color(0xFF1B2435);
  static const _dim = Color(0xFF8A94A6);

  late String _type;
  late Duration _duration;
  late int _minSeconds;
  // The Rosary's mysteries, defaulted to today's set; null for thanksgiving.
  MysterySet? _set;

  // True until the user picks which prayer to pray. Only happens when a
  // locked app raised the gate without a prior choice (args.prayerType is
  // null); the voluntary "Rezar ahora" flow already asks before pushing here.
  late bool _needsChoice;

  Timer? _timer;
  late int _secondsLeft;
  bool _completed = false;

  bool get _done => _secondsLeft <= 0;
  int get _elapsed => _duration.inSeconds - _secondsLeft;
  bool get _canFinish => _done || _elapsed >= _minSeconds;

  @override
  void initState() {
    super.initState();
    _needsChoice = widget.args.prayerType == null;
    _setType(widget.args.prayerType ?? 'rosary');

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scriptureLockActive.value = true;
    });
    if (!_needsChoice) _startTimer();
  }

  void _setType(String type) {
    _type = type;
    _duration = Duration(minutes: fullMinutesFor(type));
    _minSeconds = minMinutesFor(type) * 60;
    _secondsLeft = _duration.inSeconds;
    _set = type == 'rosary'
        ? mysterySetForWeekday(DateTime.now().weekday)
        : null;
  }

  void _choosePrayerType(String type) {
    setState(() {
      _setType(type);
      _needsChoice = false;
    });
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scriptureLockActive.value = false;
    });
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_needsChoice && !_done && !_completed) _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  Future<void> _complete() async {
    if (_completed || !_canFinish) return;
    // Capture the router BEFORE the async gap so navigation can't be lost if
    // the element is torn down while logging.
    final router = GoRouter.of(context);

    setState(() => _completed = true);
    _timer?.cancel();
    scriptureLockActive.value = false; // restore the footer/chrome on the way out

    try {
      await ref.read(prayerRepositoryProvider).logPrayer(
            triggerPackage: widget.args.triggerPackage,
            prayerType: _type,
            durationSeconds: _elapsed,
            completedAt: DateTime.now(),
          );
    } catch (e, st) {
      // Never let a logging failure trap the user on the prayer screen.
      debugPrint('logPrayer failed: $e\n$st');
    }

    // Praying opens the 24-hour window: all locked apps become usable until it
    // elapses. Always do this, however the gate was raised.
    await AppLockService.openUnlockWindow(24);

    // Reset the in-app stack to the control panel (dashboard's Protección tab,
    // now tab 0).
    router.go('/dashboard', extra: 0);

    // If a locked app raised this gate, drop back to the phone so the user
    // lands on the app they were opening — now unlocked for 24h.
    if (widget.args.mode == PrayerGateMode.enforced) {
      await SystemNavigator.pop();
    }
  }

  String get _clock {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider).asData?.value ?? Lang.es;

    return PopScope(
      canPop: false,
      child: _needsChoice ? _chooserScaffold(lang) : _prayerScaffold(lang),
    );
  }

  /// Shown when a locked app raised the gate with no prayer chosen yet: the
  /// same two options offered by "Rezar ahora", but undismissable — the timer
  /// hasn't started, so choosing costs no time.
  Widget _chooserScaffold(Lang lang) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.volunteer_activism, color: _gold, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(PS.whatToPray(lang),
                        style: GoogleFonts.dmSerifDisplay(
                            color: Colors.white, fontSize: 22)),
                  ),
                  _languageButton(lang),
                ],
              ),
              const SizedBox(height: 28),
              _chooserCard(
                icon: Icons.brightness_7,
                iconColor: _gold,
                title: PS.rosaryTitle(lang),
                subtitle: PS.rosarySub(lang),
                onTap: () => _choosePrayerType('rosary'),
              ),
              const SizedBox(height: 14),
              _chooserCard(
                icon: Icons.favorite,
                iconColor: _accent,
                title: PS.thanksChoice(lang),
                subtitle: PS.thanksSub(lang),
                onTap: () => _choosePrayerType('thanksgiving'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chooserCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.inter(color: _dim, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: _dim),
          ],
        ),
      ),
    );
  }

  Widget _prayerScaffold(Lang lang) {
    final guide = buildGuide(_type, lang, set: _set);
    final fraction = 1 - (_secondsLeft / _duration.inSeconds);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(guide.title, lang),
              if (_set != null) ...[
                const SizedBox(height: 10),
                _mysteryBar(lang),
              ],
              const SizedBox(height: 14),
              Expanded(child: _prayerBody(guide)),
              const SizedBox(height: 12),
              _progress(lang, fraction),
              const SizedBox(height: 12),
              _amenButton(lang),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String title, Lang lang) {
    return Row(
      children: [
        const Icon(Icons.volunteer_activism, color: _gold, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(PS.thanksTitle(lang),
                  style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white, fontSize: 24)),
              Text(title, style: GoogleFonts.inter(color: _dim, fontSize: 13)),
            ],
          ),
        ),
        _languageButton(lang),
        const SizedBox(width: 8),
        Text(
          _clock,
          style: GoogleFonts.robotoMono(
            color: _done ? _good : Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  /// Compact chip that opens the language picker, so a user who can't read or
  /// pronounce one language can pray this locked screen in another — without
  /// having to leave the gate (which they can't, when an app raised it).
  Widget _languageButton(Lang lang) {
    return InkWell(
      onTap: () => _pickLanguage(lang),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: _dim, size: 16),
            const SizedBox(width: 6),
            Text(PS.langName(lang),
                style: GoogleFonts.inter(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _pickLanguage(Lang current) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(PS.language(current),
                  style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white, fontSize: 20)),
              const SizedBox(height: 8),
              for (final l in Lang.values)
                ListTile(
                  leading: Icon(Icons.language,
                      color: l == current ? _accent : _dim),
                  title: Text(PS.langName(l),
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  trailing: l == current
                      ? const Icon(Icons.check, color: _accent)
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    // Persist to the shared setting; the provider watch rebuilds
                    // the gate with the prayer text in the new language.
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

  /// The two "top features" for the Rosary: which mysteries (tap to change) and
  /// a "today" marker when the set matches the weekday's traditional mysteries.
  Widget _mysteryBar(Lang lang) {
    final set = _set!;
    final isToday = mysterySetForWeekday(DateTime.now().weekday).type == set.type;
    return InkWell(
      onTap: () => _pickMysteries(lang),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: _gold, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(set.name, lang),
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
            ),
            if (isToday)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(PS.today(lang),
                    style: GoogleFonts.inter(color: _accent, fontSize: 11)),
              ),
            const Icon(Icons.expand_more, color: _dim, size: 20),
          ],
        ),
      ),
    );
  }

  void _pickMysteries(Lang lang) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final todayType =
            mysterySetForWeekday(DateTime.now().weekday).type;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Text(PS.changeMysteries(lang),
                  style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white, fontSize: 20)),
              const SizedBox(height: 8),
              for (final s in allMysterySets)
                ListTile(
                  leading: Icon(Icons.auto_awesome,
                      color: s.type == _set?.type ? _gold : _dim),
                  title: Text(tr(s.name, lang),
                      style: GoogleFonts.inter(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  trailing: s.type == todayType
                      ? Text(PS.today(lang),
                          style:
                              GoogleFonts.inter(color: _accent, fontSize: 12))
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    setState(() => _set = s);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _prayerBody(PrayerGuide guide) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: ListView.separated(
        itemCount: guide.steps.length,
        separatorBuilder: (_, _) => const Divider(color: _border, height: 28),
        itemBuilder: (context, i) {
          final step = guide.steps[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.heading,
                  style: GoogleFonts.inter(
                      color: _gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(step.body,
                  style: GoogleFonts.inter(
                      color: const Color(0xFFC9D2E0),
                      fontSize: 15,
                      height: 1.5)),
            ],
          );
        },
      ),
    );
  }

  Widget _progress(Lang lang, double fraction) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: _border,
            valueColor: AlwaysStoppedAnimation<Color>(_done ? _good : _accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _done
              ? PS.completedHint(lang)
              : _canFinish
                  ? PS.canFinishNow(lang)
                  : PS.prayAtLeast(lang, _minSeconds ~/ 60),
          style: GoogleFonts.inter(color: _dim, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _amenButton(Lang lang) {
    final label = _done
        ? PS.amen(lang)
        : _canFinish
            ? PS.finishedAmen(lang)
            : PS.prayToContinue(lang, _minSeconds - _elapsed);
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _canFinish ? _complete : null,
        icon:
            Icon(_canFinish ? Icons.check_circle : Icons.lock_clock, size: 22),
        label: Text(label,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _canFinish ? _good : _card,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _card,
          disabledForegroundColor: _dim,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
