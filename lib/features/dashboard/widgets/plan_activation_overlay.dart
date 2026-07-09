import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/l10n/app_localizations.dart';

class PlanActivationOverlay {
  PlanActivationOverlay._();

  /// Activates [plan] and, if given, stores its commitment [schedule] template.
  /// The lock itself only engages when the user first turns protection on. Pass
  /// a null [schedule] (or [CommitmentSchedule.none]) for plans with no lock
  /// (e.g. the free trial), which clears any previous template.
  ///
  /// Refused while a commitment lock is currently active (locked or on a
  /// break) — switching plans must never be usable as a back door to wipe
  /// the running lock and free up the protection toggle.
  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required ActivePlan plan,
    CommitmentSchedule? schedule,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => const _ActivationSpinner(),
    );

    await Future.delayed(const Duration(milliseconds: 800));

    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    final mode = commitmentModeFromString(settings?.commitmentMode);
    final days = settings?.commitmentTotalDays ?? 0;
    final breaks = settings?.commitmentBreakCount ?? 0;
    final now = DateTime.now();
    final rolledStart =
        advanceCycle(mode, days, breaks, settings?.commitmentStartedAt, now);
    final status = computeStatus(
        mode, days, breaks, rolledStart ?? settings?.commitmentStartedAt, now);

    if (status.isActive) {
      if (!context.mounted) return;
      navigator.pop();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => const _ActivationLocked(),
      );
      return;
    }

    await ref.read(activePlanActionsProvider.notifier).setActivePlan(plan);
    await repo.setCommitmentSchedule(schedule ?? CommitmentSchedule.none);

    if (!context.mounted) return;
    navigator.pop();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => const _ActivationDone(),
    );

    await Future.delayed(const Duration(milliseconds: 400));
    if (!context.mounted) return;
    navigator.pop();
    // Gate the control panel behind the Terms & Conditions until accepted once.
    final accepted = (await ref
            .read(blockingSettingsRepositoryProvider)
            .getSettings())
        ?.termsAccepted ==
        true;
    if (!context.mounted) return;
    context.go(accepted ? '/dashboard' : '/terms');
  }
}

class _ActivationSpinner extends StatelessWidget {
  const _ActivationSpinner();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: Color(0xFF1E5FFF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.plan_activating,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivationDone extends StatelessWidget {
  const _ActivationDone();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF00D26A),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            l.plan_activated,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of activating a new plan when a commitment lock is
/// currently active (locked or on a break) — the user must wait for it to
/// end before switching plans.
class _ActivationLocked extends StatelessWidget {
  const _ActivationLocked();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A0E18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1B2435)),
      ),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Color(0xFF1E5FFF), size: 22),
          SizedBox(width: 8),
          Text('Protection is locked', style: TextStyle(color: Colors.white)),
        ],
      ),
      content: const Text(
        "You can't switch plans while your protection commitment is "
        'locked. Wait for the current lock (or break) to end, then try '
        'again.',
        style: TextStyle(color: Color(0xFF9AA5B1)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK', style: TextStyle(color: Color(0xFF1E5FFF))),
        ),
      ],
    );
  }
}
