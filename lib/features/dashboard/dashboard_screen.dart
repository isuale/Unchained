import 'package:flutter/material.dart';
import 'package:unchained/features/dashboard/presentation/blocklist_screen.dart';
import 'package:unchained/features/dashboard/presentation/progress_screen.dart';
import 'package:unchained/features/dashboard/presentation/settings_screen.dart';
import 'package:unchained/features/dashboard/protection_dashboard_screen.dart';
import 'package:unchained/features/prayer/presentation/prayer_home_screen.dart';
import 'package:unchained/l10n/app_localizations.dart';

/// The app's home. Tab 0 is the control panel ("Blocking"/Protección) — the
/// default landing after payment; tab 1 is the prayer home ("Oración"); tabs
/// 2–4 are Block list, Progress (the addiction graphic) and Settings. Finishing
/// a prayer lands on the control panel (tab 0).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.initialTab = 0});

  /// Which bottom-nav tab to open on. 0 = Protección (the control panel, the
  /// default), 1 = Oración (prayer home). Finishing a prayer passes 0.
  final int initialTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _index = widget.initialTab;

  static const _bg = Color(0xFF0A0E18);
  static const _active = Color(0xFF1E5FFF);
  static const _inactive = Color(0xFF666666);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          ProtectionDashboardScreen(),
          PrayerHomeScreen(),
          BlocklistScreen(),
          ProgressScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: _bg,
          selectedItemColor: _active,
          unselectedItemColor: _inactive,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.shield_outlined),
              activeIcon: const Icon(Icons.shield),
              label: l.nav_blocking,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism_outlined),
              activeIcon: Icon(Icons.volunteer_activism),
              label: 'Oración',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.block_flipped),
              label: l.nav_blocklist,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.timeline),
              label: l.nav_progress,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: l.nav_settings,
            ),
          ],
        ),
      ),
    );
  }
}
