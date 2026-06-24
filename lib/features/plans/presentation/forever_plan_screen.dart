import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/features/dashboard/widgets/plan_activation_overlay.dart';
import 'package:unchained/l10n/app_localizations.dart';

class ForeverPlanScreen extends ConsumerWidget {
  const ForeverPlanScreen({super.key});

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
      l.forever_feature_1,
      l.forever_feature_2,
      l.forever_feature_3,
      l.forever_feature_4,
      l.forever_feature_5,
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
                  l.forever_name,
                  style: textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _animate(
                2,
                Text(
                  l.forever_price,
                  style: textTheme.headlineSmall?.copyWith(
                    color: _accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _animate(
                3,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final feature in features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                color: _accent, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                feature,
                                style: textTheme.bodyLarge
                                    ?.copyWith(color: Colors.white),
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
                4,
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
                      plan: ActivePlan.forever,
                      schedule: CommitmentSchedule.forever,
                    ),
                    child: Text(
                      l.forever_cta,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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
