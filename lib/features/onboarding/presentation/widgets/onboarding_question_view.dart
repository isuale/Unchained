import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/core/i18n/localized_text.dart';
import 'package:unchained/features/onboarding/application/onboarding_state.dart';
import 'package:unchained/features/onboarding/domain/models/onboarding_answer.dart';
import 'package:unchained/features/onboarding/domain/models/onboarding_question.dart';
import 'package:unchained/l10n/app_localizations.dart';

class OnboardingQuestionView extends ConsumerStatefulWidget {
  const OnboardingQuestionView({
    super.key,
    required this.question,
    this.onAdvance,
  });

  final OnboardingQuestion question;
  final VoidCallback? onAdvance;

  @override
  ConsumerState<OnboardingQuestionView> createState() =>
      _OnboardingQuestionViewState();
}

class _OnboardingQuestionViewState
    extends ConsumerState<OnboardingQuestionView> {
  Future<void> _handleSelect(String answerId) async {
    ref
        .read(onboardingProvider.notifier)
        .selectAnswer(widget.question.id, answerId);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    widget.onAdvance?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selectedAnswerId = ref.watch(
      onboardingProvider.select((s) => s.selectedAnswers[widget.question.id]),
    );
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            l.byKey(widget.question.textKey),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textAlign: TextAlign.left,
          )
              .animate(key: ValueKey('q-text-${widget.question.id}'))
              .fadeIn(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              )
              .slideY(
                begin: 0.2,
                end: 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              ),
          const SizedBox(height: 40),
          Column(
            children: [
              for (int i = 0; i < widget.question.answers.length; i++)
                _AnswerButton(
                  answer: widget.question.answers[i],
                  isSelected:
                      selectedAnswerId == widget.question.answers[i].id,
                  onTap: () => _handleSelect(widget.question.answers[i].id),
                )
                    .animate(
                        key: ValueKey(
                            'q-${widget.question.id}-a${widget.question.answers[i].id}'))
                    .fadeIn(
                      delay: Duration(milliseconds: 200 * (i + 1)),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    )
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: Duration(milliseconds: 200 * (i + 1)),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.answer,
    required this.isSelected,
    required this.onTap,
  });

  final OnboardingAnswer answer;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E5FFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E5FFF) : Colors.white54,
              width: 1.5,
            ),
          ),
          child: Text(
            l.byKey(answer.textKey),
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
