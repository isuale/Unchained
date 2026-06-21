import 'package:freezed_annotation/freezed_annotation.dart';
import 'onboarding_answer.dart';

part 'onboarding_question.freezed.dart';

@freezed
abstract class OnboardingQuestion with _$OnboardingQuestion {
  const factory OnboardingQuestion({
    required String id,
    required String textKey,
    required List<OnboardingAnswer> answers,
  }) = _OnboardingQuestion;
}
