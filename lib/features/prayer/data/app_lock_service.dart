import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';

/// Dart side of the prayer app-locker's native enforcement (`unchained/applock`).
///
/// Pushes the locked-app config to native so the accessibility watchdog knows
/// what to gate, opens the 24h unlock window after a prayer, and receives the
/// native push that raises the gate when a locked app is opened.
class AppLockService {
  AppLockService._();

  static const _channel = MethodChannel('unchained/applock');

  /// Push the current locked-app config to native. [lockAll] guards every app;
  /// otherwise only [packages] are guarded.
  static Future<bool> setConfig({
    required bool lockAll,
    required List<String> packages,
  }) async {
    try {
      final r = await _channel.invokeMethod<bool>('setConfig', {
        'lockAll': lockAll,
        'packages': packages,
      });
      return r ?? false;
    } catch (e, st) {
      debugPrint('AppLockService.setConfig failed: $e\n$st');
      return false;
    }
  }

  /// Open the "apps unlocked" window for [hours] (called after a finished prayer).
  static Future<bool> openUnlockWindow(int hours) async {
    try {
      final r =
          await _channel.invokeMethod<bool>('openUnlockWindow', {'hours': hours});
      return r ?? false;
    } catch (e, st) {
      debugPrint('AppLockService.openUnlockWindow failed: $e\n$st');
      return false;
    }
  }

  /// Registers [onShowPrayer], called by the native watchdog when a locked app
  /// is opened and we must raise the prayer gate. The argument is the package
  /// that triggered it. Call once at startup.
  static void registerPrayerHandler(void Function(String? package) onShowPrayer) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'showPrayer') {
        onShowPrayer(call.arguments as String?);
      }
      return null;
    });
  }

  /// Cold-start safety net: whether this launch was the watchdog opening us to
  /// pray. Returns the triggering package once (then null), mirroring
  /// [UninstallGuardService.consumePendingLock].
  static Future<String?> consumePendingPrayer() async {
    try {
      return await _channel.invokeMethod<String?>('consumePendingPrayer');
    } catch (e, st) {
      debugPrint('AppLockService.consumePendingPrayer failed: $e\n$st');
      return null;
    }
  }
}

/// Keeps native in sync with the locked-app config. Watch this provider from a
/// long-lived widget (the prayer home) so any change to the lock mode or the
/// chosen apps is pushed to the native watchdog immediately.
final appLockSyncProvider = Provider<void>((ref) {
  final lockAll = ref.watch(lockAllAppsProvider).asData?.value ?? false;
  final locked =
      ref.watch(lockedAppsProvider).asData?.value ?? const <LockedApp>[];
  final packages =
      locked.where((a) => a.enabled).map((a) => a.packageName).toList();
  AppLockService.setConfig(lockAll: lockAll, packages: packages);
});
