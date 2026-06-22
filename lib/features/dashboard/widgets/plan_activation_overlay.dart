import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/l10n/app_localizations.dart';

class PlanActivationOverlay {
  PlanActivationOverlay._();

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required ActivePlan plan,
  }) async {
    // Only the free trial can be installed/activated for now. Every paid plan
    // is gated off here so the activation flow never runs for them.
    if (plan != ActivePlan.freeTrial) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.plan_unavailable)),
      );
      return;
    }

    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (_) => const _ActivationSpinner(),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    await ref.read(activePlanActionsProvider.notifier).setActivePlan(plan);

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
    context.go('/dashboard');
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
