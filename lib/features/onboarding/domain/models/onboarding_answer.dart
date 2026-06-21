import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_answer.freezed.dart';

@freezed
abstract class OnboardingAnswer with _$OnboardingAnswer {
  const factory OnboardingAnswer({
    required String id,
    required String textKey,
    required int points,
  }) = _OnboardingAnswer;
}
