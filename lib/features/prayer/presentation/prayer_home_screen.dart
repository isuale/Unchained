import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';
import 'package:unchained/features/prayer/domain/prayer_strings.dart';
import 'package:unchained/features/prayer/domain/prayers.dart';
import 'package:unchained/features/prayer/presentation/prayer_gate_screen.dart';

/// The home of the prayer app-locker: a permanently-present act of thanks
/// ("Gracias a Dios"), the giving-thanks streak, a language switch, and entry
/// points to pray or to manage which apps are locked.
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
    final lang = ref.watch(prayerLanguageProvider).asData?.value ?? Lang.es;
    // The native watchdog's config is synced from DashboardScreen, not here —
    // this screen unmounts when the locker is switched off, which is precisely
    // when the "off" state needs to reach native.

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            // Language switch, pinned top-right.
            Align(
              alignment: Alignment.centerRight,
              child: _languageButton(context, ref, lang),
            ),
            const SizedBox(height: 6),

            // The permanent thanks — always the first thing on screen.
            Center(
              child: Column(
                children: [
                  const Icon(Icons.volunteer_activism, color: _gold, size: 44),
                  const SizedBox(height: 14),
                  Text(
                    PS.thanksTitle(lang),
                    style: GoogleFonts.dmSerifDisplay(
                        color: Colors.white, fontSize: 40),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    PS.verse(lang),
                    style: GoogleFonts.inter(
                        color: _dim, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _streakCard(lang, streak, prayers.length),
            const SizedBox(height: 16),

            _primaryButton(
              icon: Icons.self_improvement,
              label: PS.prayNow(lang),
              onTap: () => _choosePrayer(context, lang),
            ),
            const SizedBox(height: 12),

            _lockedAppsButton(context, lang, lockAll ? -1 : lockedApps.length),

            const SizedBox(height: 28),
            Center(
              child: Text(
                lockAll
                    ? PS.allBlocked(lang)
                    : lockedApps.isEmpty
                        ? PS.noAppsYet(lang)
                        : PS.someBlocked(lang, lockedApps.length),
                style: GoogleFonts.inter(color: _dim, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageButton(BuildContext context, WidgetRef ref, Lang lang) {
    return InkWell(
      onTap: () => _pickLanguage(context, ref, lang),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  void _pickLanguage(BuildContext context, WidgetRef ref, Lang current) {
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

  Widget _streakCard(Lang lang, int streak, int totalPrayers) {
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
                  PS.streak(lang, streak),
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  PS.totalPrayers(lang, totalPrayers),
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
        label: Text(label,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _lockedAppsButton(BuildContext context, Lang lang, int count) {
    final base = PS.blockedApps(lang);
    final label = count < 0
        ? '$base · ${PS.allWord(lang)}'
        : count == 0
            ? base
            : '$base · $count';
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => context.push('/apps'),
        icon: const Icon(Icons.lock_outline, size: 22),
        label: Text(label,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  /// Ask which prayer to pray, then open the gate for it.
  void _choosePrayer(BuildContext context, Lang lang) {
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
              Text(PS.whatToPray(lang),
                  style: GoogleFonts.dmSerifDisplay(
                      color: Colors.white, fontSize: 20)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.brightness_7, color: _gold),
                title: Text(PS.rosaryTitle(lang),
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(PS.rosarySub(lang),
                    style: GoogleFonts.inter(color: _dim, fontSize: 12)),
                onTap: () => start('rosary'),
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: _accent),
                title: Text(PS.thanksChoice(lang),
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(PS.thanksSub(lang),
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
