import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/features/blocking/blocking_service.dart';

class BlockingNotifier extends Notifier<bool> {
  @override
  bool build() {
    _syncFromNative();
    return false;
  }

  Future<void> _syncFromNative() async {
    final running = await BlockingService.isRunning();
    if (state != running) state = running;
  }

  Future<void> toggle() async {
    if (state) {
      final stopped = await BlockingService.stop();
      if (stopped) state = false;
    } else {
      final granted = await BlockingService.prepare();
      if (!granted) return;
      final started = await BlockingService.start();
      if (started) state = true;
    }
  }
}

final blockingProvider =
    NotifierProvider<BlockingNotifier, bool>(BlockingNotifier.new);
