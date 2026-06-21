import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/core/database/user_assessment_repository.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/features/dashboard/widgets/plan_activation_overlay.dart';
import 'package:unchained/l10n/app_localizations.dart';

class AllPlansScreen extends ConsumerWidget {
  const AllPlansScreen({super.key});

  static const _accent = Color(0xFF1E5FFF);
  static const _mutedBorder = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final asyncAssessment = ref.watch(latestAssessmentProvider);
    final recommendedId = asyncAssessment.maybeWhen(
      data: (a) => a?.recommendedPlanId,
      orElse: () => null,
    );

    final plans = <_PlanCard>[
      _PlanCard(
        id: 'free_trial',
        name: l.free_trial_name,
        price: l.free_trial_price,
        features: [l.free_trial_feature_1, l.free_trial_feature_2],
        route: '/plans/free-trial',
      ),
      _PlanCard(
        id: 'monthly',
        name: l.monthly_name,
        price: l.monthly_price,
        features: [l.monthly_feature_1, l.monthly_feature_2],
        route: '/plans/monthly',
      ),
      _PlanCard(
        id: 'ai_plan',
        name: l.ai_plan_title,
        price: l.ai_plan_price_short,
        features: [l.ai_plan_feature_1, l.ai_plan_feature_5],
        route: '/plans/ai',
      ),
      _PlanCard(
        id: 'forever',
        name: l.forever_name,
        price: l.forever_price,
        features: [l.forever_feature_2, l.forever_feature_3],
        route: '/plans/forever',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  // If we were pushed on top of another screen (e.g. the
                  // dashboard), pop back to it. Otherwise (onboarding flow,
                  // reached via go) fall back to the recommended plan.
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go(_planRouteFromId(recommendedId)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l.plans_all_title,
                style: textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: plans.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final plan = plans[i];
                    final isRecommended = recommendedId == plan.id;
                    return _PlanCardWidget(
                      plan: plan,
                      isRecommended: isRecommended,
                      accent: _accent,
                      mutedBorder: _mutedBorder,
                      recommendedLabel: l.plans_recommended_badge,
                      ctaLabel: l.plans_card_cta,
                      onTap: () => PlanActivationOverlay.show(
                        context: context,
                        ref: ref,
                        plan: _activePlanFromId(plan.id),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ActivePlan _activePlanFromId(String id) => switch (id) {
      'free_trial' => ActivePlan.freeTrial,
      'monthly' => ActivePlan.monthly,
      'ai_plan' => ActivePlan.aiPlan,
      _ => ActivePlan.forever,
    };

// Back from "all plans" returns to the user's recommended plan screen
// (taken from the saved assessment), not the analyzing screen — re-running
// the analyzer with no in-memory answers would wrongly show 0%.
String _planRouteFromId(String? id) => switch (id) {
      'monthly' => '/plans/monthly',
      'ai_plan' => '/plans/ai',
      'forever' => '/plans/forever',
      _ => '/plans/free-trial',
    };

class _PlanCard {
  const _PlanCard({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
    required this.route,
  });

  final String id;
  final String name;
  final String price;
  final List<String> features;
  final String route;
}

class _PlanCardWidget extends StatelessWidget {
  const _PlanCardWidget({
    required this.plan,
    required this.isRecommended,
    required this.accent,
    required this.mutedBorder,
    required this.recommendedLabel,
    required this.ctaLabel,
    required this.onTap,
  });

  final _PlanCard plan;
  final bool isRecommended;
  final Color accent;
  final Color mutedBorder;
  final String recommendedLabel;
  final String ctaLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isRecommended ? accent : mutedBorder,
                  width: isRecommended ? 2 : 1,
                ),
                color: Colors.white.withValues(alpha: 0.03),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.price,
                    style: textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final f in plan.features)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, color: accent, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              f,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        ctaLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isRecommended)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recommendedLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
