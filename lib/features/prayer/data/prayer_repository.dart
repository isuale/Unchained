import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/core/database/user_assessment_repository.dart';

/// Single access point for the prayer app-locker's persisted state: which apps
/// are locked behind prayer, and the history of completed prayers.
final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  return PrayerRepository(ref.watch(appDatabaseProvider));
});

/// Live list of apps the user has locked behind prayer, alphabetically.
final lockedAppsProvider = StreamProvider<List<LockedApp>>((ref) {
  return ref.watch(prayerRepositoryProvider).watchLockedApps();
});

/// Live history of completed prayers, newest first.
final prayerLogProvider = StreamProvider<List<PrayerEntry>>((ref) {
  return ref.watch(prayerRepositoryProvider).watchPrayerLog();
});

/// The current "days giving thanks" streak: consecutive days (up to and
/// including today) on which at least one prayer was completed.
final prayerStreakProvider = Provider<int>((ref) {
  final log = ref.watch(prayerLogProvider).asData?.value ?? const [];
  return PrayerRepository.streakFrom(log);
});

class PrayerRepository {
  PrayerRepository(this._db);

  final AppDatabase _db;

  // --- Locked apps ---

  Stream<List<LockedApp>> watchLockedApps() {
    return (_db.select(_db.lockedApps)
          ..orderBy([(t) => OrderingTerm.asc(t.appLabel)]))
        .watch();
  }

  Future<List<LockedApp>> getLockedApps() {
    return (_db.select(_db.lockedApps)
          ..orderBy([(t) => OrderingTerm.asc(t.appLabel)]))
        .get();
  }

  /// Add (or re-enable) an app to the locked set. Re-adding the same package
  /// refreshes its label and turns it back on rather than duplicating the row.
  Future<void> addLockedApp(String packageName, String appLabel) {
    return _db.into(_db.lockedApps).insert(
          LockedAppsCompanion(
            packageName: Value(packageName),
            appLabel: Value(appLabel),
            enabled: const Value(true),
          ),
          onConflict: DoUpdate(
            (_) => LockedAppsCompanion(
              appLabel: Value(appLabel),
              enabled: const Value(true),
            ),
            target: [_db.lockedApps.packageName],
          ),
        );
  }

  Future<void> removeLockedApp(String packageName) {
    return (_db.delete(_db.lockedApps)
          ..where((t) => t.packageName.equals(packageName)))
        .go();
  }

  Future<void> setLockedAppEnabled(String packageName, bool enabled) {
    return (_db.update(_db.lockedApps)
          ..where((t) => t.packageName.equals(packageName)))
        .write(LockedAppsCompanion(enabled: Value(enabled)));
  }

  // --- Prayer history ---

  Stream<List<PrayerEntry>> watchPrayerLog() {
    return (_db.select(_db.prayerLog)
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .watch();
  }

  /// Record a finished prayer. [triggerPackage] is the app whose launch raised
  /// the gate, or null for a voluntary prayer from the home screen.
  Future<void> logPrayer({
    String? triggerPackage,
    required String prayerType,
    required int durationSeconds,
    required DateTime completedAt,
  }) {
    return _db.into(_db.prayerLog).insert(
          PrayerLogCompanion(
            triggerPackage: Value(triggerPackage),
            prayerType: Value(prayerType),
            durationSeconds: Value(durationSeconds),
            completedAt: Value(completedAt),
          ),
        );
  }

  /// Consecutive-day streak ending today (or yesterday, so a not-yet-prayed
  /// today doesn't instantly break it), derived from a newest-first [log].
  static int streakFrom(List<PrayerEntry> log) {
    if (log.isEmpty) return 0;
    final days = <DateTime>{
      for (final e in log)
        DateTime(e.completedAt.year, e.completedAt.month, e.completedAt.day),
    };
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);
    // Allow the streak to still count if today hasn't been prayed yet.
    if (!days.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!days.contains(cursor)) return 0;
    }
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
