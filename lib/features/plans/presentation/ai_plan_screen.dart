import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/core/database/user_assessment_repository.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/features/dashboard/widgets/plan_activation_overlay.dart';
import 'package:unchained/features/onboarding/domain/plan_recommendation.dart';
import 'package:unchained/features/plans/presentation/widgets/schedule_summary.dart';
import 'package:unchained/l10n/app_localizations.dart';

class AiPlanScreen extends ConsumerWidget {
  const AiPlanScreen({super.key});

  static const _accent = Color(0xFF1E5FFF);

  Widget _animate(int index, Widget child) {
    final delay = Duration(milliseconds: index * 150);
    const duration = Duration(milliseconds: 400);
    const curve = Curves.easeOutCubic;
    return child
        .animate()
        .fadeIn(delay: delay, duration: duration, curve: curve)
        .slideY(
          begin: 0.15,
          end: 0,
          delay: delay,
          duration: duration,
          curve: curve,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    // The AI plan's on-device "calculation": derive the schedule from the
    // user's onboarding result. Falls back to a moderate default if no
    // assessment exists yet (e.g. the user skipped onboarding).
    final assessment = ref.watch(latestAssessmentProvider).asData?.value;
    final schedule = aiScheduleFor(assessment?.percentage ?? 65);
    final summaryLines = scheduleSummaryLines(l, schedule);

    final features = <String>[
      l.ai_plan_feature_1,
      l.ai_plan_feature_2,
      l.ai_plan_feature_3,
      l.ai_plan_feature_4,
      l.ai_plan_feature_5,
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _animate(
                0,
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.go('/plans/all'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _animate(
                1,
                Text(
                  l.ai_plan_recommended_label.toUpperCase(),
                  style: textTheme.labelMedium?.copyWith(
                    color: _accent,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _animate(
                2,
                Text(
                  l.ai_plan_title,
                  style: textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _animate(
                3,
                Text(
                  l.ai_plan_subtitle,
                  style: textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _animate(
                4,
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '9.99',
                            style: textTheme.displayLarge?.copyWith(
                              color: _accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12, left: 6),
                            child: Text(
                              l.ai_plan_currency,
                              style: textTheme.titleMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        l.ai_plan_price_period,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _animate(
                5,
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1320),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _accent.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: _accent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l.ai_plan_computed_label,
                            style: textTheme.labelMedium?.copyWith(
                              color: _accent,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      for (final line in summaryLines)
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
              ),
              const SizedBox(height: 32),
              _animate(
                6,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final feature in features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: _accent,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _animate(
                7,
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
                      plan: ActivePlan.aiPlan,
                      schedule: schedule,
                    ),
                    child: Text(
                      l.ai_plan_cta,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _animate(
                8,
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/plans/all'),
                    child: Text(
                      l.ai_plan_view_others,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
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
}
