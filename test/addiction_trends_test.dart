import 'package:flutter_test/flutter_test.dart';
import 'package:unchained/features/dashboard/domain/addiction_trends.dart';

void main() {
  final start = DateTime.utc(2026, 1, 1);

  List<MapEntry<DateTime, int>> seriesOf(List<int> values) => [
        for (var i = 0; i < values.length; i++)
          MapEntry(start.add(Duration(days: i)), values[i]),
      ];

  group('summarizeTrend', () {
    test('empty series → not enough data', () {
      final summary = summarizeTrend(const []);
      expect(summary.hasEnoughData, isFalse);
      expect(summary.direction, TrendDirection.flat);
    });

    test('shorter than 14 days → not enough data', () {
      final summary = summarizeTrend(seriesOf(List.filled(10, 5)));
      expect(summary.hasEnoughData, isFalse);
    });

    test('14 days but mostly zero → not enough data', () {
      final values = List.filled(14, 0);
      values[13] = 30; // only today has real usage
      final summary = summarizeTrend(seriesOf(values));
      expect(summary.hasEnoughData, isFalse);
    });

    test('clear downward trend', () {
      // First week averages 100, last week averages 50 → down 50%.
      final values = [100, 100, 100, 100, 100, 100, 100, 50, 50, 50, 50, 50, 50, 50];
      final summary = summarizeTrend(seriesOf(values));
      expect(summary.hasEnoughData, isTrue);
      expect(summary.direction, TrendDirection.down);
      expect(summary.percentChange, 50);
    });

    test('clear upward trend', () {
      // First week averages 50, last week averages 100 → up 100%.
      final values = [50, 50, 50, 50, 50, 50, 50, 100, 100, 100, 100, 100, 100, 100];
      final summary = summarizeTrend(seriesOf(values));
      expect(summary.hasEnoughData, isTrue);
      expect(summary.direction, TrendDirection.up);
      expect(summary.percentChange, 100);
    });

    test('flat trend', () {
      final values = List.filled(14, 25);
      final summary = summarizeTrend(seriesOf(values));
      expect(summary.hasEnoughData, isTrue);
      expect(summary.direction, TrendDirection.flat);
      expect(summary.percentChange, 0);
    });
  });
}
