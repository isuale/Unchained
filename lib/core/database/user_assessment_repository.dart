import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final userAssessmentRepositoryProvider =
    Provider<UserAssessmentRepository>((ref) {
  return UserAssessmentRepository(ref.watch(appDatabaseProvider));
});

final latestAssessmentProvider = FutureProvider<UserAssessment?>((ref) async {
  final repo = ref.watch(userAssessmentRepositoryProvider);
  return repo.getLatestAssessment();
});

class UserAssessmentRepository {
  UserAssessmentRepository(this._db);

  final AppDatabase _db;

  Future<UserAssessment> saveAssessment(UserAssessment assessment) async {
    final id = await _db.into(_db.userAssessments).insert(
          UserAssessmentsCompanion(
            totalScore: Value(assessment.totalScore),
            percentage: Value(assessment.percentage),
            level: Value(assessment.level),
            recommendedPlanId: Value(assessment.recommendedPlanId),
            createdAt: Value(assessment.createdAt),
          ),
        );
    return (_db.select(_db.userAssessments)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<UserAssessment?> getLatestAssessment() {
    return (_db.select(_db.userAssessments)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
  }
}
