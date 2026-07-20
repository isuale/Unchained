import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/core/database/user_assessment_repository.dart';
import 'package:unchained/features/app_limits/data/app_limits_bridge.dart';
import 'package:unchained/features/app_limits/data/app_limits_repository.dart';

final appLimitsRepositoryProvider = Provider<AppLimitsRepository>((ref) {
  return AppLimitsRepository(ref.watch(appDatabaseProvider));
});

/// Live list of apps the user has picked, alphabetically.
final appLimitsProvider = StreamProvider<List<AppTimeLimit>>((ref) {
  return ref.watch(appLimitsRepositoryProvider).watchAppLimits();
});

/// Ticks once per second so the lock countdown refreshes even when nothing in
/// the database changes.
final _secondTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

/// Live native status (usage + 24h exhaustion-lock deadline) for every
/// configured app, re-fetched every second so the countdown and re-enabled
/// controls track native truth without needing a manual refresh.
final appLimitStatusesProvider =
    FutureProvider<Map<String, AppLimitStatus>>((ref) async {
  ref.watch(_secondTickerProvider);
  return AppLimitsBridge.getStatuses();
});

/// Keeps native in sync with the configured apps: pushes every app's
/// enabled/limit config on every change. Watch this from a long-lived widget
/// (the dashboard) so edits made in the picker take effect immediately.
final appLimitsSyncProvider = Provider<void>((ref) {
  final apps = ref.watch(appLimitsProvider).asData?.value ?? const [];
  for (final app in apps) {
    AppLimitsBridge.setAppLimitConfig(
      packageName: app.packageName,
      label: app.appLabel,
      enabled: app.enabled,
      limitMinutes: app.dailyLimitMinutes,
    );
  }
});

class AppLimitsActions extends Notifier<void> {
  @override
  void build() {}

  /// Adds a new app or updates an existing one's daily limit, then pushes the
  /// change to native immediately. Refused (returns false, no write at all)
  /// while the app is in its 24h exhaustion lock — otherwise a user could
  /// dodge the cooldown by just raising the limit the moment it runs out.
  Future<bool> setAppLimit({
    required String packageName,
    required String appLabel,
    required bool enabled,
    required int dailyLimitMinutes,
  }) async {
    final statuses = await AppLimitsBridge.getStatuses();
    if (statuses[packageName]?.isLocked == true) return false;

    await ref.read(appLimitsRepositoryProvider).setAppLimit(
          packageName: packageName,
          appLabel: appLabel,
          enabled: enabled,
          dailyLimitMinutes: dailyLimitMinutes,
        );
    await AppLimitsBridge.setAppLimitConfig(
      packageName: packageName,
      label: appLabel,
      enabled: enabled,
      limitMinutes: dailyLimitMinutes,
    );
    return true;
  }

  /// Turns an already-configured app's limit on/off without changing its
  /// minute budget. Same 24h-lock refusal as [setAppLimit].
  Future<bool> setEnabled(
    String packageName,
    String appLabel,
    int dailyLimitMinutes,
    bool enabled,
  ) {
    return setAppLimit(
      packageName: packageName,
      appLabel: appLabel,
      enabled: enabled,
      dailyLimitMinutes: dailyLimitMinutes,
    );
  }

  Future<void> removeAppLimit(String packageName) async {
    await ref.read(appLimitsRepositoryProvider).removeAppLimit(packageName);
    await AppLimitsBridge.removeAppLimit(packageName);
  }
}

final appLimitsActionsProvider =
    NotifierProvider<AppLimitsActions, void>(AppLimitsActions.new);
