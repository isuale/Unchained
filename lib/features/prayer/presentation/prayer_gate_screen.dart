import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/features/guard/lock_visibility.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';
import 'package:unchained/features/prayer/domain/prayers.dart';

/// Why the gate is up.
enum PrayerGateMode {
  /// Opened voluntarily from "Rezar ahora". The user may leave any time; only a
  /// finished 20-minute prayer counts toward the streak.
  voluntary,

  /// Raised by opening a locked app (native, wired in a later phase). There is
  /// no way off until the prayer is finished; finishing opens the 24h window.
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

/// Full-screen, back-proof prayer session. A 20-minute countdown runs while the
/// screen is in the foreground (it pauses if the app is backgrounded, so
/// leaving freezes progress rather than earning the apps). "Amén" only becomes
/// tappable at 0:00; tapping it logs the prayer and lifts the gate.
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

  late final PrayerGuide _guide;
  // Session length comes from the chosen prayer: the Rosary is a full 20-minute
  // session, thanksgiving is a short 5. Set once from the guide in initState.
  late final Duration _duration;
  Timer? _timer;
  late int _secondsLeft;
  bool _completed = false;

  bool get _done => _secondsLeft <= 0;

  @override
  void initState() {
    super.initState();
    _guide = guideFor(widget.args.prayerType);
    _duration = Duration(minutes: _guide.minutes);
    _secondsLeft = _duration.inSeconds;
    WidgetsBinding.instance.addObserver(this);
    // Hide the app's owner-credit footer for the whole session so the user sees
    // only the prayer. Deferred so toggling the ancestor listener never fires
    // during build. Reuses the same notifier the Scripture lock uses.
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
    // Pause the countdown when the app leaves the foreground and resume it on
    // return — so backgrounding the app can't run the clock down for free, but
    // an interruption doesn't wipe a nearly-finished prayer either.
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
    if (_completed || !_done) return;
    setState(() => _completed = true);
    _timer?.cancel();

    await ref.read(prayerRepositoryProvider).logPrayer(
          triggerPackage: widget.args.triggerPackage,
          prayerType: _guide.type,
          durationSeconds: _duration.inSeconds,
          completedAt: DateTime.now(),
        );
    // Phase 5 (native enforcement) opens the 24-hour unlock window here.

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gracias a Dios · Oración completada'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _card,
      ),
    );
    if (context.canPop()) context.pop();
  }

  String get _clock {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final voluntary = widget.args.mode == PrayerGateMode.voluntary;
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
                _header(voluntary),
                const SizedBox(height: 14),
                Expanded(child: _prayerBody()),
                const SizedBox(height: 12),
                _progress(fraction),
                const SizedBox(height: 12),
                _amenButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool voluntary) {
    return Row(
      children: [
        const Icon(Icons.volunteer_activism, color: _gold, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gracias a Dios',
                style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white, fontSize: 24),
              ),
              Text(
                _guide.title,
                style: GoogleFonts.inter(color: _dim, fontSize: 13),
              ),
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
        if (voluntary && !_done)
          TextButton(
            onPressed: () {
              if (context.canPop()) context.pop();
            },
            child: Text('Salir', style: GoogleFonts.inter(color: _dim)),
          ),
      ],
    );
  }

  Widget _prayerBody() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: ListView.separated(
        itemCount: _guide.steps.length,
        separatorBuilder: (_, _) => const Divider(
          color: _border,
          height: 28,
        ),
        itemBuilder: (context, i) {
          final step = _guide.steps[i];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.heading,
                style: GoogleFonts.inter(
                  color: _gold,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                step.body,
                style: GoogleFonts.inter(
                  color: const Color(0xFFC9D2E0),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _progress(double fraction) {
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
              ? 'Oración completada. Pulsa Amén para continuar.'
              : 'Ora durante ${_duration.inMinutes} minutos. El tiempo se pausa '
                  'si sales de la app.',
          style: GoogleFonts.inter(color: _dim, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _amenButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _done ? _complete : null,
        icon: Icon(_done ? Icons.check_circle : Icons.lock_clock, size: 22),
        label: Text(
          _done ? 'Amén' : 'Ora para continuar…',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _done ? _good : _card,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _card,
          disabledForegroundColor: _dim,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
