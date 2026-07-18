import 'package:flutter/material.dart';
import 'package:unchained/features/dashboard/presentation/settings_screen.dart';
import 'package:unchained/features/prayer/presentation/prayer_home_screen.dart';

// NOTE: the old content-filter tabs (ProtectionDashboardScreen, BlocklistScreen,
// ProgressScreen) are retired from the nav for the prayer app-locker pivot. Their
// files are kept in-tree for one release rather than deleted, so nothing is lost
// if we need to reference them; they are simply no longer routed here.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.initialTab = 0});

  /// Which bottom-nav tab to open on: 0 = Oración, 1 = Ajustes. Finishing a
  /// prayer lands on 1 (the control/settings side of the panel).
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
    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: const [
          PrayerHomeScreen(),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism_outlined),
              activeIcon: Icon(Icons.volunteer_activism),
              label: 'Oración',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
