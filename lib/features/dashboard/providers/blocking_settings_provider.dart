import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/features/blocking/blocking_service.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';

final blockingSettingsProvider = StreamProvider<BlockingSetting>((ref) {
  return ref.watch(blockingSettingsRepositoryProvider).watchSettings();
});

enum ProtectionToggleResult { ok, permissionDenied, failed }

class BlockingSettingsActions extends Notifier<void> {
  @override
  void build() {
    _reconcileWithNative();
  }

  Future<void> _reconcileWithNative() async {
    final actuallyRunning = await BlockingService.isRunning();
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (settings == null) return;
    if (settings.protectionEnabled != actuallyRunning) {
      await repo.toggleField('protectionEnabled', actuallyRunning);
    }
  }

  Future<void> toggle(String field, bool value) {
    return ref
        .read(blockingSettingsRepositoryProvider)
        .toggleField(field, value);
  }

  Future<ProtectionToggleResult> toggleProtection(bool desired) async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    if (desired) {
      final granted = await BlockingService.prepare();
      if (!granted) return ProtectionToggleResult.permissionDenied;
      final started = await BlockingService.start();
      if (!started) return ProtectionToggleResult.failed;
      await repo.toggleField('protectionEnabled', true);
      return ProtectionToggleResult.ok;
    } else {
      await BlockingService.stop();
      await repo.toggleField('protectionEnabled', false);
      return ProtectionToggleResult.ok;
    }
  }

  Future<void> setStrictness(String level) {
    return ref
        .read(blockingSettingsRepositoryProvider)
        .setStrictness(level);
  }

  Future<void> setSocialMode(String mode) {
    return ref.read(blockingSettingsRepositoryProvider).setSocialMode(mode);
  }

  /// Turns off the native VPN and wipes the local session so the user can
  /// start over from the welcome screen as if newly installed.
  Future<void> leaveSession() async {
    await BlockingService.stop();
    await ref.read(blockingSettingsRepositoryProvider).resetSession();
  }
}

final blockingSettingsActionsProvider =
    NotifierProvider<BlockingSettingsActions, void>(BlockingSettingsActions.new);
