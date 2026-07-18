import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';
import 'package:unchained/features/prayer/presentation/prayer_gate_screen.dart';

/// The home of the prayer app-locker: a permanently-present act of thanks
/// ("Gracias a Dios"), the giving-thanks streak, and entry points to pray or
/// to manage which apps are locked.
///
/// This screen replaces the old content-filter dashboard as tab 1. The buttons
/// for "Rezar ahora" (the prayer gate) and "Apps bloqueadas" (the app picker)
/// are wired to their real screens in later phases; for now they announce
/// what's coming so the pivot is visible and testable end to end.
class PrayerHomeScreen extends ConsumerWidget {
  const PrayerHomeScreen({super.key});

  static const _accent = Color(0xFF1E5FFF);
  static const _gold = Color(0xFFE9B949);
  static const _card = Color(0xFF0A0E18);
  static const _border = Color(0xFF1B2435);
  static const _dim = Color(0xFF8A94A6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(prayerStreakProvider);
    final lockedApps = ref.watch(lockedAppsProvider).asData?.value ?? const [];
    final prayers = ref.watch(prayerLogProvider).asData?.value ?? const [];
    final lockAll = ref.watch(lockAllAppsProvider).asData?.value ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          children: [
            // The permanent thanks — always the first thing on screen.
            Center(
              child: Column(
                children: [
                  const Icon(Icons.volunteer_activism,
                      color: _gold, size: 44),
                  const SizedBox(height: 14),
                  Text(
                    'Gracias a Dios',
                    style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white,
                      fontSize: 40,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dad gracias en todo, porque esta es la voluntad de '
                    'Dios.\n— 1 Tesalonicenses 5:18',
                    style: GoogleFonts.inter(
                        color: _dim, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Streak — the reason "thanks to God" is motivating, not decorative.
            _streakCard(streak, prayers.length),
            const SizedBox(height: 16),

            _primaryButton(
              icon: Icons.self_improvement,
              label: 'Rezar ahora',
              onTap: () => _choosePrayer(context),
            ),
            const SizedBox(height: 12),

            _lockedAppsButton(context, lockAll ? -1 : lockedApps.length),

            const SizedBox(height: 28),
            Center(
              child: Text(
                lockAll
                    ? 'Todas las apps están bloqueadas tras la oración.'
                    : lockedApps.isEmpty
                        ? 'Aún no has bloqueado ninguna app.'
                        : '${lockedApps.length} app(s) bloqueada(s) tras la oración.',
                style: GoogleFonts.inter(color: _dim, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _streakCard(int streak, int totalPrayers) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 34)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak ${streak == 1 ? 'día' : 'días'} dando gracias',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalPrayers ${totalPrayers == 1 ? 'oración' : 'oraciones'} '
                  'en total',
                  style: GoogleFonts.inter(color: _dim, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 22),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _lockedAppsButton(BuildContext context, int count) {
    final label = count < 0
        ? 'Apps bloqueadas · Todas'
        : count == 0
            ? 'Apps bloqueadas'
            : 'Apps bloqueadas · $count';
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/apps'),
        icon: const Icon(Icons.lock_outline, size: 22),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  /// Ask which prayer to pray, then open the 20-minute gate for it.
  void _choosePrayer(BuildContext context) {
    // Capture the router up front: after the sheet closes, its own context is
    // defunct and can't be used to navigate.
    final router = GoRouter.of(context);

    void start(String prayerType) {
      Navigator.of(context).pop(); // close the sheet
      router.push('/pray', extra: PrayerGateArgs(prayerType: prayerType));
    }

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
              Text(
                '¿Qué quieres rezar?',
                style: GoogleFonts.dmSerifDisplay(
                    color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.brightness_7, color: _gold),
                title: Text('Santo Rosario',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text('Oración completa · 20 min',
                    style: GoogleFonts.inter(color: _dim, fontSize: 12)),
                onTap: () => start('rosary'),
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: _accent),
                title: Text('Acción de Gracias',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text('Salmos y gratitud · 20 min',
                    style: GoogleFonts.inter(color: _dim, fontSize: 12)),
                onTap: () => start('thanksgiving'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
