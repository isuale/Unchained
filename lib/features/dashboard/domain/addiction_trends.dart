import 'package:flutter/foundation.dart';

/// Which way a 14-day usage/blocked-count series is trending.
enum TrendDirection { down, up, flat }

/// Summary of a day-bucketed series, comparing the mean of the first 7 days
/// against the mean of the last 7 days.
@immutable
class TrendSummary {
  const TrendSummary({
    required this.direction,
    required this.percentChange,
    required this.hasEnoughData,
  });

  final TrendDirection direction;

  /// Absolute percent change from the first-week average to the last-week
  /// average, rounded to the nearest whole number. 0 when [hasEnoughData] is
  /// false or the series is flat.
  final int percentChange;

  /// False when the series doesn't yet carry a real trend — both native
  /// trackers are new, so early days legitimately read 0 (tracking hadn't
  /// started yet) rather than "0 usage". Requiring at least 7 nonzero days
  /// out of the 14 avoids showing a misleading "down 100%!" on day one.
  final bool hasEnoughData;
}

/// Summarizes a day-ascending series of `(day, value)` entries (as returned
/// by the feed-guard/blocking-stats bridges) into a [TrendSummary]. Expects
/// up to 14 entries, oldest first; shorter series are handled gracefully.
TrendSummary summarizeTrend(List<MapEntry<DateTime, int>> series) {
  final nonZeroDays = series.where((e) => e.value > 0).length;
  if (series.length < 14 || nonZeroDays < 7) {
    return const TrendSummary(
      direction: TrendDirection.flat,
      percentChange: 0,
      hasEnoughData: false,
    );
  }

  final firstWeek = series.sublist(0, 7);
  final lastWeek = series.sublist(series.length - 7);
  final firstAvg = _average(firstWeek);
  final lastAvg = _average(lastWeek);

  if (firstAvg == 0) {
    return const TrendSummary(
      direction: TrendDirection.flat,
      percentChange: 0,
      hasEnoughData: true,
    );
  }

  final change = ((lastAvg - firstAvg) / firstAvg) * 100;
  final direction = change < -1
      ? TrendDirection.down
      : (change > 1 ? TrendDirection.up : TrendDirection.flat);

  return TrendSummary(
    direction: direction,
    percentChange: change.abs().round(),
    hasEnoughData: true,
  );
}

double _average(List<MapEntry<DateTime, int>> entries) =>
    entries.isEmpty
        ? 0
        : entries.map((e) => e.value).reduce((a, b) => a + b) /
            entries.length;
