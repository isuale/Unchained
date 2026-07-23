import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
import 'package:unchained/features/dashboard/domain/commitment.dart';
import 'package:unchained/features/dashboard/providers/active_plan_provider.dart';
import 'package:unchained/features/dashboard/widgets/plan_activation_overlay.dart';
import 'package:unchained/features/plans/domain/pending_activation.dart';
import 'package:unchained/features/plans/domain/stripe_checkout.dart';
import 'package:unchained/features/plans/presentation/widgets/email_checkout_dialog.dart';

/// What happens when the user taps a paid plan's CTA.
///
/// Once a plan's real Stripe Payment Link is configured, this gates
/// activation behind actual payment: it asks for an email, remembers what
/// the user is trying to buy ([PendingActivation]), sends them to Stripe, and
/// stops there — the plan is only unlocked later, when the app returns via
/// the unchained://paid deep link and the backend confirms the payment (see
/// PaymentConfirmationScreen).
///
/// A plan still on the beunchained.app stand-in (no real link yet) has no
/// real checkout to confirm against, so it keeps the old demo behavior of
/// activating immediately after opening the browser.
class PlanCheckoutFlow {
  PlanCheckoutFlow._();

  static Future<void> start({
    required BuildContext context,
    required WidgetRef ref,
    required String planId,
    required ActivePlan plan,
    required CommitmentSchedule schedule,
  }) async {
    if (!StripeCheckout.hasRealLink(planId)) {
      await StripeCheckout.open(planId);
      if (!context.mounted) return;
      await PlanActivationOverlay.show(
        context: context,
        ref: ref,
        plan: plan,
        schedule: schedule,
      );
      return;
    }

    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (!context.mounted) return;
    final email = await showEmailCheckoutDialog(
      context,
      initialEmail: settings?.customerEmail,
    );
    if (email == null) return; // user cancelled

    final pending = PendingActivation(
      planId: planId,
      plan: plan,
      schedule: schedule,
      email: email,
    );
    await repo.setCustomerEmail(email);
    await repo.setPendingActivation(pending.toJson());
    await StripeCheckout.open(planId, email: email);
  }
}
