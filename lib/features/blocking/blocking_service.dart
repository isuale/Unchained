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
}
