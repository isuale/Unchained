import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/core/database/app_database.dart';
import 'package:unchained/core/database/user_assessment_repository.dart';
import 'package:unchained/features/onboarding/application/onboarding_state.dart';
import 'package:unchained/features/onboarding/domain/plan_recommendation.dart';
import 'package:unchained/l10n/app_localizations.dart';

class AnalyzingScreen extends ConsumerStatefulWidget {
  const AnalyzingScreen({super.key});

  @override
  ConsumerState<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends ConsumerState<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final int _percentage;
  late final AddictionLevel _level;
  late final String _planId;
  late final int _totalScore;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    final selectedAnswers = ref.read(onboardingProvider).selectedAnswers;
    final result = calculatePercentageAndPlan(selectedAnswers);
    _percentage = result.$1;
    _level = result.$2;
    _planId = result.$3;
    _totalScore = calculateTotalScore(selectedAnswers);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _controller.addStatusListener(_onAnimationStatus);
    _controller.forward();
  }

  Future<void> _onAnimationStatus(AnimationStatus status) async {
    if (status != AnimationStatus.completed) return;
    await HapticFeedback.mediumImpact();
    final repo = ref.read(userAssessmentRepositoryProvider);
    await repo.saveAssessment(
      UserAssessment(
        id: 0,
        totalScore: _totalScore,
        percentage: _percentage,
        level: _level.name,
        recommendedPlanId: _planId,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    setState(() => _showResult = true);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  Color _colorForPercentage(int p) {
    if (p <= 10) return const Color(0xFF4ADE80);
    if (p <= 50) return const Color(0xFF1E5FFF);
    if (p <= 80) return const Color(0xFFFFA500);
    return const Color(0xFFEF4444);
  }

  int _stepFromValue(double v) {
    if (v < 0.25) return 0;
    if (v < 0.5) return 1;
    if (v < 0.75) return 2;
    return 3;
  }

  String _stepLabel(int index, AppLocalizations l) {
    switch (index) {
      case 0:
        return l.analyzing_step_1;
      case 1:
        return l.analyzing_step_2;
      case 2:
        return l.analyzing_step_3;
      default:
        return l.analyzing_step_4;
    }
  }

  String _planName(String planId, AppLocalizations l) {
    switch (planId) {
      case 'free_trial':
        return l.analyzing_plan_free_trial_name;
      case 'monthly':
        return l.analyzing_plan_monthly_name;
      case 'ai_plan':
        return l.analyzing_plan_ai_plan_name;
      default:
        return l.analyzing_plan_forever_name;
    }
  }

  String _planDesc(String planId, AppLocalizations l) {
    switch (planId) {
      case 'free_trial':
        return l.analyzing_plan_free_trial_desc;
      case 'monthly':
        return l.analyzing_plan_monthly_desc;
      case 'ai_plan':
        return l.analyzing_plan_ai_plan_desc;
      default:
        return l.analyzing_plan_forever_desc;
    }
  }

  String _planRoute(String planId) {
    switch (planId) {
      case 'free_trial':
        return '/plans/free-trial';
      case 'monthly':
        return '/plans/monthly';
      case 'ai_plan':
        return '/plans/ai';
      default:
        return '/plans/forever';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),
              Text(
                l.analyzing_title,
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 24,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final stepIndex = _stepFromValue(_controller.value);
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _stepLabel(stepIndex, l),
                        key: ValueKey(stepIndex),
                        style: textTheme.bodyMedium
                            ?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 48),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final currentPct =
                      (_controller.value * _percentage).round();
                  final color = _colorForPercentage(currentPct);
                  return Column(
                    children: [
                      Text(
                        currentPct.toString(),
                        style: textTheme.displayLarge?.copyWith(
                          color: color,
                          fontSize: 96,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.analyzing_addicted_label,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: Colors.white54),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final currentPct =
                      (_controller.value * _percentage).round();
                  final color = _colorForPercentage(currentPct);
                  return Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white12,
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _controller.value * (_percentage / 100),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: color,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              AnimatedOpacity(
                opacity: _showResult ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.analyzing_recommend_label.toUpperCase(),
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white54,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _planName(_planId, l),
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _planDesc(_planId, l),
                        style: textTheme.bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedOpacity(
                opacity: _showResult ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E5FFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        onPressed: _showResult
                            ? () => context.go(_planRoute(_planId))
                            : null,
                        child: Text(
                          l.analyzing_see_plan_button,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _showResult
                          ? () => context.go('/plans/all')
                          : null,
                      child: Text(
                        l.analyzing_skip_to_plans,
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
