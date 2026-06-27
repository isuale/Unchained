import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart side of the uninstall-protection ("guard") feature.
///
/// Mirrors [BlockingService]'s shape: every call is wrapped so a channel failure
/// returns a safe default instead of throwing. Pairs with the native
/// `unchained/guard` channel in `MainActivity.kt`.
class UninstallGuardService {
  UninstallGuardService._();

  static const _channel = MethodChannel('unchained/guard');

  /// Registers [onShowLock], called by the native watchdog when the user reaches
  /// an "escape door" (App info / uninstall dialog / Play Store / accessibility
  /// settings) and we must throw up the scripture lock. Call once at startup.
  static void registerLockHandler(VoidCallback onShowLock) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'showLock') {
        onShowLock();
      }
      return null;
    });
  }

  /// Whether the user has switched our accessibility service on in system settings.
  static Future<bool> isAccessibilityEnabled() => _invokeBool('isAccessibilityEnabled');

  /// Whether "Display over other apps" is granted (needed to cover Settings).
  static Future<bool> isOverlayGranted() => _invokeBool('isOverlayGranted');

  /// Whether protection is switched on (persisted natively; the watchdog's gate).
  static Future<bool> isGuardEnabled() => _invokeBool('isGuardEnabled');

  /// Turns the watchdog gate on/off. The native side stops triggering when off.
  static Future<bool> setGuardEnabled(bool enabled) async {
    try {
      final r = await _channel.invokeMethod<bool>('setGuardEnabled', enabled);
      return r ?? false;
    } catch (e, st) {
      debugPrint('UninstallGuardService.setGuardEnabled failed: $e\n$st');
      return false;
    }
  }

  static Future<bool> openAccessibilitySettings() =>
      _invokeBool('openAccessibilitySettings');

  static Future<bool> openOverlaySettings() => _invokeBool('openOverlaySettings');

  /// Tell native the challenge was passed, opening a short grace window during
  /// which the watchdog stands down so the user can proceed.
  static Future<bool> challengePassed() => _invokeBool('challengePassed');

  /// Whether this launch was the watchdog cold-starting us to show the lock.
  /// Called once at startup so a pushed `showLock` lost to a handler-registration
  /// race can't strand the user on the normal app instead of the 800 letters.
  /// Clears the flag natively, so it returns true at most once per launch.
  static Future<bool> consumePendingLock() => _invokeBool('consumePendingLock');

  // --- Hard uninstall block (device admin / device owner) ---

  /// Whether we are an active **device administrator**. While true, Android
  /// refuses to uninstall the app until the admin is deactivated.
  static Future<bool> isDeviceAdminActive() => _invokeBool('isDeviceAdminActive');

  /// Whether we are the **device owner** — the strongest role, where uninstall
  /// can be blocked outright with no deactivate door. Requires `dpm
  /// set-device-owner` on a device with no accounts.
  static Future<bool> isDeviceOwner() => _invokeBool('isDeviceOwner');

  /// Launch the system dialog that asks the user to make us a device administrator.
  static Future<bool> requestDeviceAdmin() => _invokeBool('requestDeviceAdmin');

  /// If we are device owner, hard-block (or unblock) our own uninstall via the OS.
  /// Returns false (a no-op) when we lack the device-owner role.
  static Future<bool> lockUninstall(bool blocked) async {
    try {
      final r = await _channel.invokeMethod<bool>('lockUninstall', blocked);
      return r ?? false;
    } catch (e, st) {
      debugPrint('UninstallGuardService.lockUninstall failed: $e\n$st');
      return false;
    }
  }

  /// Relinquish the device-admin role (and lift any device-owner uninstall block).
  /// Only call after the scripture lock has been passed.
  static Future<bool> removeDeviceAdmin() => _invokeBool('removeDeviceAdmin');

  static Future<bool> _invokeBool(String method) async {
    try {
      final r = await _channel.invokeMethod<bool>(method);
      return r ?? false;
    } catch (e, st) {
      debugPrint('UninstallGuardService.$method failed: $e\n$st');
      return false;
    }
  }
}
