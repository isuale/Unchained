import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/l10n/app_localizations.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.activePlan,
    required this.streakDays,
  });

  final ActivePlan? activePlan;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/logo.png', width: 28, height: 28),
              const SizedBox(width: 10),
              Text(
                'Unchained',
                style: textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _PlanPill(
                plan: activePlan,
                l: l,
                // push (not go) so backing out of the plans screen returns
                // to the dashboard the user came from.
                onTap: () => context.push('/plans/all'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.dashboard_streak(streakDays),
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.plan, required this.l, this.onTap});
  final ActivePlan? plan;
  final AppLocalizations l;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, gradient) = _styleFor(plan, l);
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: fg.withValues(alpha: 0.75),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }

  (String, Color, Color, Gradient?) _styleFor(
      ActivePlan? plan, AppLocalizations l) {
    switch (plan) {
      case ActivePlan.monthly:
        return (
          l.dashboard_plan_pill_monthly,
          const Color(0xFF1E5FFF),
          Colors.white,
          null,
        );
      case ActivePlan.aiPlan:
        return (
          l.dashboard_plan_pill_ai_plan,
          Colors.transparent,
          Colors.white,
          const LinearGradient(
            colors: [Color(0xFF1E5FFF), Color(0xFF8B5CF6)],
          ),
        );
      case ActivePlan.forever:
        return (
          l.dashboard_plan_pill_forever,
          const Color(0xFFFFB800),
          Colors.black,
          null,
        );
      case ActivePlan.freeTrial:
      case null:
        return (
          l.dashboard_plan_pill_free_trial,
          const Color(0xFF1A2238),
          Colors.white,
          null,
        );
    }
  }
}
