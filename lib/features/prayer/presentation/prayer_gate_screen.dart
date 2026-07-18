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
    this.prayerType = 'rosary',
    this.triggerPackage,
  });

  final PrayerGateMode mode;
  final String prayerType;
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

  late final String _type;
  late final Duration _duration;
  late final int _minSeconds;
  // The Rosary's mysteries, defaulted to today's set; null for thanksgiving.
  MysterySet? _set;

  Timer? _timer;
  late int _secondsLeft;
  bool _completed = false;

  bool get _done => _secondsLeft <= 0;
  int get _elapsed => _duration.inSeconds - _secondsLeft;
  bool get _canFinish => _done || _elapsed >= _minSeconds;

  @override
  void initState() {
    super.initState();
    _type = widget.args.prayerType;
    _duration = Duration(minutes: fullMinutesFor(_type));
    _minSeconds = minMinutesFor(_type) * 60;
    _secondsLeft = _duration.inSeconds;
    _set = _type == 'rosary'
        ? mysterySetForWeekday(DateTime.now().weekday)
        : null;

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scriptureLockActive.value = true;
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
      if (!_done && !_completed) _startTimer();
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

    // Reset the in-app stack to the control panel (dashboard's Protección tab).
    router.go('/dashboard', extra: 1);

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
    final lang = ref.watch(prayerLanguageProvider).asData?.value ?? Lang.es;
    final guide = buildGuide(_type, lang, set: _set);
    final fraction = 1 - (_secondsLeft / _duration.inSeconds);

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
                _header(guide.title),
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
      ),
    );
  }

  Widget _header(String title) {
    return Row(
      children: [
        const Icon(Icons.volunteer_activism, color: _gold, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gracias a Dios',
                  style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white, fontSize: 24)),
              Text(title, style: GoogleFonts.inter(color: _dim, fontSize: 13)),
            ],
          ),
        ),
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
