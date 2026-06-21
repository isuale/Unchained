import 'package:unchained/features/onboarding/domain/data/onboarding_questions_data.dart';

enum AddictionLevel { free, mild, moderate, severe }

int calculateTotalScore(Map<String, String> selectedAnswers) {
  int total = 0;
  for (final question in onboardingQuestions) {
    final selectedId = selectedAnswers[question.id];
    if (selectedId == null) continue;
    for (final answer in question.answers) {
      if (answer.id == selectedId) {
        total += answer.points;
        break;
      }
    }
  }
  return total;
}

(int percentage, AddictionLevel level, String planId) calculatePercentageAndPlan(
  Map<String, String> selectedAnswers,
) {
  final total = calculateTotalScore(selectedAnswers);
  final percentage = ((total - 7) / 23 * 100).round().clamp(0, 100);
  if (percentage <= 10) return (percentage, AddictionLevel.free, 'free_trial');
  if (percentage <= 50) return (percentage, AddictionLevel.mild, 'monthly');
  if (percentage <= 80) return (percentage, AddictionLevel.moderate, 'ai_plan');
  return (percentage, AddictionLevel.severe, 'forever');
}
