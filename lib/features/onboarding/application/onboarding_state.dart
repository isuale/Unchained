import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:unchained/features/onboarding/domain/data/onboarding_questions_data.dart';

part 'onboarding_state.freezed.dart';

@freezed
abstract class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    @Default(0) int currentQuestionIndex,
    @Default(<String, String>{}) Map<String, String> selectedAnswers,
  }) = _OnboardingState;
}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() => const OnboardingState();

  void selectAnswer(String questionId, String answerId) {
    state = state.copyWith(
      selectedAnswers: {
        ...state.selectedAnswers,
        questionId: answerId,
      },
    );
  }

  void goToNext() {
    if (isLastQuestion) return;
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
    );
  }

  void goToPrevious() {
    if (isFirstQuestion) return;
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex - 1,
    );
  }

  bool get isFirstQuestion => state.currentQuestionIndex == 0;

  bool get isLastQuestion =>
      state.currentQuestionIndex == onboardingQuestions.length - 1;

  bool get canContinue {
    final currentQuestion = onboardingQuestions[state.currentQuestionIndex];
    return state.selectedAnswers.containsKey(currentQuestion.id);
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
