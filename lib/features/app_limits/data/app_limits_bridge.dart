import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart side of the "App Time Limits" feature: a daily minute budget for any
/// app the user picks (not just the four built-in social feeds).
///
/// Enforcement reuses the same native watchdog as the Social feed limits
/// (`FeedGuardService.kt`/`FeedGuardState.kt`), keyed by package name instead
/// of a fixed target key — see that class's doc comment. This class just
/// pushes config to native and reads back live usage; it does no enforcement
/// itself, so it keeps working even if the app is backgrounded.
///
/// Mirrors [FeedGuardBridge]'s shape: every call is wrapped so a channel
/// failure returns a safe default instead of throwing.
class AppLimitsBridge {
  AppLimitsBridge._();

  static const _channel = MethodChannel('unchained/app_limits');

  /// Whether the shared feed-guard accessibility service is switched on.
  static Future<bool> isAccessibilityEnabled() =>
      _invokeBool('isAccessibilityEnabled');

  static Future<bool> openAccessibilitySettings() =>
      _invokeBool('openAccessibilitySettings');

  /// Pushes one app's enabled/limit config to native. Call for every
  /// configured app on startup, and again whenever one changes.
  static Future<bool> setAppLimitConfig({
    required String packageName,
    required String label,
    required bool enabled,
    required int limitMinutes,
  }) async {
    try {
      final r = await _channel.invokeMethod<bool>('setAppLimitConfig', {
        'package': packageName,
        'label': label,
        'enabled': enabled,
        'limitMinutes': limitMinutes,
      });
      return r ?? false;
    } catch (e, st) {
      debugPrint('AppLimitsBridge.setAppLimitConfig failed: $e\n$st');
      return false;
    }
  }

  /// Removes an app from native entirely (usage/history/lock all cleared).
  static Future<bool> removeAppLimit(String packageName) async {
    try {
      final r = await _channel.invokeMethod<bool>('removeAppLimit', {
        'package': packageName,
      });
      return r ?? false;
    } catch (e, st) {
      debugPrint('AppLimitsBridge.removeAppLimit failed: $e\n$st');
      return false;
    }
  }

  /// Dev-only: clears one app's daily usage and drops its 24h exhaustion lock
  /// so the budget is fresh again immediately. Bypasses the anti-circumvention
  /// cooldown on purpose — only ever call from a kDevTools-gated path.
  static Future<bool> resetAppLimit(String packageName) async {
    try {
      final r = await _channel.invokeMethod<bool>('resetAppLimit', {
        'package': packageName,
      });
      return r ?? false;
    } catch (e, st) {
      debugPrint('AppLimitsBridge.resetAppLimit failed: $e\n$st');
      return false;
    }
  }

  /// Live status for every configured app, keyed by package name. Returns an
  /// empty map on any failure.
  static Future<Map<String, AppLimitStatus>> getStatuses() async {
    try {
      final r = await _channel.invokeMapMethod<String, dynamic>('getStatuses');
      if (r == null) return {};
      return r.map((key, value) {
        final m = Map<String, dynamic>.from(value as Map);
        final lockedMillis = (m['lockedUntilMillis'] as num?)?.toInt() ?? 0;
        return MapEntry(
          key,
          AppLimitStatus(
            usedSeconds: (m['usedSeconds'] as num?)?.toInt() ?? 0,
            remainingSeconds: (m['remainingSeconds'] as num?)?.toInt() ?? 0,
            lockedUntil: lockedMillis > 0
                ? DateTime.fromMillisecondsSinceEpoch(lockedMillis)
                : null,
          ),
        );
      });
    } catch (e, st) {
      debugPrint('AppLimitsBridge.getStatuses failed: $e\n$st');
      return {};
    }
  }

  static Future<bool> _invokeBool(String method) async {
    try {
      final r = await _channel.invokeMethod<bool>(method);
      return r ?? false;
    } catch (e, st) {
      debugPrint('AppLimitsBridge.$method failed: $e\n$st');
      return false;
    }
  }
}

/// Live native state for one App Time Limits target.
///
/// [lockedUntil] is non-null while the app is in its 24h anti-circumvention
/// lock after its daily budget was exhausted — native refuses config changes
/// for it until this deadline passes (see [AppLimitsBridge.setAppLimitConfig]).
class AppLimitStatus {
  const AppLimitStatus({
    required this.usedSeconds,
    required this.remainingSeconds,
    this.lockedUntil,
  });

  final int usedSeconds;
  final int remainingSeconds;
  final DateTime? lockedUntil;

  bool get isLocked => lockedUntil != null;
}
