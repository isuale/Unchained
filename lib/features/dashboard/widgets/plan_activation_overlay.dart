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
  /// The plan switch itself is never blocked. But while a commitment lock is
  /// currently active (locked or on a break), the new schedule is *not*
  /// stored — the running lock is left untouched so it keeps enforcing
  /// (protection stays un-toggleable) in the background under whichever
  /// plan you switch to, instead of being wiped by the switch.
  ///
  /// The one exception is [CommitmentMode.forever], which always applies. That
  /// guard exists to stop a switch *weakening* a running lock; Forever can only
  /// strengthen it (protection locked permanently, no breaks, no end date), so
  /// refusing it was simply wrong — it left the header saying "Forever" while
  /// the banner counted down the old plan's remaining days, and let that old
  /// span expire into freedom the Forever user never asked for.
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
    final status = computeStatus(
      mode,
      days,
      breaks,
      settings?.commitmentStartedAt,
      now,
      breaksUsed: settings?.commitmentBreaksUsed ?? 0,
      breakClaimedAt: settings?.commitmentBreakClaimedAt,
    );
    // A repeating cycle that has just finished a span is not over — it restarts —
    // so it must survive a plan switch exactly like a mid-span commitment does.
    final stillCommitted =
        status.isActive || (status.isCompleted && mode == CommitmentMode.cycle);
    // Captured before setActivePlan overwrites it, so we can tell a genuine
    // plan CHANGE (was some other plan) apart from a first-time activation
    // (was null) or simply re-confirming the same plan (unchanged).
    final previousPlan = settings?.activePlan;

    await ref.read(activePlanActionsProvider.notifier).setActivePlan(plan);

    // Forever outranks whatever is running: it is strictly more commitment, so
    // the "don't let a switch weaken a live lock" guard must not block it.
    final toForever = schedule?.mode == CommitmentMode.forever;
    if (!stillCommitted || toForever) {
      await repo.setCommitmentSchedule(schedule ?? CommitmentSchedule.none);
      if (stillCommitted && toForever) {
        // setCommitmentSchedule deliberately clears the run anchor, and with a
        // null anchor computeStatus reports *no* commitment at all. Re-anchor in
        // the same breath, or switching to Forever would briefly hand the user
        // a freely-toggleable protection switch — the exact escape the guard
        // above exists to prevent. The original anchor is kept rather than
        // `now` so "committed since" stays truthful.
        await repo.startCommitmentRun(settings?.commitmentStartedAt ?? now);
      }
    }
    // Switching to a different plan than the one already active requires
    // re-accepting the Terms & Conditions before the control panel is
    // reachable again — the same gate a first-time activation already goes
    // through below, since termsAccepted starts false on a fresh install.
    if (previousPlan != null && previousPlan != plan.name) {
      await repo.setTermsAccepted(false);
    }

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
    // After paying, land on the dashboard's default tab 0 — now the Protección
    // (blocking) tab, not the prayer home. If terms aren't accepted yet, the
    // terms gate handles the same landing once the user agrees.
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
