import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/features/dashboard/widgets/plan_activation_overlay.dart';
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
                    onPressed: () => context.go('/home'),
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
              const SizedBox(height: 40),
              _animate(
                5,
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
                6,
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
                7,
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
