import 'package:flutter/material.dart';
import 'package:unchained/l10n/app_localizations.dart';

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
  });

  final int currentIndex;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final progress = (currentIndex + 1) / totalQuestions;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              color: const Color(0xFF1E5FFF),
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.onboarding_question_progress(
              currentIndex + 1,
              totalQuestions,
            ),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
