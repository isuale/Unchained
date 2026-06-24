import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/features/dashboard/widgets/pill_selector.dart';
import 'package:unchained/features/dashboard/widgets/plan_activation_overlay.dart';
import 'package:unchained/features/plans/presentation/widgets/schedule_summary.dart';
import 'package:unchained/l10n/app_localizations.dart';

/// Lets the user shape their Monthly commitment: how many days to protect,
/// whether to include short breaks (and how many), and whether the whole thing
/// repeats forever ("Constant"). On activation it stores the resulting
/// [CommitmentSchedule] template; the lock engages when the user first turns
/// protection on from the dashboard.
class MonthlySetupScreen extends ConsumerStatefulWidget {
  const MonthlySetupScreen({super.key});

  @override
  ConsumerState<MonthlySetupScreen> createState() => _MonthlySetupScreenState();
}

class _MonthlySetupScreenState extends ConsumerState<MonthlySetupScreen> {
  static const _accent = Color(0xFF1E5FFF);
  static const _card = Color(0xFF0E1320);
  static const _border = Color(0xFF1A2238);

  static const int _minDays = 1;
  static const int _maxDays = 90;
  static const int _maxBreaks = 10;

  int _days = 30;
  bool _withBreaks = false;
  int _breakCount = 2;
  bool _constant = false;

  CommitmentSchedule get _schedule => CommitmentSchedule(
        mode: _constant ? CommitmentMode.cycle : CommitmentMode.fixed,
        totalDays: _days,
        breakCount: _withBreaks ? _breakCount : 0,
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.go('/plans/monthly'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.monthly_setup_title,
                style: textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.monthly_setup_subtitle,
                style: textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 28),

              // Days
              _DaysCard(
                days: _days,
                min: _minDays,
                max: _maxDays,
                label: l.monthly_setup_days_label,
                onChanged: (v) => setState(() => _days = v),
              ),
              const SizedBox(height: 20),

              // Breaks on/off
              Text(
                l.monthly_setup_breaks_label.toUpperCase(),
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              PillSelector(
                leftLabel: l.monthly_setup_breaks_with,
                rightLabel: l.monthly_setup_breaks_without,
                isLeftSelected: _withBreaks,
                onSelectLeft: () => setState(() => _withBreaks = true),
                onSelectRight: () => setState(() => _withBreaks = false),
              ),

              // Break count (only when breaks are on)
              if (_withBreaks) ...[
                const SizedBox(height: 16),
                _StepperCard(
                  label: l.monthly_setup_break_count_label,
                  note: l.monthly_setup_break_note,
                  value: _breakCount,
                  min: 1,
                  max: _maxBreaks,
                  onChanged: (v) => setState(() => _breakCount = v),
                ),
              ],
              const SizedBox(height: 20),

              // Constant toggle
              _ConstantCard(
                value: _constant,
                title: l.monthly_setup_constant_label,
                subtitle: l.monthly_setup_constant_sub,
                onChanged: (v) => setState(() => _constant = v),
              ),
              const SizedBox(height: 24),

              // Summary
              Text(
                l.monthly_setup_summary_label,
                style: textTheme.labelMedium?.copyWith(
                  color: _accent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _accent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in scheduleSummaryLines(l, _schedule))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: _accent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                line,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () => PlanActivationOverlay.show(
                    context: context,
                    ref: ref,
                    plan: ActivePlan.monthly,
                    schedule: _schedule,
                  ),
                  child: Text(
                    l.monthly_setup_activate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  static Color get card => _card;
  static Color get border => _border;
}

class _DaysCard extends StatelessWidget {
  const _DaysCard({
    required this.days,
    required this.min,
    required this.max,
    required this.label,
    required this.onChanged,
  });

  final int days;
  final int min;
  final int max;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: _MonthlySetupScreenState.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _MonthlySetupScreenState.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$days',
                style: const TextStyle(
                  color: Color(0xFF1E5FFF),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: days.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: const Color(0xFF1E5FFF),
            inactiveColor: const Color(0xFF1A2238),
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

class _StepperCard extends StatelessWidget {
  const _StepperCard({
    required this.label,
    required this.note,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String note;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _MonthlySetupScreenState.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _MonthlySetupScreenState.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _RoundIconButton(
                icon: Icons.remove,
                enabled: value > min,
                onTap: () => onChanged(value - 1),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _RoundIconButton(
                icon: Icons.add,
                enabled: value < max,
                onTap: () => onChanged(value + 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF1E5FFF)
              : const Color(0xFF1A2238),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : const Color(0xFF555555),
          size: 20,
        ),
      ),
    );
  }
}

class _ConstantCard extends StatelessWidget {
  const _ConstantCard({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _MonthlySetupScreenState.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _MonthlySetupScreenState.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      color: Color(0xFF888888), fontSize: 12),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF1E5FFF),
          ),
        ],
      ),
    );
  }
}
