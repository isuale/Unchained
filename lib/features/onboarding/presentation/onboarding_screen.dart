import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/onboarding/application/onboarding_state.dart';
import 'package:unchained/features/onboarding/domain/data/onboarding_questions_data.dart';
import 'package:unchained/features/onboarding/presentation/widgets/onboarding_progress_bar.dart';
import 'package:unchained/features/onboarding/presentation/widgets/onboarding_question_view.dart';
import 'package:unchained/l10n/app_localizations.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleBack() {
    final notifier = ref.read(onboardingProvider.notifier);
    if (notifier.isFirstQuestion) return;
    notifier.goToPrevious();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _handleContinue() {
    final notifier = ref.read(onboardingProvider.notifier);
    if (notifier.isLastQuestion) {
      context.go('/onboarding/analyzing');
      return;
    }
    notifier.goToNext();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final isFirstQuestion = notifier.isFirstQuestion;

    return PopScope(
      canPop: isFirstQuestion,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.app_title),
        ),
        body: Column(
          children: [
            OnboardingProgressBar(
              currentIndex: state.currentQuestionIndex,
              totalQuestions: onboardingQuestions.length,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: onboardingQuestions.length,
                itemBuilder: (context, index) => OnboardingQuestionView(
                  question: onboardingQuestions[index],
                  onAdvance: _handleContinue,
                ),
                onPageChanged: (_) {},
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  key: ValueKey('bottom-row-${state.currentQuestionIndex}'),
                  children: [
                    if (!isFirstQuestion)
                      TextButton(
                        onPressed: _handleBack,
                        child: Text(l.onboarding_back),
                      ),
                  ],
                )
                  .animate(
                      key: ValueKey('bottom-anim-${state.currentQuestionIndex}'))
                  .fadeIn(
                    delay: const Duration(milliseconds: 1000),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  )
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    delay: const Duration(milliseconds: 1000),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                  ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
