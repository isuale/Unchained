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
/// The protected span scales across six tiers from 14 up to 90 days, so a user's
/// answers genuinely change how long their plan lasts instead of everyone
/// landing on the same 90-day cycle.
///
/// This is intentionally a pure, deterministic function so the AI plan works
/// offline, instantly and privately. A real model call could later be dropped
/// in behind this same signature.
CommitmentSchedule aiScheduleFor(int percentage) {
  if (percentage <= 20) {
    return const CommitmentSchedule(
        mode: CommitmentMode.fixed, totalDays: 14, breakCount: 2);
  }
  if (percentage <= 40) {
    return const CommitmentSchedule(
        mode: CommitmentMode.fixed, totalDays: 30, breakCount: 1);
  }
  if (percentage <= 60) {
    return const CommitmentSchedule(
        mode: CommitmentMode.fixed, totalDays: 45, breakCount: 1);
  }
  if (percentage <= 75) {
    return const CommitmentSchedule(
        mode: CommitmentMode.cycle, totalDays: 60, breakCount: 1);
  }
  if (percentage <= 90) {
    return const CommitmentSchedule(
        mode: CommitmentMode.cycle, totalDays: 75, breakCount: 0);
  }
  return const CommitmentSchedule(
      mode: CommitmentMode.cycle, totalDays: 90, breakCount: 0);
}
