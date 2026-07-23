import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/core/database/user_assessment_repository.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';

class BlockingSettingsRepository {
  BlockingSettingsRepository(this._db);
  final AppDatabase _db;

  Stream<BlockingSetting> watchSettings() {
    return (_db.select(_db.blockingSettings)..where((t) => t.id.equals(1)))
        .watchSingle();
  }

  Future<BlockingSetting?> getSettings() {
    return (_db.select(_db.blockingSettings)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  Future<void> updateSettings(BlockingSettingsCompanion companion) async {
    final stamped = companion.copyWith(updatedAt: Value(DateTime.now()));
    await (_db.update(_db.blockingSettings)..where((t) => t.id.equals(1)))
        .write(stamped);
  }

  Future<void> toggleField(String field, bool value) async {
    final v = Value(value);
    var companion = switch (field) {
      'protectionEnabled' => BlockingSettingsCompanion(protectionEnabled: v),
      'searchFilteringEnabled' =>
        BlockingSettingsCompanion(searchFilteringEnabled: v),
      'blockReels' => BlockingSettingsCompanion(blockReels: v),
      'blockShorts' => BlockingSettingsCompanion(blockShorts: v),
      'blockTikTok' => BlockingSettingsCompanion(blockTikTok: v),
      'blockSnapchatStories' =>
        BlockingSettingsCompanion(blockSnapchatStories: v),
      'blockShopping' => BlockingSettingsCompanion(blockShopping: v),
      'blockGambling' => BlockingSettingsCompanion(blockGambling: v),
      'blockImageVideoSearch' =>
        BlockingSettingsCompanion(blockImageVideoSearch: v),
      'appTimeLimitsEnabled' =>
        BlockingSettingsCompanion(appTimeLimitsEnabled: v),
      'customAppsBlocklistEnabled' =>
        BlockingSettingsCompanion(customAppsBlocklistEnabled: v),
      'blockInAppBrowsers' =>
        BlockingSettingsCompanion(blockInAppBrowsers: v),
      'preventUninstall' => BlockingSettingsCompanion(preventUninstall: v),
      'accountabilityPartnerEnabled' =>
        BlockingSettingsCompanion(accountabilityPartnerEnabled: v),
      'customBlockScreen' => BlockingSettingsCompanion(customBlockScreen: v),
      'customWebsitesBlocklistEnabled' =>
        BlockingSettingsCompanion(customWebsitesBlocklistEnabled: v),
      'prayerLockEnabled' => BlockingSettingsCompanion(prayerLockEnabled: v),
      _ => throw ArgumentError('Unknown boolean field: $field'),
    };
    if (field == 'protectionEnabled' && value) {
      companion = await _withProtectionStartedAt(companion);
    }
    await updateSettings(companion);
  }

  /// Stamps [protectionStartedAt] the first time protection is ever turned on,
  /// then leaves it untouched on every later toggle so commitment breaks (or a
  /// free-trial user flipping protection off and back on) don't reset the
  /// "days protected" streak shown on the Progress tab.
  Future<BlockingSettingsCompanion> _withProtectionStartedAt(
      BlockingSettingsCompanion companion) async {
    final existing = await getSettings();
    if (existing != null && existing.protectionStartedAt == null) {
      return companion.copyWith(
          protectionStartedAt: Value(DateTime.now()));
    }
    return companion;
  }

  Future<void> setStrictness(String level) async {
    await updateSettings(
        BlockingSettingsCompanion(strictnessLevel: Value(level)));
  }

  Future<void> setSocialMode(String mode) async {
    await updateSettings(BlockingSettingsCompanion(socialMode: Value(mode)));
  }

  /// Turns one of the Social feed blocks (blockReels/blockShorts/blockTikTok/
  /// blockSnapchatStories) on or off together with its daily minute budget, in
  /// a single write. [limitMinutes] is only applied when [enabled] is true —
  /// turning a feed off leaves its previously configured budget untouched so
  /// the next time it's enabled the dialog can default to the last value.
  Future<void> setSocialFeedTarget(
    String enabledField,
    bool enabled, {
    int? limitMinutes,
  }) async {
    final e = Value(enabled);
    var companion = switch (enabledField) {
      'blockReels' => BlockingSettingsCompanion(blockReels: e),
      'blockShorts' => BlockingSettingsCompanion(blockShorts: e),
      'blockTikTok' => BlockingSettingsCompanion(blockTikTok: e),
      'blockSnapchatStories' =>
        BlockingSettingsCompanion(blockSnapchatStories: e),
      _ => throw ArgumentError('Unknown social feed field: $enabledField'),
    };
    if (enabled && limitMinutes != null) {
      final m = Value(limitMinutes);
      companion = switch (enabledField) {
        'blockReels' => companion.copyWith(reelsLimitMinutes: m),
        'blockShorts' => companion.copyWith(shortsLimitMinutes: m),
        'blockTikTok' => companion.copyWith(tiktokLimitMinutes: m),
        'blockSnapchatStories' => companion.copyWith(snapchatLimitMinutes: m),
        _ => companion,
      };
    }
    await updateSettings(companion);
  }

  Future<void> setActivePlan(String plan) async {
    await updateSettings(BlockingSettingsCompanion(activePlan: Value(plan)));
  }

  /// Records that the user has passed the Terms & Conditions gate (either by
  /// agreeing or by choosing to continue at their own responsibility). Once set,
  /// the gate is not shown again until the session is reset.
  Future<void> setTermsAccepted(bool accepted) async {
    await updateSettings(
        BlockingSettingsCompanion(termsAccepted: Value(accepted)));
  }

  /// Persists the user's custom blocklist (extra domains to block), stored
  /// newline-separated. Pass the full desired list; it replaces the old one.
  Future<void> setCustomBlocklist(List<String> domains) async {
    await updateSettings(
        BlockingSettingsCompanion(customBlocklist: Value(domains.join('\n'))));
  }

  /// Persists the user's custom allowlist (domains to un-block / allow),
  /// stored newline-separated. Pass the full desired list; it replaces the old.
  Future<void> setCustomAllowlist(List<String> domains) async {
    await updateSettings(
        BlockingSettingsCompanion(customAllowlist: Value(domains.join('\n'))));
  }

  /// Stores the commitment template chosen by a plan at activation. This does
  /// not start a lock — the run begins later via [startCommitmentRun] when the
  /// user first turns protection on. Clears any in-flight run anchor.
  Future<void> setCommitmentSchedule(CommitmentSchedule schedule) async {
    await updateSettings(BlockingSettingsCompanion(
      commitmentMode: Value(commitmentModeToString(schedule.mode)),
      commitmentTotalDays: Value(schedule.totalDays),
      commitmentBreakCount: Value(schedule.breakCount),
      commitmentStartedAt: const Value(null),
    ));
  }

  /// Anchors the commitment run at [startedAt] — called the moment the user
  /// first turns protection on (or when a cycle rolls forward to a new span).
  Future<void> startCommitmentRun(DateTime startedAt) async {
    await updateSettings(
        BlockingSettingsCompanion(commitmentStartedAt: Value(startedAt)));
  }

  /// Clears the commitment entirely (used when a fixed span completes). Leaves
  /// protectionEnabled untouched — protection stays on but freely toggleable.
  Future<void> clearCommitment() async {
    await updateSettings(const BlockingSettingsCompanion(
      commitmentMode: Value(null),
      commitmentTotalDays: Value(0),
      commitmentBreakCount: Value(0),
      commitmentStartedAt: Value(null),
    ));
  }

  /// Remembers the email the user entered before Stripe checkout, so future
  /// checkouts can be pre-filled and so a returning payment can be looked up.
  Future<void> setCustomerEmail(String email) async {
    await updateSettings(
        BlockingSettingsCompanion(customerEmail: Value(email)));
  }

  /// Records the plan+schedule the user is trying to buy, right before sending
  /// them to Stripe checkout. Read back after returning from checkout (via the
  /// unchained://paid deep link) to know what to activate once payment is
  /// confirmed. [json] is a [PendingActivation] JSON-encoded by the caller.
  Future<void> setPendingActivation(String json) async {
    await updateSettings(
        BlockingSettingsCompanion(pendingActivationJson: Value(json)));
  }

  /// Clears the pending activation once it's been handled (confirmed or
  /// abandoned by the user), so a stale one is never re-applied later.
  Future<void> clearPendingActivation() async {
    await updateSettings(
        const BlockingSettingsCompanion(pendingActivationJson: Value(null)));
  }

  /// Wipes the user's session so the app behaves like a fresh install:
  /// clears the settings row back to defaults and removes the onboarding
  /// assessment history. After this, the splash screen routes to /welcome
  /// because [BlockingSetting.activePlan] is null again.
  Future<void> resetSession() async {
    await _db.delete(_db.userAssessments).go();
    await _db.delete(_db.blockingSettings).go();
    await _db.into(_db.blockingSettings).insert(
          const BlockingSettingsCompanion(id: Value(1)),
        );
  }
}

final blockingSettingsRepositoryProvider =
    Provider<BlockingSettingsRepository>((ref) {
  return BlockingSettingsRepository(ref.watch(appDatabaseProvider));
});
