import 'package:flutter/foundation.dart';

import 'package:unchained/features/dashboard/domain/addiction_trends.dart';
import 'package:unchained/features/dashboard/domain/streak_progress.dart';

/// One day on the recovery journey: how many days of protection the user had
/// banked by that date, and how many temptations were blocked that same day.
/// This is the pairing that lets the Progress tab *relate* the two numbers
/// instead of charting each in isolation.
@immutable
class RecoveryDay {
  const RecoveryDay({
    required this.date,
    required this.dayOfProtection,
    required this.blockedAttempts,
  });

  /// The calendar day (date-only) this bucket covers.
  final DateTime date;

  /// The streak day number on this date (1 = first protected day). 0 for days
  /// before protection was ever turned on.
  final int dayOfProtection;

  /// Temptations blocked on this date.
  final int blockedAttempts;
}

/// The joined "days protected ↔ temptations blocked" story for the Progress
/// tab. Pure/testable: it takes the native blocked-history map and the
/// protection anchor and produces one aligned series plus the headline
/// relationship between the two variables.
@immutable
class RecoveryJourney {
  const RecoveryJourney({
    required this.days,
    required this.streakDays,
    required this.totalBlocked,
    required this.peakBlocked,
    required this.direction,
    required this.percentChange,
    required this.hasEnoughData,
  });

  /// Per-day buckets, oldest first, restricted to days on or after protection
  /// started (so the pairing is always meaningful).
  final List<RecoveryDay> days;

  /// Current streak length in days.
  final int streakDays;

  /// Total temptations blocked across [days].
  final int totalBlocked;

  /// The highest single-day blocked count in [days] (0 if none).
  final int peakBlocked;

  /// Whether daily temptations are trending down, up, or flat as the streak
  /// grows — the direction of the relationship between the two variables.
  final TrendDirection direction;

  /// Magnitude of [direction], first-week vs last-week average, whole percent.
  final int percentChange;

  /// False while the series is too young to carry a real relationship.
  final bool hasEnoughData;

  /// Average temptations blocked per protected day, rounded, over [days].
  int get averagePerDay =>
      days.isEmpty ? 0 : (totalBlocked / days.length).round();
}

/// Joins the native blocked-per-day history with the protection streak into a
/// single [RecoveryJourney]. Only days on/after [protectionStartedAt] are
/// kept, so every bucket carries a real "day N protected" number to pair with
/// its blocked count. Returns an empty journey when protection never started.
RecoveryJourney buildRecoveryJourney(
  DateTime? protectionStartedAt,
  Map<DateTime, int> blockedHistory,
  DateTime now,
) {
  final streakDays = currentStreakDays(protectionStartedAt, now);
  if (protectionStartedAt == null || streakDays <= 0) {
    return const RecoveryJourney(
      days: [],
      streakDays: 0,
      totalBlocked: 0,
      peakBlocked: 0,
      direction: TrendDirection.flat,
      percentChange: 0,
      hasEnoughData: false,
    );
  }

  final start = _dateOnly(protectionStartedAt);
  final days = <RecoveryDay>[];
  final entries = blockedHistory.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));

  for (final entry in entries) {
    final date = _dateOnly(entry.key);
    if (date.isBefore(start)) continue;
    days.add(RecoveryDay(
      date: date,
      dayOfProtection: currentStreakDays(protectionStartedAt, date),
      blockedAttempts: entry.value,
    ));
  }

  final totalBlocked =
      days.fold<int>(0, (sum, d) => sum + d.blockedAttempts);
  final peakBlocked = days.fold<int>(
      0, (max, d) => d.blockedAttempts > max ? d.blockedAttempts : max);

  final summary = summarizeTrend([
    for (final d in days) MapEntry(d.date, d.blockedAttempts),
  ]);

  return RecoveryJourney(
    days: days,
    streakDays: streakDays,
    totalBlocked: totalBlocked,
    peakBlocked: peakBlocked,
    direction: summary.direction,
    percentChange: summary.percentChange,
    hasEnoughData: summary.hasEnoughData,
  );
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
