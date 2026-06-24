import 'package:unchained/features/dashboard/domain/commitment.dart';
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

/// The AI plan's on-device "calculation": maps the onboarding addiction
/// percentage to a commitment schedule. The deeper the struggle, the longer the
/// protected span and the fewer/no breaks; the most severe cases run as a
/// never-ending [CommitmentMode.cycle].
///
/// This is intentionally a pure, deterministic function so the AI plan works
/// offline, instantly and privately. A real model call could later be dropped
/// in behind this same signature.
CommitmentSchedule aiScheduleFor(int percentage) {
  if (percentage <= 10) {
    return const CommitmentSchedule(
        mode: CommitmentMode.fixed, totalDays: 7, breakCount: 2);
  }
  if (percentage <= 50) {
    return const CommitmentSchedule(
        mode: CommitmentMode.fixed, totalDays: 21, breakCount: 1);
  }
  if (percentage <= 80) {
    return const CommitmentSchedule(
        mode: CommitmentMode.cycle, totalDays: 45, breakCount: 1);
  }
  return const CommitmentSchedule(
      mode: CommitmentMode.cycle, totalDays: 90, breakCount: 0);
}
