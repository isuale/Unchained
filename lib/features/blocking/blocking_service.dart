import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BlockingService {
  BlockingService._();

  static const _channel = MethodChannel('unchained/blocking');

  static Future<bool> prepare() async {
    try {
      final result = await _channel.invokeMethod<bool>('prepareVpn');
      return result ?? false;
    } catch (e, st) {
      debugPrint('BlockingService.prepare failed: $e\n$st');
      return false;
    }
  }

  static Future<bool> start() async {
    try {
      final result = await _channel.invokeMethod<bool>('startBlocking');
      return result ?? false;
    } catch (e, st) {
      debugPrint('BlockingService.start failed: $e\n$st');
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopBlocking');
      return result ?? false;
    } catch (e, st) {
      debugPrint('BlockingService.stop failed: $e\n$st');
      return false;
    }
  }

  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isRunning');
      return result ?? false;
    } catch (e, st) {
      debugPrint('BlockingService.isRunning failed: $e\n$st');
      return false;
    }
  }

  /// Pushes the user's custom block / allow domain lists to the native VPN
  /// engine. Persisted natively too, so they survive a service restart. Safe
  /// to call whether or not protection is currently running.
  static Future<bool> setUserLists({
    required List<String> blocklist,
    required List<String> allowlist,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('setUserLists', {
        'blocklist': blocklist,
        'allowlist': allowlist,
      });
      return result ?? false;
    } catch (e, st) {
      debugPrint('BlockingService.setUserLists failed: $e\n$st');
      return false;
    }
  }

  /// The native built-in blocklist (the always-blocked adult domains), shown
  /// read-only in the Blocklist UI. Returns an empty list on failure.
  static Future<List<String>> builtinBlocklist() async {
    try {
      final result =
          await _channel.invokeListMethod<String>('getBuiltinBlocklist');
      return result ?? const [];
    } catch (e, st) {
      debugPrint('BlockingService.builtinBlocklist failed: $e\n$st');
      return const [];
    }
  }

  /// How many domains the built-in porn blocklist contains (~1000), for the
  /// "N sites blocked" summary. Returns 0 on failure.
  static Future<int> builtinBlocklistCount() async {
    try {
      final result =
          await _channel.invokeMethod<int>('getBuiltinBlocklistCount');
      return result ?? 0;
    } catch (e, st) {
      debugPrint('BlockingService.builtinBlocklistCount failed: $e\n$st');
      return 0;
    }
  }
}
