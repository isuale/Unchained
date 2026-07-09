import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A 14-day line-chart card for the Progress tab's trend section, used for
/// both "blocked temptations" and per-feed usage. [series] must be day-
/// ascending, already in the unit to display (e.g. minutes, not seconds).
///
/// The insight caption ([insightText]/[insightColor]) is resolved by the
/// caller (via `summarizeTrend` + localized strings) rather than computed
/// here, so this widget stays localization-agnostic.
class TrendChartCard extends StatelessWidget {
  const TrendChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.series,
    required this.unitLabel,
    required this.color,
    required this.insightText,
    required this.insightColor,
  });

  final String title;
  final IconData icon;
  final List<MapEntry<DateTime, int>> series;
  final String unitLabel;
  final Color color;
  final String insightText;
  final Color insightColor;

  static const _card = Color(0xFF0E1320);
  static const _border = Color(0xFF1A2238);

  @override
  Widget build(BuildContext context) {
    final maxY = series.isEmpty
        ? 1.0
        : series.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            insightText,
            style: TextStyle(
              color: insightColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 1 : maxY * 1.2,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => _border,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${s.y.toInt()} $unitLabel',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < series.length; i++)
                        FlSpot(i.toDouble(), series[i].value.toDouble()),
                    ],
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.25),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
