import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/features/dashboard/presentation/blocklist_screen.dart';
import 'package:unchained/features/dashboard/presentation/progress_screen.dart';
import 'package:unchained/features/dashboard/presentation/settings_screen.dart';
import 'package:unchained/features/dashboard/protection_dashboard_screen.dart';
import 'package:unchained/features/prayer/data/app_lock_service.dart';
import 'package:unchained/features/prayer/presentation/prayer_home_screen.dart';
import 'package:unchained/l10n/app_localizations.dart';

/// The tabs of the home shell, keyed by identity rather than a bare index so
/// the set can change without silently shifting which screen a nav item shows.
enum _Tab { protection, prayer, blocklist, progress, settings }

/// The app's home. Tab 0 is the control panel ("Blocking"/Protección) — the
/// default landing after payment; tab 1 is the prayer home ("Oración"); tabs
/// 2–4 are Block list, Progress (the addiction graphic) and Settings.
/// Finishing a prayer lands on tab 0.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.initialTab = 0});

  /// Which bottom-nav tab to open on. 0 = Protección (the control panel, the
  /// default), 1 = Oración (prayer home). Finishing a prayer passes 0.
  final int initialTab;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late _Tab _current = switch (widget.initialTab) {
    1 => _Tab.prayer,
    2 => _Tab.blocklist,
    3 => _Tab.progress,
    4 => _Tab.settings,
    _ => _Tab.protection,
  };

  static const _bg = Color(0xFF0A0E18);
  static const _active = Color(0xFF1E5FFF);
  static const _inactive = Color(0xFF666666);

  Widget _screenFor(_Tab tab) => switch (tab) {
        _Tab.protection => const ProtectionDashboardScreen(),
        _Tab.prayer => const PrayerHomeScreen(),
        _Tab.blocklist => const BlocklistScreen(),
        _Tab.progress => const ProgressScreen(),
        _Tab.settings => const SettingsScreen(),
      };

  BottomNavigationBarItem _itemFor(_Tab tab, AppLocalizations l) =>
      switch (tab) {
        _Tab.protection => BottomNavigationBarItem(
            icon: const Icon(Icons.shield_outlined),
            activeIcon: const Icon(Icons.shield),
            label: l.nav_blocking,
          ),
        _Tab.prayer => BottomNavigationBarItem(
            icon: const Icon(Icons.volunteer_activism_outlined),
            activeIcon: const Icon(Icons.volunteer_activism),
            label: l.nav_prayer,
          ),
        _Tab.blocklist => BottomNavigationBarItem(
            icon: const Icon(Icons.block_flipped),
            label: l.nav_blocklist,
          ),
        _Tab.progress => BottomNavigationBarItem(
            icon: const Icon(Icons.timeline),
            label: l.nav_progress,
          ),
        _Tab.settings => BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l.nav_settings,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // Keep the native watchdog's app-lock config in sync with the DB. This
    // lives here, not on the prayer tab, so a change still reaches native
    // whichever tab happens to be on screen.
    ref.watch(appLockSyncProvider);

    // Every tab is always present. The prayer tab stays even when the locker is
    // switched off — it holds the only switch to turn it back on — but the
    // screen itself then renders a neutral "off" state with no religious
    // content. See PrayerHomeScreen.
    const tabs = _Tab.values;
    final selected = _current;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      body: IndexedStack(
        index: tabs.indexOf(selected),
        children: [for (final t in tabs) _screenFor(t)],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: tabs.indexOf(selected),
          onTap: (i) => setState(() => _current = tabs[i]),
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
          items: [for (final t in tabs) _itemFor(t, l)],
        ),
      ),
    );
  }
}
