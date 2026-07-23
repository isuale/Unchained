import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
import 'package:unchained/features/dashboard/widgets/plan_activation_overlay.dart';
import 'package:unchained/features/plans/domain/entitlement_service.dart';
import 'package:unchained/features/plans/domain/pending_activation.dart';

const _accent = Color(0xFF1E5FFF);

/// Shown after returning from Stripe checkout (via the unchained://paid deep
/// link). Polls the backend for confirmation that the pending plan was
/// actually paid for, then hands off to [PlanActivationOverlay] to unlock it —
/// the plan is never unlocked just because the user tapped "Subscribe".
class PaymentConfirmationScreen extends ConsumerStatefulWidget {
  const PaymentConfirmationScreen({super.key});

  @override
  ConsumerState<PaymentConfirmationScreen> createState() =>
      _PaymentConfirmationScreenState();
}

enum _Stage { loading, confirming, notConfirmed, nothingPending }

class _PaymentConfirmationScreenState
    extends ConsumerState<PaymentConfirmationScreen> {
  _Stage _stage = _Stage.loading;
  PendingActivation? _pending;
  late final TextEditingController _emailController = TextEditingController();
  bool _busy = false;

  static const int _maxAttempts = 12; // ~30s at 2.5s apart
  static const _pollDelay = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    final pending = PendingActivation.fromJson(settings?.pendingActivationJson);
    if (!mounted) return;
    if (pending == null) {
      setState(() => _stage = _Stage.nothingPending);
      return;
    }
    _pending = pending;
    _emailController.text = pending.email;
    setState(() => _stage = _Stage.confirming);
    await _poll(pending.email);
  }

  Future<void> _poll(String email) async {
    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final entitlement = await EntitlementService.check(email);
      if (!mounted) return;
      if (entitlement.active) {
        await _activate();
        return;
      }
      await Future.delayed(_pollDelay);
      if (!mounted) return;
    }
    if (!mounted) return;
    setState(() => _stage = _Stage.notConfirmed);
  }

  Future<void> _activate() async {
    final pending = _pending;
    if (pending == null || !mounted) return;
    final repo = ref.read(blockingSettingsRepositoryProvider);
    await repo.setCustomerEmail(pending.email);
    await repo.clearPendingActivation();
    if (!mounted) return;
    await PlanActivationOverlay.show(
      context: context,
      ref: ref,
      plan: pending.plan,
      schedule: pending.schedule,
    );
  }

  Future<void> _retryWithEditedEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || _pending == null) return;
    setState(() => _busy = true);
    final repo = ref.read(blockingSettingsRepositoryProvider);
    await repo.setCustomerEmail(email);
    final updated = PendingActivation(
      planId: _pending!.planId,
      plan: _pending!.plan,
      schedule: _pending!.schedule,
      email: email,
    );
    await repo.setPendingActivation(updated.toJson());
    _pending = updated;
    if (!mounted) return;
    setState(() {
      _busy = false;
      _stage = _Stage.confirming;
    });
    await _poll(email);
  }

  Future<void> _cancel() async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    await repo.clearPendingActivation();
    if (!mounted) return;
    context.go('/plans/all');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_stage) {
              _Stage.loading => const CircularProgressIndicator(color: _accent),
              _Stage.confirming => _ConfirmingView(planId: _pending?.planId),
              _Stage.nothingPending => _NothingPendingView(
                  onDone: () => context.go('/plans/all'),
                ),
              _Stage.notConfirmed => _NotConfirmedView(
                  controller: _emailController,
                  busy: _busy,
                  onRetry: _retryWithEditedEmail,
                  onCancel: _cancel,
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _ConfirmingView extends StatelessWidget {
  const _ConfirmingView({this.planId});
  final String? planId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(strokeWidth: 4, color: _accent),
        ),
        const SizedBox(height: 24),
        const Text(
          'Confirming your payment…',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "This can take a few seconds while Stripe lets us know.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF9AA3B2), height: 1.4),
        ),
      ],
    );
  }
}

class _NotConfirmedView extends StatelessWidget {
  const _NotConfirmedView({
    required this.controller,
    required this.busy,
    required this.onRetry,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.hourglass_bottom, color: Color(0xFF9AA3B2), size: 48),
        const SizedBox(height: 18),
        const Text(
          "We couldn't confirm your payment yet",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'If you completed checkout, make sure this matches the email you '
          'used on the Stripe payment page, then try again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF9AA3B2), height: 1.4),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: controller,
          enabled: !busy,
          autocorrect: false,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'you@example.com',
            hintStyle: const TextStyle(color: Color(0xFF666666)),
            filled: true,
            fillColor: const Color(0xFF0A0E18),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1C2233)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: busy ? null : onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
          child: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Check again',
                  style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy ? null : onCancel,
          child: const Text('Cancel',
              style: TextStyle(color: Color(0xFF9AA3B2))),
        ),
      ],
    );
  }
}

class _NothingPendingView extends StatelessWidget {
  const _NothingPendingView({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onDone());
    return const SizedBox.shrink();
  }
}
