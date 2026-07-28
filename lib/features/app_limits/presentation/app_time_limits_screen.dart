import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/core/dev_flags.dart';
import 'package:unchained/features/app_limits/application/app_limits_provider.dart';
import 'package:unchained/features/app_limits/data/app_limits_bridge.dart';
import 'package:unchained/features/prayer/data/installed_apps_service.dart';
import 'package:unchained/l10n/app_localizations.dart';

/// Lets the user pick ANY app on the phone and give it its own daily minute
/// budget — the generalized counterpart to the Social section's fixed
/// Reels/Shorts/TikTok/Snapchat timers. Enforcement is the exact same native
/// watchdog (FeedGuardService), just keyed by package name instead of a fixed
/// target key — see AppLimitsBridge / FeedGuardState's class doc.
class AppTimeLimitsScreen extends ConsumerStatefulWidget {
  const AppTimeLimitsScreen({super.key});

  @override
  ConsumerState<AppTimeLimitsScreen> createState() =>
      _AppTimeLimitsScreenState();
}

class _AppTimeLimitsScreenState extends ConsumerState<AppTimeLimitsScreen> {
  static const _accent = Color(0xFF1E5FFF);
  static const _card = Color(0xFF0A0E18);
  static const _border = Color(0xFF1B2435);
  static const _dim = Color(0xFF8A94A6);
  static const _gold = Color(0xFFFFB800);

  String _query = '';

  AppLocalizations get l => AppLocalizations.of(context)!;

  @override
  Widget build(BuildContext context) {
    // Keeps native in sync with any edit made on this screen.
    ref.watch(appLimitsSyncProvider);

    final configured = ref.watch(appLimitsProvider).asData?.value ?? const [];
    final byPackage = {for (final a in configured) a.packageName: a};
    final statuses =
        ref.watch(appLimitStatusesProvider).asData?.value ?? const {};

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          l.app_limits_screen_title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _PermissionBanner(),
          ),
          _searchField(),
          Expanded(child: _appList(byPackage, statuses)),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        style: const TextStyle(color: Colors.white),
        cursorColor: _accent,
        decoration: InputDecoration(
          hintText: l.app_limits_search_hint,
          hintStyle: const TextStyle(color: _dim),
          prefixIcon: const Icon(Icons.search, color: _dim),
          filled: true,
          fillColor: _card,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent),
          ),
        ),
      ),
    );
  }

  Widget _appList(
    Map<String, AppTimeLimit> byPackage,
    Map<String, AppLimitStatus> statuses,
  ) {
    final asyncApps = ref.watch(installedAppsProvider);
    return asyncApps.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _accent)),
      error: (e, _) => Center(
        child: Text(
          l.app_limits_empty_search,
          style: const TextStyle(color: _dim),
        ),
      ),
      data: (apps) {
        final filtered = _query.isEmpty
            ? apps
            : apps
                .where((a) => a.label.toLowerCase().contains(_query))
                .toList();
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              l.app_limits_empty_search,
              style: const TextStyle(color: _dim),
            ),
          );
        }
        final limited = filtered
            .where((a) => byPackage.containsKey(a.packageName))
            .toList();
        final rest = filtered
            .where((a) => !byPackage.containsKey(a.packageName))
            .toList();

        return ListView(
          children: [
            if (limited.isNotEmpty) ...[
              _sectionHeader(l.app_limits_section_limited),
              for (final app in limited)
                _limitedRow(app, byPackage[app.packageName]!,
                    statuses[app.packageName]),
            ],
            if (rest.isNotEmpty) ...[
              _sectionHeader(l.app_limits_section_all),
              for (final app in rest) _addableRow(app),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _dim,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _limitedRow(
    InstalledApp app,
    AppTimeLimit limit,
    AppLimitStatus? status,
  ) {
    final lockedUntil = status?.lockedUntil;
    final sublabel = lockedUntil != null
        ? l.feed_guard_locked_sublabel(_formatLockCountdown(lockedUntil))
        : '${limit.dailyLimitMinutes} min/day';

    return ListTile(
      leading: _appIcon(app),
      title: Text(
        app.label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(sublabel, style: const TextStyle(color: _dim)),
      onTap: () => _editLimit(app, limit, lockedUntil),
      onLongPress: kDevTools ? () => _confirmReset(app) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lockedUntil != null)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.lock_clock, color: _gold, size: 20),
            )
          else
            Switch(
              value: limit.enabled,
              onChanged: (v) => ref
                  .read(appLimitsActionsProvider.notifier)
                  .setEnabled(app.packageName, app.label,
                      limit.dailyLimitMinutes, v),
              activeThumbColor: Colors.white,
              activeTrackColor: _accent,
              inactiveTrackColor: const Color(0xFF1A2238),
              inactiveThumbColor: const Color(0xFF666666),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: _dim, size: 20),
            onPressed: lockedUntil != null ? null : () => _confirmRemove(app),
          ),
        ],
      ),
    );
  }

  Widget _addableRow(InstalledApp app) {
    return ListTile(
      leading: _appIcon(app),
      title: Text(
        app.label,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _addApp(app),
      trailing: OutlinedButton(
        onPressed: () => _addApp(app),
        style: OutlinedButton.styleFrom(
          foregroundColor: _accent,
          side: const BorderSide(color: _accent),
        ),
        child: Text(l.app_limits_add),
      ),
    );
  }

  Widget _appIcon(InstalledApp app) {
    if (app.icon == null) {
      return const CircleAvatar(
        backgroundColor: _card,
        child: Icon(Icons.android, color: _dim),
      );
    }
    return SizedBox(
      width: 40,
      height: 40,
      child: Image.memory(app.icon!, gaplessPlayback: true),
    );
  }

  Future<void> _addApp(InstalledApp app) async {
    final minutes = await _askDailyLimitMinutes(context, 30);
    if (minutes == null) return;
    await ref.read(appLimitsActionsProvider.notifier).setAppLimit(
          packageName: app.packageName,
          appLabel: app.label,
          enabled: true,
          dailyLimitMinutes: minutes,
        );
  }

  Future<void> _editLimit(
    InstalledApp app,
    AppTimeLimit limit,
    DateTime? lockedUntil,
  ) async {
    if (lockedUntil != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(l.feed_guard_locked_message(_formatLockCountdown(lockedUntil))),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0A0F1C),
        ),
      );
      return;
    }
    final minutes =
        await _askDailyLimitMinutes(context, limit.dailyLimitMinutes);
    if (minutes == null) return;
    final applied = await ref.read(appLimitsActionsProvider.notifier).setAppLimit(
          packageName: app.packageName,
          appLabel: app.label,
          enabled: limit.enabled,
          dailyLimitMinutes: minutes,
        );
    if (!applied && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.feed_guard_locked_refused),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0A0F1C),
        ),
      );
    }
  }

  Future<void> _confirmRemove(InstalledApp app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: Text(
          l.app_limits_remove_title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l.app_limits_remove_body(app.label),
          style: const TextStyle(color: Color(0xFFB8C0D0), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.common_cancel,
                style: const TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.app_limits_remove_confirm,
                style:
                    const TextStyle(color: _accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(appLimitsActionsProvider.notifier)
          .removeAppLimit(app.packageName);
    }
  }

  /// Dev-only (DEV_TOOLS) hard reset of one app's daily budget: clears usage
  /// and drops the 24h exhaustion lock, bypassing the anti-circumvention
  /// cooldown for testing. Mirrors the Social section's long-press reset.
  Future<void> _confirmReset(InstalledApp app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: Text(l.dev_reset_budget_title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          l.dev_reset_budget_body(app.label),
          style: const TextStyle(color: Color(0xFFB8C0D0), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.common_cancel,
                style: const TextStyle(color: Color(0xFF888888))),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.dev_reset_confirm, style: const TextStyle(color: _accent)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AppLimitsBridge.resetAppLimit(app.packageName);
    ref.invalidate(appLimitStatusesProvider);
  }

  String _formatLockCountdown(DateTime lockedUntil) {
    final remaining = lockedUntil.difference(DateTime.now());
    if (remaining.isNegative) return '0m';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  /// Simple stepper dialog for "how many minutes per day?" (1-180, steps of 5
  /// except down to the 1-minute floor). Mirrors the Social section's dialog.
  Future<int?> _askDailyLimitMinutes(BuildContext context, int initial) {
    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        var minutes = initial.clamp(1, 180);
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: _card,
            title: Text(
              l.app_limits_minutes_title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.app_limits_minutes_body,
                  style: const TextStyle(color: Color(0xFFB8C0D0), height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: minutes > 1
                          ? () => setState(
                              () => minutes = (minutes - 5).clamp(1, 180))
                          : null,
                      icon: const Icon(Icons.remove_circle_outline,
                          color: _accent),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        '$minutes',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: minutes < 180
                          ? () => setState(() => minutes += 5)
                          : null,
                      icon: const Icon(Icons.add_circle_outline,
                          color: _accent),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l.common_cancel,
                    style: const TextStyle(color: Color(0xFF888888))),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(minutes),
                child: Text(
                  l.common_confirm,
                  style: const TextStyle(color: _accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Enforcing a per-app daily limit requires the same dedicated accessibility
/// service the Social feed limits use. Adding an app above silently does
/// nothing until this is granted, so surface it inline.
class _PermissionBanner extends StatefulWidget {
  const _PermissionBanner();

  @override
  State<_PermissionBanner> createState() => _PermissionBannerState();
}

class _PermissionBannerState extends State<_PermissionBanner>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final enabled = await AppLimitsBridge.isAccessibilityEnabled();
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _enabled) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB800).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFFFFB800).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFFB800), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.app_limits_permission_banner,
              style: const TextStyle(color: Color(0xFFB8C0D0), fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () async {
              await AppLimitsBridge.openAccessibilitySettings();
            },
            child: Text(l.app_limits_permission_enable,
                style: const TextStyle(color: Color(0xFF1E5FFF))),
          ),
        ],
      ),
    );
  }
}
