import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/features/dashboard/domain/addiction_trends.dart';
import 'package:unchained/features/dashboard/domain/recovery_journey.dart';
import 'package:unchained/features/dashboard/domain/streak_progress.dart';
import 'package:unchained/features/dashboard/presentation/widgets/recovery_journey_card.dart';
import 'package:unchained/features/dashboard/presentation/widgets/trend_chart_card.dart';
import 'package:unchained/features/dashboard/providers/addiction_trends_provider.dart';
import 'package:unchained/features/dashboard/providers/blocking_settings_provider.dart';
import 'package:unchained/features/dashboard/widgets/section_title.dart';
import 'package:unchained/l10n/app_localizations.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  static const _bgTop = Color(0xFF000000);
  static const _bgBottom = Color(0xFF050812);
  static const _card = Color(0xFF0E1320);
  static const _border = Color(0xFF1A2238);
  static const _accent = Color(0xFF1E5FFF);
  static const _accent2 = Color(0xFF8B5CF6);
  static const _green = Color(0xFF00D26A);
  static const _muted = Color(0xFF888888);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final asyncSettings = ref.watch(blockingSettingsProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgBottom],
        ),
      ),
      child: asyncSettings.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: _accent),
        ),
        error: (e, _) => Center(
          child: Text(
            l.error_loading_settings('$e'),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (settings) {
          final now = DateTime.now();
          final streakDays =
              currentStreakDays(settings.protectionStartedAt, now);
          if (!settings.protectionEnabled || streakDays <= 0) {
            return _ProtectionOffState(l: l);
          }
          final weeks = weeklyStreakProgress(settings.protectionStartedAt, now);
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                Text(
                  l.nav_progress,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                _HeroStreakCard(
                  streakDays: streakDays,
                  since: settings.protectionStartedAt!,
                  l: l,
                ),
                const SizedBox(height: 24),
                SectionTitle(title: l.progress_journey_section),
                _JourneySection(settings: settings, l: l),
                const SizedBox(height: 24),
                SectionTitle(title: l.progress_weekly_section),
                _WeeklyChartCard(weeks: weeks, l: l),
                const SizedBox(height: 24),
                SectionTitle(title: l.progress_milestones_section),
                _MilestoneRow(streakDays: streakDays),
                if (settings.protectionEnabled) ...[
                  const SizedBox(height: 24),
                  SectionTitle(title: l.progress_trends_section),
                  _TrendsSection(settings: settings, l: l),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroStreakCard extends StatelessWidget {
  const _HeroStreakCard({
    required this.streakDays,
    required this.since,
    required this.l,
  });

  final int streakDays;
  final DateTime since;
  final AppLocalizations l;

  List<String> _months(AppLocalizations l) => [
        l.month_jan, l.month_feb, l.month_mar, l.month_apr,
        l.month_may, l.month_jun, l.month_jul, l.month_aug,
        l.month_sep, l.month_oct, l.month_nov, l.month_dec,
      ];

  String _shortDate(DateTime d) => '${_months(l)[d.month - 1]} ${d.day}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: ProgressScreen._card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ProgressScreen._accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [ProgressScreen._accent, ProgressScreen._accent2],
            ).createShader(bounds),
            child: Text(
              '$streakDays',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 72,
                    height: 1.0,
                  ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.progress_days_label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.progress_since(_shortDate(since)),
            style: const TextStyle(color: ProgressScreen._muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({required this.weeks, required this.l});

  final List<WeekProgress> weeks;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
      decoration: BoxDecoration(
        color: ProgressScreen._card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ProgressScreen._border),
      ),
      child: SizedBox(
        height: 190,
        child: BarChart(
          BarChartData(
            maxY: 7,
            minY: 0,
            alignment: BarChartAlignment.spaceAround,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 7,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: ProgressScreen._border,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= weeks.length) {
                      return const SizedBox.shrink();
                    }
                    final w = weeks[i];
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'W${w.weekNumber}',
                        style: TextStyle(
                          color:
                              w.isCurrent ? Colors.white : ProgressScreen._muted,
                          fontSize: 11,
                          fontWeight:
                              w.isCurrent ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => ProgressScreen._border,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final w = weeks[group.x];
                  return BarTooltipItem(
                    l.progress_week_tooltip(w.weekNumber, w.daysProtected),
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            barGroups: [
              for (var i = 0; i < weeks.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: weeks[i].daysProtected.toDouble(),
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: weeks[i].isCurrent
                            ? [ProgressScreen._accent, ProgressScreen._accent2]
                            : [
                                ProgressScreen._accent.withValues(alpha: 0.35),
                                ProgressScreen._accent.withValues(alpha: 0.55),
                              ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.streakDays});

  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final m in streakMilestones) ...[
            _MilestoneChip(days: m, achieved: streakDays >= m),
            const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.days, required this.achieved});

  final int days;
  final bool achieved;

  @override
  Widget build(BuildContext context) {
    final color = achieved ? ProgressScreen._green : ProgressScreen._muted;
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: achieved
            ? ProgressScreen._green.withValues(alpha: 0.12)
            : ProgressScreen._card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: achieved ? 0.6 : 0.4)),
      ),
      child: Column(
        children: [
          Icon(
            achieved ? Icons.check_circle : Icons.lock_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            '$days',
            style: TextStyle(
              color: achieved ? Colors.white : ProgressScreen._muted,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// The recovery-journey card: joins the protection streak (from [settings])
/// with the native blocked-per-day history (from [addictionTrendsProvider])
/// so the two numbers are shown *related* rather than side by side.
class _JourneySection extends ConsumerWidget {
  const _JourneySection({required this.settings, required this.l});

  final BlockingSetting settings;
  final AppLocalizations l;

  static const _green = Color(0xFF00D26A);
  static const _amber = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(addictionTrendsProvider);
    return trendsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: ProgressScreen._accent),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (trends) {
        final journey = buildRecoveryJourney(
          settings.protectionStartedAt,
          trends.blocked,
          DateTime.now(),
        );
        if (journey.days.isEmpty) return const SizedBox.shrink();
        return RecoveryJourneyCard(
          journey: journey,
          daysProtectedLabel: l.progress_days_label,
          temptationsBlockedLabel: l.progress_journey_temptations_label,
          insightText: _insightText(journey),
          insightColor: _insightColor(journey),
          legendDaysLabel: l.progress_journey_legend_days,
          legendTemptationsLabel: l.progress_journey_legend_temptations,
          tooltipDayProtected: (d) => l.progress_journey_tooltip_day(d),
          tooltipBlocked: (c) => l.progress_journey_tooltip_blocked(c),
        );
      },
    );
  }

  String _insightText(RecoveryJourney j) {
    if (!j.hasEnoughData) return l.progress_journey_building;
    switch (j.direction) {
      case TrendDirection.down:
        return l.progress_journey_down(j.percentChange);
      case TrendDirection.up:
        return l.progress_journey_up(j.percentChange);
      case TrendDirection.flat:
        return l.progress_journey_flat;
    }
  }

  Color _insightColor(RecoveryJourney j) {
    if (!j.hasEnoughData) return ProgressScreen._muted;
    switch (j.direction) {
      case TrendDirection.down:
        return _green;
      case TrendDirection.up:
        return _amber;
      case TrendDirection.flat:
        return ProgressScreen._muted;
    }
  }
}

/// 14-day trend charts for blocked DNS queries and enabled feed-guard
/// targets. Native data (not a Drift stream), so this fetches once via
/// [addictionTrendsProvider] rather than watching [blockingSettingsProvider].
class _TrendsSection extends ConsumerWidget {
  const _TrendsSection({required this.settings, required this.l});

  final BlockingSetting settings;
  final AppLocalizations l;

  static const _amber = Color(0xFFFFB800);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(addictionTrendsProvider);
    return trendsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: ProgressScreen._accent),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (trends) {
        final cards = <Widget>[];

        final blockedSeries = _sortedEntries(trends.blocked);
        if (blockedSeries.isNotEmpty) {
          cards.add(_buildCard(
            title: l.progress_blocked_trend_title,
            icon: Icons.shield_outlined,
            series: blockedSeries,
            unitLabel: l.progress_trend_unit_blocked,
            color: ProgressScreen._accent,
          ));
        }

        final feedTargets = [
          (
            key: 'blockReels',
            icon: Icons.movie_outlined,
            label: l.dashboard_block_reels,
            enabled: settings.blockReels,
          ),
          (
            key: 'blockShorts',
            icon: Icons.smart_display_outlined,
            label: l.dashboard_block_shorts,
            enabled: settings.blockShorts,
          ),
          (
            key: 'blockTikTok',
            icon: Icons.music_note,
            label: l.dashboard_block_tiktok,
            enabled: settings.blockTikTok,
          ),
          (
            key: 'blockSnapchatStories',
            icon: Icons.camera_alt_outlined,
            label: l.dashboard_block_snapchat,
            enabled: settings.blockSnapchatStories,
          ),
        ];

        for (final target in feedTargets) {
          if (!target.enabled) continue;
          final rawSeries = _sortedEntries(trends.feed[target.key] ?? const {});
          if (rawSeries.isEmpty) continue;
          final minuteSeries = [
            for (final e in rawSeries) MapEntry(e.key, (e.value / 60).round()),
          ];
          cards.add(_buildCard(
            title: target.label,
            icon: target.icon,
            series: minuteSeries,
            unitLabel: l.progress_trend_unit_minutes,
            color: ProgressScreen._accent2,
          ));
        }

        if (cards.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (final card in cards) ...[card, const SizedBox(height: 12)],
          ],
        );
      },
    );
  }

  TrendChartCard _buildCard({
    required String title,
    required IconData icon,
    required List<MapEntry<DateTime, int>> series,
    required String unitLabel,
    required Color color,
  }) {
    final summary = summarizeTrend(series);
    return TrendChartCard(
      title: title,
      icon: icon,
      series: series,
      unitLabel: unitLabel,
      color: color,
      insightText: _insightText(summary),
      insightColor: _insightColor(summary),
    );
  }

  String _insightText(TrendSummary s) {
    if (!s.hasEnoughData) return l.progress_trend_need_data;
    switch (s.direction) {
      case TrendDirection.down:
        return l.progress_trend_down(s.percentChange);
      case TrendDirection.up:
        return l.progress_trend_up(s.percentChange);
      case TrendDirection.flat:
        return l.progress_trend_flat;
    }
  }

  Color _insightColor(TrendSummary s) {
    if (!s.hasEnoughData) return ProgressScreen._muted;
    switch (s.direction) {
      case TrendDirection.down:
        return ProgressScreen._green;
      case TrendDirection.up:
        return _amber;
      case TrendDirection.flat:
        return ProgressScreen._muted;
    }
  }

  List<MapEntry<DateTime, int>> _sortedEntries(Map<DateTime, int> map) {
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }
}

class _ProtectionOffState extends StatelessWidget {
  const _ProtectionOffState({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timeline, color: ProgressScreen._accent, size: 56),
            const SizedBox(height: 20),
            Text(
              l.progress_off_title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l.progress_off_subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ProgressScreen._muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
