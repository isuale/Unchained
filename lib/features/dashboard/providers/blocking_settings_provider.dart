import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/features/blocking/blocking_service.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
import 'package:unchained/features/dashboard/data/feed_guard_bridge.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';
import 'package:unchained/features/dashboard/providers/domain_lists_provider.dart';
import 'package:unchained/features/guard/uninstall_guard_service.dart';

final blockingSettingsProvider = StreamProvider<BlockingSetting>((ref) {
  return ref.watch(blockingSettingsRepositoryProvider).watchSettings();
});

/// Ticks once per second so time-based UI (the lock countdown) refreshes
/// even when nothing in the database changes.
final _secondTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

/// Live feed-guard status for all four targets (usage + 24h exhaustion-lock
/// deadline), re-fetched from native every second so the dashboard's lock
/// countdown and re-enabled controls track native truth without needing a
/// manual refresh.
final feedGuardStatusesProvider =
    FutureProvider<Map<String, FeedGuardStatus>>((ref) async {
  ref.watch(_secondTickerProvider);
  return FeedGuardBridge.getStatuses();
});

/// The user's current spot in the plan-driven commitment, recomputed every second.
///
/// This provider does not merely *report* the phase, it enforces it:
///  - a break whose 30 minutes have run out is closed and protection put back up;
///  - being [CommitmentPhase.locked] with protection off is treated as a fault
///    and repaired, because that combination is exactly what a user who paused
///    during a break and never came back would otherwise sit in for weeks;
///  - a completed [CommitmentMode.cycle] restarts into a fresh span, and a
///    completed [CommitmentMode.fixed] clears the lock (protection stays on but
///    becomes freely toggleable).
final commitmentStatusProvider = Provider<CommitmentStatus>((ref) {
  ref.watch(_secondTickerProvider); // re-evaluate every second
  final settings = ref.watch(blockingSettingsProvider).asData?.value;
  if (settings == null) return CommitmentStatus.none_;

  final now = DateTime.now();
  final repo = ref.read(blockingSettingsRepositoryProvider);
  final status = _statusFor(settings, now);

  // A claimed break that is no longer running has expired. Close it out so the
  // next tick reads as a clean lock rather than a stale claim.
  if (settings.commitmentBreakClaimedAt != null && !status.isBreak) {
    repo.endBreak();
  }

  if (status.isCompleted) {
    if (status.mode == CommitmentMode.cycle) {
      // Repeating plan: straight into the next span, with a fresh set of breaks.
      repo.startCommitmentRun(now);
      _rearmProtection(repo);
      return computeStatus(CommitmentMode.cycle, settings.commitmentTotalDays,
          settings.commitmentBreakCount, now, now);
    }
    repo.clearCommitment();
    return CommitmentStatus.none_;
  }

  // THE ENFORCEMENT. "Locked" must mean protected. If protection is off here,
  // the user turned it off during a break and the break has since ended — put
  // it back up rather than leaving a lock badge over an unprotected phone.
  if (status.isLocked && !settings.protectionEnabled) {
    _rearmProtection(repo);
  }
  return status;
});

/// Guards against the once-a-second provider firing a second re-arm while the
/// first is still awaiting native.
bool _rearmInFlight = false;

/// When a re-arm may next be attempted. `prepare()` puts up Android's VPN
/// consent dialog if consent was revoked, and this provider re-evaluates every
/// second — without a cooldown a user who dismisses that dialog would be shown
/// it again a second later, forever.
DateTime? _rearmBlockedUntil;
const Duration _rearmCooldown = Duration(seconds: 30);

/// Brings the tunnel back up and records it. Used wherever the commitment says
/// protection must be on but it isn't.
Future<void> _rearmProtection(BlockingSettingsRepository repo) async {
  if (_rearmInFlight) return;
  final blockedUntil = _rearmBlockedUntil;
  if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) return;
  _rearmInFlight = true;
  try {
    if (!await BlockingService.isRunning()) {
      // Already-granted consent resolves immediately; no dialog is shown.
      if (!await BlockingService.prepare() || !await BlockingService.start()) {
        // Consent refused or the tunnel would not come up. Back off rather than
        // hammering; the next attempt still happens without the user asking.
        _rearmBlockedUntil = DateTime.now().add(_rearmCooldown);
        return;
      }
    }
    _rearmBlockedUntil = null;
    await repo.toggleField('protectionEnabled', true);
  } finally {
    _rearmInFlight = false;
  }
}

/// Pure helper: the commitment status for a freshly-read settings row.
CommitmentStatus _statusFor(BlockingSetting? s, DateTime now) => computeStatus(
      commitmentModeFromString(s?.commitmentMode),
      s?.commitmentTotalDays ?? 0,
      s?.commitmentBreakCount ?? 0,
      s?.commitmentStartedAt,
      now,
      breaksUsed: s?.commitmentBreaksUsed ?? 0,
      breakClaimedAt: s?.commitmentBreakClaimedAt,
    );

enum ProtectionToggleResult { ok, permissionDenied, failed, locked }

class BlockingSettingsActions extends Notifier<void> {
  @override
  void build() {
    // Chained, not parallel: both touch protectionEnabled, and the commitment
    // pass must judge the row the native reconcile has already settled.
    _reconcileWithNative().then((_) => _reconcileCommitment());
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
    await FeedGuardBridge.setSocialMode(settings.socialMode);
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
    // Routes through the actions provider so legacy subdomain-only blocklist
    // entries are upgraded to the whole site before being pushed to native.
    await ref.read(domainListsActionsProvider).syncToNative();
  }

  Future<void> _reconcileWithNative() async {
    var actuallyRunning = await BlockingService.isRunning();
    // The uninstall guard is owned natively (it survives even if the app is
    // killed), so its switch must reflect that truth, not a stale DB flag.
    final guardEnabled = await UninstallGuardService.isGuardEnabled();
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (settings == null) return;
    // Reconcile *toward* protection, not away from it. If the DB says protection
    // is on but the tunnel isn't up, something killed it without the user asking
    // (a reboot the boot receiver couldn't cover, an OS kill, a VPN revoke) —
    // restart it rather than quietly recording "off", which would turn any such
    // event into a free escape hatch.
    if (settings.protectionEnabled && !actuallyRunning) {
      final granted = await BlockingService.prepare();
      if (granted) actuallyRunning = await BlockingService.start();
    }
    if (settings.protectionEnabled != actuallyRunning) {
      await repo.toggleField('protectionEnabled', actuallyRunning);
    }
    if (settings.preventUninstall != guardEnabled) {
      await repo.toggleField('preventUninstall', guardEnabled);
    }
  }

  /// Reconciles the commitment after time has passed (app relaunch / before a
  /// toggle-off). This is the cold-start twin of [commitmentStatusProvider]'s
  /// enforcement: a break that expired while the app was closed is closed out
  /// and protection restored, a completed [CommitmentMode.cycle] restarts, and a
  /// completed [CommitmentMode.fixed] clears the lock.
  Future<void> _reconcileCommitment() async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    var settings = await repo.getSettings();
    if (settings == null) return;
    final now = DateTime.now();
    var status = _statusFor(settings, now);

    // A break claimed before the app was closed may have run out meanwhile.
    if (settings.commitmentBreakClaimedAt != null && !status.isBreak) {
      await repo.endBreak();
      settings = await repo.getSettings();
      if (settings == null) return;
      status = _statusFor(settings, now);
    }

    if (status.isCompleted) {
      if (status.mode == CommitmentMode.cycle) {
        await repo.startCommitmentRun(now);
        await _rearmProtection(repo);
      } else {
        await repo.clearCommitment();
      }
      return;
    }

    // Locked but unprotected — the state a lapsed break leaves behind. Repair it
    // here too, so closing the app during a break cannot outlast the break.
    if (status.isLocked && !settings.protectionEnabled) {
      await _rearmProtection(repo);
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
      // Coming back early ends the break. It stays spent — otherwise a user
      // could re-arm at 29 minutes and claim a fresh 30 straight after.
      final settings = await repo.getSettings();
      if (settings?.commitmentBreakClaimedAt != null) await repo.endBreak();
      await repo.toggleField('protectionEnabled', true);
      return ProtectionToggleResult.ok;
    } else {
      // Settle any expired break / finished span first, then judge the phase.
      await _reconcileCommitment();
      final settings = await repo.getSettings();
      final now = DateTime.now();
      final status = _statusFor(settings, now);
      if (status.isLocked) return ProtectionToggleResult.locked;
      // Turning protection off is how a waiting break gets claimed; from here
      // the 30 minutes start running and end with protection back on.
      if (status.isBreakAvailable) {
        await repo.claimBreak(now, settings?.commitmentBreaksUsed ?? 0);
      }
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

  /// Persists the Social section's mode and immediately pushes it to the
  /// native feed-guard watchdog, so switching to 'allSocial' takes effect
  /// (Instagram/YouTube become whole-app timers, like TikTok/Snapchat already
  /// are) without needing an app restart.
  Future<void> setSocialMode(String mode) async {
    await ref.read(blockingSettingsRepositoryProvider).setSocialMode(mode);
    await FeedGuardBridge.setSocialMode(mode);
  }

  /// Turns one Social feed block (blockReels/blockShorts/blockTikTok/
  /// blockSnapchatStories) on or off with its daily minute budget, persists
  /// it, and immediately pushes the new config to the native watchdog so
  /// enforcement takes effect without needing an app restart.
  ///
  /// Refused (returns false, no write at all) while the target is in its 24h
  /// exhaustion lock — otherwise a user could dodge the cooldown by just
  /// disabling the target or raising its limit the moment it runs out.
  Future<bool> setSocialFeedTarget(
    String field,
    bool enabled, {
    int? limitMinutes,
  }) async {
    final statuses = await FeedGuardBridge.getStatuses();
    if (statuses[field]?.isLocked == true) return false;

    final repo = ref.read(blockingSettingsRepositoryProvider);
    await repo.setSocialFeedTarget(field, enabled, limitMinutes: limitMinutes);
    final settings = await repo.getSettings();
    if (settings == null) return true;
    final minutes = switch (field) {
      'blockReels' => settings.reelsLimitMinutes,
      'blockShorts' => settings.shortsLimitMinutes,
      'blockTikTok' => settings.tiktokLimitMinutes,
      'blockSnapchatStories' => settings.snapchatLimitMinutes,
      _ => 30,
    };
    await FeedGuardBridge.setTargetConfig(field, enabled, minutes);
    return true;
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
