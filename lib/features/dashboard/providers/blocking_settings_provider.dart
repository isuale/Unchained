import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/features/blocking/blocking_service.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';
import 'package:unchained/features/dashboard/domain/domain_lists.dart';
import 'package:unchained/features/guard/uninstall_guard_service.dart';

final blockingSettingsProvider = StreamProvider<BlockingSetting>((ref) {
  return ref.watch(blockingSettingsRepositoryProvider).watchSettings();
});

/// Ticks once per second so time-based UI (the lock countdown) refreshes
/// even when nothing in the database changes.
final _secondTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

/// The user's current spot in the commitment cycle, recomputed every second.
///
/// When a break has fully elapsed, this also persists the roll-forward into
/// the next (longer) lock, so the cycle advances live while the app is open —
/// not only when it's reopened.
final commitmentStatusProvider = Provider<CommitmentStatus>((ref) {
  ref.watch(_secondTickerProvider); // re-evaluate every second
  final settings = ref.watch(blockingSettingsProvider).asData?.value;
  if (settings == null) return CommitmentStatus.none_;

  final now = DateTime.now();
  final advanced = advanceIfLapsed(
    settings.commitmentCycle,
    settings.commitmentLockUntil,
    now,
  );
  if (advanced != null) {
    // Break is over — re-lock for the next cycle and keep protection on.
    final repo = ref.read(blockingSettingsRepositoryProvider);
    repo.setCommitment(cycle: advanced.cycle, lockUntil: advanced.lockUntil);
    repo.toggleField('protectionEnabled', true);
    BlockingService.start();
    return computeCommitment(advanced.cycle, advanced.lockUntil, now);
  }
  return computeCommitment(
    settings.commitmentCycle,
    settings.commitmentLockUntil,
    now,
  );
});

enum ProtectionToggleResult { ok, permissionDenied, failed, locked }

class BlockingSettingsActions extends Notifier<void> {
  @override
  void build() {
    _reconcileWithNative();
    _reconcileCommitment();
    _syncUserLists();
  }

  /// Pushes the user's stored custom block/allow lists to the native engine on
  /// startup, so a freshly launched VPN service has them even before any edit.
  Future<void> _syncUserLists() async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (settings == null) return;
    await BlockingService.setUserLists(
      blocklist: parseDomainList(settings.customBlocklist),
      allowlist: parseDomainList(settings.customAllowlist),
    );
  }

  Future<void> _reconcileWithNative() async {
    final actuallyRunning = await BlockingService.isRunning();
    // The uninstall guard is owned natively (it survives even if the app is
    // killed), so its switch must reflect that truth, not a stale DB flag.
    final guardEnabled = await UninstallGuardService.isGuardEnabled();
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (settings == null) return;
    if (settings.protectionEnabled != actuallyRunning) {
      await repo.toggleField('protectionEnabled', actuallyRunning);
    }
    if (settings.preventUninstall != guardEnabled) {
      await repo.toggleField('preventUninstall', guardEnabled);
    }
  }

  /// If a break has fully elapsed while the app was closed, roll the
  /// commitment forward into its next (longer) lock and re-arm protection.
  Future<void> _reconcileCommitment() async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (settings == null) return;
    final advanced = advanceIfLapsed(
      settings.commitmentCycle,
      settings.commitmentLockUntil,
      DateTime.now(),
    );
    if (advanced == null) return;

    await repo.setCommitment(
        cycle: advanced.cycle, lockUntil: advanced.lockUntil);
    // A new lock just began — make sure protection is actually running.
    final running = await BlockingService.isRunning();
    if (!running) {
      final granted = await BlockingService.prepare();
      if (granted) await BlockingService.start();
    }
    await repo.toggleField('protectionEnabled', true);
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
      // Roll any lapsed break forward first, then refuse if still locked.
      await _reconcileCommitment();
      final settings = await repo.getSettings();
      final status = computeCommitment(
        settings?.commitmentCycle ?? 0,
        settings?.commitmentLockUntil,
        DateTime.now(),
      );
      if (status.isLocked) return ProtectionToggleResult.locked;
      await BlockingService.stop();
      await repo.toggleField('protectionEnabled', false);
      return ProtectionToggleResult.ok;
    }
  }

  /// Begins the first commitment lock (cycle 1 = 14 days) and turns
  /// protection on. Call this once the user has confirmed the warning.
  Future<ProtectionToggleResult> startCommitment() async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final granted = await BlockingService.prepare();
    if (!granted) return ProtectionToggleResult.permissionDenied;
    final started = await BlockingService.start();
    if (!started) return ProtectionToggleResult.failed;
    final lockUntil =
        DateTime.now().add(CommitmentStatus.lockDurationForCycle(1));
    await repo.setCommitment(cycle: 1, lockUntil: lockUntil);
    await repo.toggleField('protectionEnabled', true);
    return ProtectionToggleResult.ok;
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
  ///
  /// Refused (returns false) while a commitment lock is active — leaving
  /// would be an escape hatch around the lock.
  Future<bool> leaveSession() async {
    await _reconcileCommitment();
    final settings =
        await ref.read(blockingSettingsRepositoryProvider).getSettings();
    final status = computeCommitment(
      settings?.commitmentCycle ?? 0,
      settings?.commitmentLockUntil,
      DateTime.now(),
    );
    if (status.isLocked) return false;
    await BlockingService.stop();
    await ref.read(blockingSettingsRepositoryProvider).resetSession();
    return true;
  }
}

final blockingSettingsActionsProvider =
    NotifierProvider<BlockingSettingsActions, void>(BlockingSettingsActions.new);
