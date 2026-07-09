import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/features/blocking/blocking_service.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
import 'package:unchained/features/dashboard/data/feed_guard_bridge.dart';
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

/// The user's current spot in the plan-driven commitment, recomputed every second.
///
/// For a [CommitmentMode.cycle] this persists the roll-forward into the next
/// span so the cycle advances live while the app is open (not only on reopen).
/// For a [CommitmentMode.fixed] that has fully elapsed it clears the commitment,
/// leaving protection running but freely toggleable.
final commitmentStatusProvider = Provider<CommitmentStatus>((ref) {
  ref.watch(_secondTickerProvider); // re-evaluate every second
  final settings = ref.watch(blockingSettingsProvider).asData?.value;
  if (settings == null) return CommitmentStatus.none_;

  final mode = commitmentModeFromString(settings.commitmentMode);
  final days = settings.commitmentTotalDays;
  final breaks = settings.commitmentBreakCount;
  final now = DateTime.now();

  // A repeating cycle whose span elapsed — roll it forward and keep protection on.
  final newStart =
      advanceCycle(mode, days, breaks, settings.commitmentStartedAt, now);
  if (newStart != null) {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    repo.startCommitmentRun(newStart);
    repo.toggleField('protectionEnabled', true);
    BlockingService.start();
    return computeStatus(mode, days, breaks, newStart, now);
  }

  final status =
      computeStatus(mode, days, breaks, settings.commitmentStartedAt, now);
  if (status.isCompleted) {
    // A fixed span finished — clear the lock, leave protection running.
    ref.read(blockingSettingsRepositoryProvider).clearCommitment();
    return CommitmentStatus.none_;
  }
  return status;
});

/// Pure helper: the commitment status for a freshly-read settings row.
CommitmentStatus _statusFor(BlockingSetting? s, DateTime now) => computeStatus(
      commitmentModeFromString(s?.commitmentMode),
      s?.commitmentTotalDays ?? 0,
      s?.commitmentBreakCount ?? 0,
      s?.commitmentStartedAt,
      now,
    );

enum ProtectionToggleResult { ok, permissionDenied, failed, locked }

class BlockingSettingsActions extends Notifier<void> {
  @override
  void build() {
    _reconcileWithNative();
    _reconcileCommitment();
    _syncUserLists();
    _syncFeedGuardTargets();
  }

  /// Pushes the current Social feed enable/limit config to the native
  /// FeedGuardService on startup, so the watchdog enforces the right budgets
  /// even before the user touches a toggle this session.
  Future<void> _syncFeedGuardTargets() async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (settings == null) return;
    await FeedGuardBridge.setTargetConfig(
        'blockReels', settings.blockReels, settings.reelsLimitMinutes);
    await FeedGuardBridge.setTargetConfig(
        'blockShorts', settings.blockShorts, settings.shortsLimitMinutes);
    await FeedGuardBridge.setTargetConfig(
        'blockTikTok', settings.blockTikTok, settings.tiktokLimitMinutes);
    await FeedGuardBridge.setTargetConfig('blockSnapchatStories',
        settings.blockSnapchatStories, settings.snapchatLimitMinutes);
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

  /// Reconciles the commitment after time has passed (app relaunch / before a
  /// toggle-off). A lapsed [CommitmentMode.cycle] span rolls forward into a
  /// fresh span and re-arms protection; a finished [CommitmentMode.fixed] span
  /// clears the commitment (protection stays on but freely toggleable).
  Future<void> _reconcileCommitment() async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (settings == null) return;
    final mode = commitmentModeFromString(settings.commitmentMode);
    final days = settings.commitmentTotalDays;
    final breaks = settings.commitmentBreakCount;
    final now = DateTime.now();

    final newStart =
        advanceCycle(mode, days, breaks, settings.commitmentStartedAt, now);
    if (newStart != null) {
      await repo.startCommitmentRun(newStart);
      // A new span just began — make sure protection is actually running.
      final running = await BlockingService.isRunning();
      if (!running) {
        final granted = await BlockingService.prepare();
        if (granted) await BlockingService.start();
      }
      await repo.toggleField('protectionEnabled', true);
      return;
    }

    final status =
        computeStatus(mode, days, breaks, settings.commitmentStartedAt, now);
    if (status.isCompleted) {
      await repo.clearCommitment();
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
      // Roll any lapsed cycle/fixed span forward first, then refuse if still locked.
      await _reconcileCommitment();
      final settings = await repo.getSettings();
      final status = _statusFor(settings, DateTime.now());
      if (status.isLocked) return ProtectionToggleResult.locked;
      await BlockingService.stop();
      await repo.toggleField('protectionEnabled', false);
      return ProtectionToggleResult.ok;
    }
  }

  /// Begins the commitment run using the plan's stored schedule template, and
  /// turns protection on. Call this once the user has confirmed the warning.
  /// If no template is stored (e.g. free trial), this just turns protection on
  /// with no lock.
  Future<ProtectionToggleResult> startCommitment() async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final granted = await BlockingService.prepare();
    if (!granted) return ProtectionToggleResult.permissionDenied;
    final started = await BlockingService.start();
    if (!started) return ProtectionToggleResult.failed;
    final settings = await repo.getSettings();
    final mode = commitmentModeFromString(settings?.commitmentMode);
    if (mode != CommitmentMode.none) {
      await repo.startCommitmentRun(DateTime.now());
    }
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

  /// Turns one Social feed block (blockReels/blockShorts/blockTikTok/
  /// blockSnapchatStories) on or off with its daily minute budget, persists
  /// it, and immediately pushes the new config to the native watchdog so
  /// enforcement takes effect without needing an app restart.
  Future<void> setSocialFeedTarget(
    String field,
    bool enabled, {
    int? limitMinutes,
  }) async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    await repo.setSocialFeedTarget(field, enabled, limitMinutes: limitMinutes);
    final settings = await repo.getSettings();
    if (settings == null) return;
    final minutes = switch (field) {
      'blockReels' => settings.reelsLimitMinutes,
      'blockShorts' => settings.shortsLimitMinutes,
      'blockTikTok' => settings.tiktokLimitMinutes,
      'blockSnapchatStories' => settings.snapchatLimitMinutes,
      _ => 30,
    };
    await FeedGuardBridge.setTargetConfig(field, enabled, minutes);
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
    final status = _statusFor(settings, DateTime.now());
    if (status.isLocked) return false;
    await BlockingService.stop();
    await ref.read(blockingSettingsRepositoryProvider).resetSession();
    return true;
  }
}

final blockingSettingsActionsProvider =
    NotifierProvider<BlockingSettingsActions, void>(BlockingSettingsActions.new);
