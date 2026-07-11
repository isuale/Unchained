import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:unchained/features/dashboard/domain/recovery_journey.dart';

/// The centrepiece of the Progress tab: one card that *relates* the two
/// numbers the user cares about — how many days they've stayed protected and
/// how many temptations got blocked over those same days. A rising line (days
/// protected) crossed against a falling line/area (daily temptations) tells
/// the recovery story at a glance, with the headline stats and an insight
/// caption spelling out the relationship.
class RecoveryJourneyCard extends StatelessWidget {
  const RecoveryJourneyCard({
    super.key,
    required this.journey,
    required this.daysProtectedLabel,
    required this.temptationsBlockedLabel,
    required this.insightText,
    required this.insightColor,
    required this.legendDaysLabel,
    required this.legendTemptationsLabel,
    required this.tooltipDayProtected,
    required this.tooltipBlocked,
  });

  final RecoveryJourney journey;
  final String daysProtectedLabel;
  final String temptationsBlockedLabel;
  final String insightText;
  final Color insightColor;
  final String legendDaysLabel;
  final String legendTemptationsLabel;

  /// `(dayNumber) => "Day N protected"`.
  final String Function(int) tooltipDayProtected;

  /// `(count) => "N blocked"`.
  final String Function(int) tooltipBlocked;

  static const _card = Color(0xFF0E1320);
  static const _border = Color(0xFF1A2238);
  static const _accent = Color(0xFF1E5FFF);
  static const _green = Color(0xFF00D26A);
  static const _amber = Color(0xFFFFB800);
  static const _muted = Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatRow(
            journey: journey,
            daysProtectedLabel: daysProtectedLabel,
            temptationsBlockedLabel: temptationsBlockedLabel,
          ),
          const SizedBox(height: 10),
          Text(
            insightText,
            style: TextStyle(
              color: insightColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: _JourneyChart(
              journey: journey,
              tooltipDayProtected: tooltipDayProtected,
              tooltipBlocked: tooltipBlocked,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: _green, label: legendDaysLabel),
              const SizedBox(width: 18),
              _LegendDot(color: _amber, label: legendTemptationsLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.journey,
    required this.daysProtectedLabel,
    required this.temptationsBlockedLabel,
  });

  final RecoveryJourney journey;
  final String daysProtectedLabel;
  final String temptationsBlockedLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _Stat(
            value: '${journey.streakDays}',
            label: daysProtectedLabel,
            color: RecoveryJourneyCard._green,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.link_rounded,
            color: RecoveryJourneyCard._muted,
            size: 20,
          ),
        ),
        Expanded(
          child: _Stat(
            value: '${journey.totalBlocked}',
            label: temptationsBlockedLabel,
            color: RecoveryJourneyCard._amber,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: RecoveryJourneyCard._muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Two overlaid line series on a shared x-axis: temptations blocked per day
/// (amber, filled, on its real scale) and the climbing "days protected"
/// progress (green, normalized to the same height). The crossing shape — one
/// falling, one rising — is the whole point of the card.
class _JourneyChart extends StatelessWidget {
  const _JourneyChart({
    required this.journey,
    required this.tooltipDayProtected,
    required this.tooltipBlocked,
  });

  final RecoveryJourney journey;
  final String Function(int) tooltipDayProtected;
  final String Function(int) tooltipBlocked;

  @override
  Widget build(BuildContext context) {
    final days = journey.days;
    final n = days.length;
    final maxBlocked = journey.peakBlocked;
    final maxY = (maxBlocked <= 0 ? 1 : maxBlocked) * 1.25;

    // Normalize the protection-day line into the blocked axis so it rises
    // across the window as a progress track (it's labeled in the legend).
    final firstDay = days.first.dayOfProtection;
    final lastDay = days.last.dayOfProtection;
    final daySpan = (lastDay - firstDay);
    double protectionY(int dayOfProtection) {
      if (daySpan <= 0) return maxY * 0.9;
      final t = (dayOfProtection - firstDay) / daySpan;
      // Keep it inside the frame, climbing 15% -> 90% of the height.
      return maxY * (0.15 + 0.75 * t);
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (n - 1).toDouble(),
        minY: 0,
        maxY: maxY.toDouble(),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => RecoveryJourneyCard._border,
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.toInt();
              final day = (i >= 0 && i < n) ? days[i] : null;
              final isProtection = s.barIndex == 1;
              final text = day == null
                  ? ''
                  : isProtection
                      ? tooltipDayProtected(day.dayOfProtection)
                      : tooltipBlocked(day.blockedAttempts);
              return LineTooltipItem(
                text,
                TextStyle(
                  color: isProtection
                      ? RecoveryJourneyCard._green
                      : RecoveryJourneyCard._amber,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          // Temptations blocked (real scale, filled area).
          LineChartBarData(
            spots: [
              for (var i = 0; i < n; i++)
                FlSpot(i.toDouble(), days[i].blockedAttempts.toDouble()),
            ],
            isCurved: true,
            preventCurveOverShooting: true,
            color: RecoveryJourneyCard._amber,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  RecoveryJourneyCard._amber.withValues(alpha: 0.28),
                  RecoveryJourneyCard._amber.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // Days protected (normalized progress track).
          LineChartBarData(
            spots: [
              for (var i = 0; i < n; i++)
                FlSpot(i.toDouble(), protectionY(days[i].dayOfProtection)),
            ],
            isCurved: false,
            color: RecoveryJourneyCard._green,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            dashArray: const [5, 4],
          ),
        ],
      ),
    );
  }
}
