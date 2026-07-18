import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class UserAssessments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get totalScore => integer()();
  IntColumn get percentage => integer()();
  TextColumn get level => text()();
  TextColumn get recommendedPlanId => text()();
  DateTimeColumn get createdAt => dateTime()();
}

class BlockingSettings extends Table {
  IntColumn get id => integer().clientDefault(() => 1)();

  // Core
  BoolColumn get protectionEnabled =>
      boolean().withDefault(const Constant(false))();
  TextColumn get strictnessLevel =>
      text().withDefault(const Constant('basic'))();
  BoolColumn get searchFilteringEnabled =>
      boolean().withDefault(const Constant(true))();

  // Social
  TextColumn get socialMode =>
      text().withDefault(const Constant('reelsAndShorts'))();
  BoolColumn get blockReels =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get blockShorts =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get blockTikTok =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get blockSnapchatStories =>
      boolean().withDefault(const Constant(false))();

  // Daily time budget (minutes) for each social feed above, set via the
  // "how many minutes per day" prompt shown when the matching block* toggle is
  // turned on. Enforced natively by FeedGuardService (AccessibilityService);
  // see android/.../FeedGuardService.kt.
  IntColumn get reelsLimitMinutes =>
      integer().withDefault(const Constant(30))();
  IntColumn get shortsLimitMinutes =>
      integer().withDefault(const Constant(30))();
  IntColumn get tiktokLimitMinutes =>
      integer().withDefault(const Constant(30))();
  IntColumn get snapchatLimitMinutes =>
      integer().withDefault(const Constant(30))();

  // Content
  BoolColumn get blockShopping =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get blockGambling =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get blockImageVideoSearch =>
      boolean().withDefault(const Constant(false))();

  // App control
  BoolColumn get appTimeLimitsEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get customAppsBlocklistEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get blockInAppBrowsers =>
      boolean().withDefault(const Constant(false))();

  // Advanced
  BoolColumn get preventUninstall =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get accountabilityPartnerEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get customBlockScreen =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get customWebsitesBlocklistEnabled =>
      boolean().withDefault(const Constant(false))();

  // DEPRECATED (kept for migration safety, no longer read). The old global
  // "growing cycle" commitment. Replaced by the plan-driven schedule below.
  IntColumn get commitmentCycle =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get commitmentLockUntil => dateTime().nullable()();

  // Plan-driven commitment schedule. The active plan stores a template here at
  // activation; the run begins (commitmentStartedAt is set) only when the user
  // first turns protection on. See domain/commitment.dart.
  //  - commitmentMode: 'forever' | 'fixed' | 'cycle' | null (null = no lock).
  //  - commitmentTotalDays: total locked days across the span (forever: ignored).
  //  - commitmentBreakCount: short breaks spaced evenly inside the span.
  //  - commitmentStartedAt: run anchor; null until protection is first turned on.
  TextColumn get commitmentMode => text().nullable()();
  IntColumn get commitmentTotalDays =>
      integer().withDefault(const Constant(0))();
  IntColumn get commitmentBreakCount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get commitmentStartedAt => dateTime().nullable()();

  // Plan-agnostic streak anchor for the Progress tab: the first time
  // protectionEnabled ever flips true, set once and never moved by later
  // toggles or commitment breaks (see toggleField in the repository). Unlike
  // commitmentStartedAt, this survives commitment completion/clearing, so the
  // "days protected" streak keeps counting even after a fixed plan's lock ends.
  DateTimeColumn get protectionStartedAt => dateTime().nullable()();

  // The plan the user picked (null = none picked yet)
  TextColumn get activePlan => text().nullable()();

  // Whether the user has accepted the Terms & Conditions gate that guards the
  // control panel. Set true once the user agrees (or chooses to proceed at
  // their own responsibility); checked on entry to /dashboard so the gate is
  // shown only once. Reset to false by resetSession() (fresh-install behavior).
  BoolColumn get termsAccepted =>
      boolean().withDefault(const Constant(false))();

  // User-managed domain lists, stored newline-separated (one domain per line).
  // customBlocklist: extra sites the user chose to block, on top of the native
  // built-in list. customAllowlist: sites the user chose to un-block (allow),
  // on top of the hidden built-in allowlist asset. Both are pushed to the
  // native VPN engine; see features/dashboard/domain/domain_lists.dart.
  TextColumn get customBlocklist => text().nullable()();
  TextColumn get customAllowlist => text().nullable()();

  // Prayer app-locker. When [prayerLockAllApps] is true, every launchable app
  // is locked behind prayer and the per-app LockedApps selection is ignored;
  // when false, only the apps in LockedApps are locked. [prayerUnlockHours] is
  // how long all apps stay open after a completed prayer (default 24h).
  BoolColumn get prayerLockAllApps =>
      boolean().withDefault(const Constant(false))();
  IntColumn get prayerUnlockHours =>
      integer().withDefault(const Constant(24))();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

/// Apps the user has chosen to lock behind prayer. Opening any enabled locked
/// app while the phone is "locked" raises the 20-minute prayer gate; finishing
/// a prayer unlocks ALL of these together for the grace window. Matched by
/// [packageName] against the foreground app in the native accessibility watchdog.
@DataClassName('LockedApp')
class LockedApps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get packageName => text()();
  TextColumn get appLabel => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get addedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  // One row per package: re-adding an app updates the existing row.
  @override
  List<Set<Column>> get uniqueKeys => [
        {packageName},
      ];
}

/// Append-only history of completed prayer sessions, one row per finished
/// prayer. Powers the "days giving thanks" streak on the prayer home.
@DataClassName('PrayerEntry')
class PrayerLog extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The package whose launch triggered this prayer, or null for a voluntary
  /// "Rezar ahora" started from the home screen.
  TextColumn get triggerPackage => text().nullable()();

  /// Which prayer was prayed: 'thanksgiving' | 'rosary'.
  TextColumn get prayerType => text()();

  /// How long the prayer gate stayed on-screen, in seconds.
  IntColumn get durationSeconds => integer()();

  DateTimeColumn get completedAt => dateTime()();
}

@DriftDatabase(
    tables: [UserAssessments, BlockingSettings, LockedApps, PrayerLog])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'unchained_db'));

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _ensureSettingsRow();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(blockingSettings);
            await _ensureSettingsRow();
          }
          // For databases that already had the table (v2), add the new
          // commitment columns. v1 dbs got them via createTable above.
          if (from >= 2 && from < 3) {
            await m.addColumn(
                blockingSettings, blockingSettings.commitmentCycle);
            await m.addColumn(
                blockingSettings, blockingSettings.commitmentLockUntil);
          }
          // v4: user-managed custom block/allow domain lists.
          if (from >= 2 && from < 4) {
            await m.addColumn(
                blockingSettings, blockingSettings.customBlocklist);
            await m.addColumn(
                blockingSettings, blockingSettings.customAllowlist);
          }
          // v5: plan-driven commitment schedule (replaces the growing cycle).
          if (from >= 2 && from < 5) {
            await m.addColumn(
                blockingSettings, blockingSettings.commitmentMode);
            await m.addColumn(
                blockingSettings, blockingSettings.commitmentTotalDays);
            await m.addColumn(
                blockingSettings, blockingSettings.commitmentBreakCount);
            await m.addColumn(
                blockingSettings, blockingSettings.commitmentStartedAt);
          }
          // v6: Terms & Conditions acceptance gate for the control panel.
          if (from >= 2 && from < 6) {
            await m.addColumn(
                blockingSettings, blockingSettings.termsAccepted);
          }
          // v7: plan-agnostic streak anchor for the Progress tab.
          if (from >= 2 && from < 7) {
            await m.addColumn(
                blockingSettings, blockingSettings.protectionStartedAt);
          }
          // v8: per-feed daily time budgets for the Social section (Reels/
          // Shorts/TikTok/Snapchat Stories), enforced by FeedGuardService.
          if (from >= 2 && from < 8) {
            await m.addColumn(
                blockingSettings, blockingSettings.reelsLimitMinutes);
            await m.addColumn(
                blockingSettings, blockingSettings.shortsLimitMinutes);
            await m.addColumn(
                blockingSettings, blockingSettings.tiktokLimitMinutes);
            await m.addColumn(
                blockingSettings, blockingSettings.snapchatLimitMinutes);
          }
          // v9: prayer app-locker — the apps locked behind prayer, and the
          // completed-prayer history that powers the streak.
          if (from < 9) {
            await m.createTable(lockedApps);
            await m.createTable(prayerLog);
          }
          // v10: lock-all-apps mode + unlock-window length for the app-locker.
          if (from < 10) {
            await m.addColumn(
                blockingSettings, blockingSettings.prayerLockAllApps);
            await m.addColumn(
                blockingSettings, blockingSettings.prayerUnlockHours);
          }
        },
        beforeOpen: (details) async {
          await _ensureSettingsRow();
        },
      );

  Future<void> _ensureSettingsRow() async {
    final existing = await (select(blockingSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (existing == null) {
      await into(blockingSettings)
          .insert(BlockingSettingsCompanion(id: const Value(1)));
    }
  }
}
