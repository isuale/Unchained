import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';

/// Dart side of the prayer app-locker's native enforcement (`unchained/applock`).
///
/// Pushes the locked-app config to native so the accessibility watchdog knows
/// what to gate, opens the 24h unlock window after a prayer, and receives the
/// native push that raises the gate when a locked app is opened.
class AppLockService {
  AppLockService._();

  static const _channel = MethodChannel('unchained/applock');

  /// Push the current locked-app config to native. [enabled] is the master
  /// switch — when false the watchdog gates nothing at all, whatever [lockAll]
  /// and [packages] say. [lockAll] guards every app; otherwise only [packages]
  /// are guarded.
  static Future<bool> setConfig({
    required bool enabled,
    required bool lockAll,
    required List<String> packages,
  }) async {
    try {
      final r = await _channel.invokeMethod<bool>('setConfig', {
        'enabled': enabled,
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

/// Keeps native in sync with the locked-app config. Watched from the dashboard
/// (not the prayer tab) so the master switch still reaches native after the
/// prayer tab is hidden — turning the feature off is exactly the moment the
/// prayer home unmounts, and a sync that lived there would never fire.
///
/// Nothing is pushed until all three sources have loaded: emitting the
/// defaults mid-load would briefly hand native an `enabled: true` config and
/// could raise a gate the user has already switched off.
final appLockSyncProvider = Provider<void>((ref) {
  final enabled = ref.watch(prayerLockEnabledProvider).asData?.value;
  final lockAll = ref.watch(lockAllAppsProvider).asData?.value;
  final locked = ref.watch(lockedAppsProvider).asData?.value;
  if (enabled == null || lockAll == null || locked == null) return;

  final packages =
      locked.where((a) => a.enabled).map((a) => a.packageName).toList();
  AppLockService.setConfig(
    enabled: enabled,
    lockAll: lockAll,
    packages: packages,
  );
});
