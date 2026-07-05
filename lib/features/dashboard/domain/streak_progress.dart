import 'package:flutter/foundation.dart';

/// Milestones shown as chips on the Progress tab, in ascending order.
const List<int> streakMilestones = [7, 14, 30, 60, 90, 180, 365];

/// Whole days of the "days protected" streak, counting the day
/// [protectionStartedAt] falls on as day 1. Returns 0 if protection has never
/// been turned on.
int currentStreakDays(DateTime? protectionStartedAt, DateTime now) {
  if (protectionStartedAt == null) return 0;
  final start = DateTime(protectionStartedAt.year, protectionStartedAt.month,
      protectionStartedAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final elapsed = today.difference(start).inDays;
  return elapsed < 0 ? 0 : elapsed + 1;
}

/// One bucket in the weekly progress bar chart.
@immutable
class WeekProgress {
  const WeekProgress({
    required this.weekNumber,
    required this.daysProtected,
    required this.isCurrent,
  });

  /// 1-indexed week of the streak (week 1 = the 7 days starting on day 1).
  final int weekNumber;

  /// Days protected within this week so far, 0-7.
  final int daysProtected;

  /// Whether this is the week "today" falls in.
  final bool isCurrent;
}

/// Buckets the streak into weekly totals for the bar chart, most recent
/// [maxWeeks] weeks only (earlier weeks are dropped, not zeroed).
List<WeekProgress> weeklyStreakProgress(
  DateTime? protectionStartedAt,
  DateTime now, {
  int maxWeeks = 8,
}) {
  final totalDays = currentStreakDays(protectionStartedAt, now);
  if (totalDays <= 0) return const [];

  final totalWeeks = (totalDays / 7).ceil();
  final weeks = List.generate(totalWeeks, (i) {
    final daysBefore = i * 7;
    final value = (totalDays - daysBefore).clamp(0, 7);
    return WeekProgress(
      weekNumber: i + 1,
      daysProtected: value,
      isCurrent: i == totalWeeks - 1,
    );
  });

  if (weeks.length <= maxWeeks) return weeks;
  return weeks.sublist(weeks.length - maxWeeks);
}
