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

  // The plan the user picked (null = none picked yet)
  TextColumn get activePlan => text().nullable()();

  // User-managed domain lists, stored newline-separated (one domain per line).
  // customBlocklist: extra sites the user chose to block, on top of the native
  // built-in list. customAllowlist: sites the user chose to un-block (allow),
  // on top of the hidden built-in allowlist asset. Both are pushed to the
  // native VPN engine; see features/dashboard/domain/domain_lists.dart.
  TextColumn get customBlocklist => text().nullable()();
  TextColumn get customAllowlist => text().nullable()();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [UserAssessments, BlockingSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'unchained_db'));

  @override
  int get schemaVersion => 5;

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
