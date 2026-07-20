import 'package:drift/drift.dart';
import 'package:unchained/core/database/app_database.dart';

/// Persisted state for the "App Time Limits" feature: which apps the user
/// picked, and each one's daily minute budget.
class AppLimitsRepository {
  AppLimitsRepository(this._db);

  final AppDatabase _db;

  Stream<List<AppTimeLimit>> watchAppLimits() {
    return (_db.select(_db.appTimeLimits)
          ..orderBy([(t) => OrderingTerm.asc(t.appLabel)]))
        .watch();
  }

  Future<List<AppTimeLimit>> getAppLimits() {
    return (_db.select(_db.appTimeLimits)
          ..orderBy([(t) => OrderingTerm.asc(t.appLabel)]))
        .get();
  }

  /// Add (or re-configure) an app's daily limit. Re-adding the same package
  /// updates the existing row rather than duplicating it.
  Future<void> setAppLimit({
    required String packageName,
    required String appLabel,
    required bool enabled,
    required int dailyLimitMinutes,
  }) {
    return _db.into(_db.appTimeLimits).insert(
          AppTimeLimitsCompanion(
            packageName: Value(packageName),
            appLabel: Value(appLabel),
            enabled: Value(enabled),
            dailyLimitMinutes: Value(dailyLimitMinutes),
          ),
          onConflict: DoUpdate(
            (_) => AppTimeLimitsCompanion(
              appLabel: Value(appLabel),
              enabled: Value(enabled),
              dailyLimitMinutes: Value(dailyLimitMinutes),
            ),
            target: [_db.appTimeLimits.packageName],
          ),
        );
  }

  Future<void> setAppLimitEnabled(String packageName, bool enabled) {
    return (_db.update(_db.appTimeLimits)
          ..where((t) => t.packageName.equals(packageName)))
        .write(AppTimeLimitsCompanion(enabled: Value(enabled)));
  }

  Future<void> removeAppLimit(String packageName) {
    return (_db.delete(_db.appTimeLimits)
          ..where((t) => t.packageName.equals(packageName)))
        .go();
  }
}
