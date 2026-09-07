import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart side of the commitment-break phone notification.
///
/// A break is earned at an instant nobody chooses — wherever the plan's
/// protected time divides evenly — so on the Monthly and AI plans the user had
/// no way of knowing their 30 minutes had arrived short of opening the app and
/// checking. This bridge hands the schedule to native, which owns the alarms and
/// posts the notification with the app closed (see `BreakNotifier.kt`).
///
/// The *wording* is deliberately pushed down from here rather than living in
/// Android string resources: the app's language is a per-user setting in the
/// database, not the phone's system locale, so only Dart knows which language
/// the notification should speak. Native mirrors whatever it is given into
/// SharedPreferences, so an alarm firing days later — or after a reboot, with no
/// Flutter engine anywhere — still has the right text.
///
/// Mirrors [FeedGuardBridge]'s shape: every call is wrapped so a channel failure
/// returns a safe default instead of throwing.
class BreakNotificationsBridge {
  BreakNotificationsBridge._();

  static const _channel = MethodChannel('unchained/breaks');

  /// Replaces the entire native break schedule.
  ///
  /// [nextBreakAt] is when the next break unlocks (null when none is coming),
  /// [breakAvailableNow] means one is already earned and waiting, and
  /// [breakEndsAt] is the expiry of a break the user has already claimed —
  /// which outranks both, exactly as in `computeStatus`.
  ///
  /// Anything not described by these arguments is cancelled natively, so this is
  /// safe (and intended) to call on every settings change.
  static Future<bool> sync({
    required DateTime? nextBreakAt,
    required bool breakAvailableNow,
    required DateTime? breakEndsAt,
    required int breaksLeft,
    required int breaksTotal,
    required Map<String, String> texts,
  }) async {
    try {
      final r = await _channel.invokeMethod<bool>('sync', {
        'nextBreakAt': nextBreakAt?.millisecondsSinceEpoch ?? 0,
        'breakAvailableNow': breakAvailableNow,
        'breakEndsAt': breakEndsAt?.millisecondsSinceEpoch ?? 0,
        'breaksLeft': breaksLeft,
        'breaksTotal': breaksTotal,
        'texts': texts,
      });
      return r ?? false;
    } catch (e, st) {
      debugPrint('BreakNotificationsBridge.sync failed: $e\n$st');
      return false;
    }
  }

  /// Drops every scheduled alarm and clears any visible break notification.
  /// Used when the commitment goes away entirely (plan cleared, session reset).
  static Future<bool> cancelAll() async {
    try {
      final r = await _channel.invokeMethod<bool>('cancelAll');
      return r ?? false;
    } catch (e, st) {
      debugPrint('BreakNotificationsBridge.cancelAll failed: $e\n$st');
      return false;
    }
  }
}
