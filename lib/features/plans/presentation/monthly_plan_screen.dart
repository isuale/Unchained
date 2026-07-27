import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/plans/presentation/widgets/owner_entry_button.dart';
import 'package:unchained/l10n/app_localizations.dart';

class MonthlyPlanScreen extends ConsumerWidget {
  const MonthlyPlanScreen({super.key});

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
      l.monthly_feature_1,
      l.monthly_feature_2,
      l.monthly_feature_3,
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
                  l.monthly_name,
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
                  l.monthly_price,
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
                    onPressed: () => context.go('/plans/monthly/setup'),
                    child: Text(
                      l.monthly_cta,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OwnerEntryButton(
                // The commitment schedule (days/breaks) is chosen on the next
                // setup screen, not here — carry the unlock through as a
                // one-shot flag so its CTA activates for free instead of
                // sending the owner to Stripe.
                onUnlocked: () =>
                    context.push('/plans/monthly/setup', extra: true),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
