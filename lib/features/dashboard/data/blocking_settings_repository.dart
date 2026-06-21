import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/core/database/user_assessment_repository.dart';

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
    final companion = switch (field) {
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
      _ => throw ArgumentError('Unknown boolean field: $field'),
    };
    await updateSettings(companion);
  }

  Future<void> setStrictness(String level) async {
    await updateSettings(
        BlockingSettingsCompanion(strictnessLevel: Value(level)));
  }

  Future<void> setSocialMode(String mode) async {
    await updateSettings(BlockingSettingsCompanion(socialMode: Value(mode)));
  }

  Future<void> setActivePlan(String plan) async {
    await updateSettings(BlockingSettingsCompanion(activePlan: Value(plan)));
  }

  /// Persists the commitment cycle and the moment its lock expires.
  /// Pass cycle 0 / null to clear the commitment.
  Future<void> setCommitment({required int cycle, DateTime? lockUntil}) async {
    await updateSettings(BlockingSettingsCompanion(
      commitmentCycle: Value(cycle),
      commitmentLockUntil: Value(lockUntil),
    ));
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
