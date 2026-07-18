import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart side of the "feed guard" feature: daily time budgets for Instagram
/// Reels, YouTube Shorts, TikTok and Snapchat Stories.
///
/// Enforcement happens natively via a dedicated AccessibilityService
/// (`FeedGuardService.kt`) that watches for those specific screens and backs
/// the user out once the day's budget for that target is used up. This class
/// just pushes config to native and reads back live usage; it does no
/// enforcement itself, so it keeps working even if the app is backgrounded.
///
/// Mirrors [UninstallGuardService]'s shape: every call is wrapped so a
/// channel failure returns a safe default instead of throwing.
class FeedGuardBridge {
  FeedGuardBridge._();

  static const _channel = MethodChannel('unchained/feed_guard');

  /// The four target keys understood by the native side. Match the
  /// BlockingSettings boolean field names 1:1 so callers can pass either
  /// straight through.
  static const targets = [
    'blockReels',
    'blockShorts',
    'blockTikTok',
    'blockSnapchatStories',
  ];

  /// Whether the user has switched the feed-guard accessibility service on.
  static Future<bool> isAccessibilityEnabled() =>
      _invokeBool('isAccessibilityEnabled');

  static Future<bool> openAccessibilitySettings() =>
      _invokeBool('openAccessibilitySettings');

  /// Pushes one target's enabled/limit config to native. Call for all four
  /// targets on app start, and again whenever one changes.
  static Future<bool> setTargetConfig(
    String target,
    bool enabled,
    int limitMinutes,
  ) async {
    try {
      final r = await _channel.invokeMethod<bool>('setTargetConfig', {
        'target': target,
        'enabled': enabled,
        'limitMinutes': limitMinutes,
      });
      return r ?? false;
    } catch (e, st) {
      debugPrint('FeedGuardBridge.setTargetConfig failed: $e\n$st');
      return false;
    }
  }

  /// Dev-only: clears one target's daily usage and drops its 24h exhaustion
  /// lock so the budget is fresh again immediately. Bypasses the
  /// anti-circumvention cooldown on purpose — only ever call from a
  /// [kDevTools]-gated path. Returns false on any failure.
  static Future<bool> resetTarget(String target) async {
    try {
      final r = await _channel.invokeMethod<bool>('resetTarget', {
        'target': target,
      });
      return r ?? false;
    } catch (e, st) {
      debugPrint('FeedGuardBridge.resetTarget failed: $e\n$st');
      return false;
    }
  }

  /// Live status for every target. Returns an empty map on any failure.
  static Future<Map<String, FeedGuardStatus>> getStatuses() async {
    try {
      final r = await _channel.invokeMapMethod<String, dynamic>('getStatuses');
      if (r == null) return {};
      return r.map((key, value) {
        final m = Map<String, dynamic>.from(value as Map);
        final lockedMillis = (m['lockedUntilMillis'] as num?)?.toInt() ?? 0;
        return MapEntry(
          key,
          FeedGuardStatus(
            usedSeconds: (m['usedSeconds'] as num?)?.toInt() ?? 0,
            remainingSeconds: (m['remainingSeconds'] as num?)?.toInt() ?? 0,
            lockedUntil: lockedMillis > 0
                ? DateTime.fromMillisecondsSinceEpoch(lockedMillis)
                : null,
          ),
        );
      });
    } catch (e, st) {
      debugPrint('FeedGuardBridge.getStatuses failed: $e\n$st');
      return {};
    }
  }

  /// Per-target usage history for the last 14 days: `{ target: { day: usedSeconds } }`,
  /// zero-filled for gaps. Returns an empty map on any failure.
  static Future<Map<String, Map<DateTime, int>>> getHistory() async {
    try {
      final r = await _channel.invokeMapMethod<String, dynamic>('getHistory');
      if (r == null) return {};
      return r.map((target, value) {
        final days = List<dynamic>.from(value as List);
        return MapEntry(target, {
          for (final entry in days)
            _epochDayToDate((entry as Map)['day'] as int):
                (entry['usedSeconds'] as num).toInt(),
        });
      });
    } catch (e, st) {
      debugPrint('FeedGuardBridge.getHistory failed: $e\n$st');
      return {};
    }
  }

  static Future<bool> _invokeBool(String method) async {
    try {
      final r = await _channel.invokeMethod<bool>(method);
      return r ?? false;
    } catch (e, st) {
      debugPrint('FeedGuardBridge.$method failed: $e\n$st');
      return false;
    }
  }
}

DateTime _epochDayToDate(int epochDay) =>
    DateTime.utc(1970, 1, 1).add(Duration(days: epochDay));

/// Live native state for one feed-guard target.
///
/// [lockedUntil] is non-null while the target is in its 24h anti-circumvention
/// lock after its daily budget was exhausted — native refuses config changes
/// for that target until this deadline passes (see [FeedGuardBridge.setTargetConfig]).
class FeedGuardStatus {
  const FeedGuardStatus({
    required this.usedSeconds,
    required this.remainingSeconds,
    this.lockedUntil,
  });

  final int usedSeconds;
  final int remainingSeconds;
  final DateTime? lockedUntil;

  bool get isLocked => lockedUntil != null;
}
