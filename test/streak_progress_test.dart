import 'package:flutter_test/flutter_test.dart';
import 'package:unchained/features/dashboard/domain/streak_progress.dart';

void main() {
  final start = DateTime(2026, 1, 1, 12);

  group('currentStreakDays', () {
    test('null start → 0', () {
      expect(currentStreakDays(null, start), 0);
    });

    test('same day as start → day 1', () {
      expect(currentStreakDays(start, start.add(const Duration(hours: 3))), 1);
    });

    test('exactly one calendar day later → day 2', () {
      expect(currentStreakDays(start, start.add(const Duration(days: 1))), 2);
    });

    test('10 days later → day 11', () {
      expect(currentStreakDays(start, start.add(const Duration(days: 10))), 11);
    });
  });

  group('weeklyStreakProgress', () {
    test('never started → empty', () {
      expect(weeklyStreakProgress(null, start), isEmpty);
    });

    test('day 1 → one week bucket with 1 day, marked current', () {
      final weeks = weeklyStreakProgress(start, start);
      expect(weeks, hasLength(1));
      expect(weeks.single.weekNumber, 1);
      expect(weeks.single.daysProtected, 1);
      expect(weeks.single.isCurrent, isTrue);
    });

    test('exactly 14 days in → two full weeks', () {
      final now = start.add(const Duration(days: 13)); // day 14
      final weeks = weeklyStreakProgress(start, now);
      expect(weeks, hasLength(2));
      expect(weeks[0].daysProtected, 7);
      expect(weeks[0].isCurrent, isFalse);
      expect(weeks[1].daysProtected, 7);
      expect(weeks[1].isCurrent, isTrue);
    });

    test('day 16 → weeks 1-2 full, week 3 has 2 days', () {
      final now = start.add(const Duration(days: 15));
      final weeks = weeklyStreakProgress(start, now);
      expect(weeks, hasLength(3));
      expect(weeks[0].daysProtected, 7);
      expect(weeks[1].daysProtected, 7);
      expect(weeks[2].daysProtected, 2);
      expect(weeks[2].isCurrent, isTrue);
    });

    test('caps to maxWeeks, dropping earliest weeks', () {
      final now = start.add(const Duration(days: 69)); // day 70 = 10 weeks
      final weeks = weeklyStreakProgress(start, now, maxWeeks: 4);
      expect(weeks, hasLength(4));
      expect(weeks.first.weekNumber, 7);
      expect(weeks.last.weekNumber, 10);
      expect(weeks.last.isCurrent, isTrue);
    });
  });
}
