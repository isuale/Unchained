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

  // The plan the user picked (null = none picked yet)
  TextColumn get activePlan => text().nullable()();

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
  int get schemaVersion => 2;

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
