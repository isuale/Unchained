import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
import 'package:unchained/l10n/app_localizations.dart';
import 'package:unchained/shared/app_credits.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Terms & Conditions gate shown once before the user reaches the control panel.
///
/// In gate mode ([isGate] true, the default) it offers two ways forward — agree
/// after reading, or continue without reading at the user's own responsibility —
/// and both record acceptance so the gate is not shown again. The gate is
/// deliberately "sticky": it cannot be dismissed by the system back gesture, and
/// it holds a wakelock so the screen never sleeps out from under the reader. It
/// ends only when the user chooses one of the two buttons.
///
/// In view mode ([isGate] false, opened from Settings) it just displays the
/// terms with a back button and no acceptance buttons.
class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key, this.isGate = true});

  final bool isGate;

  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  static const Color _bg = Color(0xFF0A0E18);
  static const Color _primary = Color(0xFF1E5FFF);
  static const Color _heading = Colors.white;
  static const Color _body = Color(0xFFB6BDCC);
  static const Color _muted = Color(0xFF7A8294);

  @override
  void initState() {
    super.initState();
    // Keep the screen on while the mandatory gate is up so the OS display
    // timeout can't blank the Terms out before the user has decided.
    if (widget.isGate) {
      WakelockPlus.enable();
    }
  }

  @override
  void dispose() {
    if (widget.isGate) {
      WakelockPlus.disable();
    }
    super.dispose();
  }

  Future<void> _accept() async {
    await ref.read(blockingSettingsRepositoryProvider).setTermsAccepted(true);
    if (!mounted) return;
    // Land on the dashboard; tab 0 is now the Protección (blocking) tab.
    context.go('/dashboard');
  }

  Future<void> _continueAtOwnRisk() async {
    final l = AppLocalizations.of(context)!;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _bg,
        title: Text(
          l.terms_dialog_title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l.terms_dialog_body,
          style: const TextStyle(color: _body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l.terms_dialog_go_back,
              style: const TextStyle(color: _muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l.terms_dialog_take_responsibility,
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (proceed != true) return;
    if (!mounted) return;
    await _accept();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isGate = widget.isGate;
    // In gate mode the screen is back-proof: the system back gesture/button
    // does nothing, so the user can only leave by choosing a button.
    return PopScope(
      canPop: !isGate,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: !isGate,
          title: Text(l.terms_title),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    if (isGate) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: _primary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l.terms_gate_banner,
                                style: const TextStyle(
                                  color: _body,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    ..._termsFor(l).map(_section),
                    const SizedBox(height: 8),
                    Text(
                      l.terms_footer_note,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _OwnerCredit(),
                  ],
                ),
              ),
              if (isGate) _gateActions(l),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gateActions(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1A1F2E))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _accept,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                l.terms_agree_button,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _continueAtOwnRisk,
            child: Text(
              l.terms_continue_risk_button,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(_TermsSection s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.title,
            style: const TextStyle(
              color: _heading,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.body,
            style: const TextStyle(
              color: _body,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerCredit extends StatelessWidget {
  const _OwnerCredit();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.terms_owner_credit_label,
            style: const TextStyle(
              color: Color(0xFF7A8294),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            AppCredits.ownerName,
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: AppCredits.contactSupport,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline,
                      color: Color(0xFF8AA6FF), size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l.terms_owner_contact(AppCredits.supportEmail),
                      style: const TextStyle(
                        color: Color(0xFF8AA6FF),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection {
  const _TermsSection(this.title, this.body);
  final String title;
  final String body;
}

List<_TermsSection> _termsFor(AppLocalizations l) => [
      _TermsSection(l.terms_section1_title, l.terms_section1_body),
      _TermsSection(l.terms_section2_title, l.terms_section2_body),
      _TermsSection(l.terms_section3_title, l.terms_section3_body),
      _TermsSection(l.terms_section4_title, l.terms_section4_body),
      _TermsSection(l.terms_section5_title, l.terms_section5_body),
      _TermsSection(l.terms_section6_title, l.terms_section6_body),
      _TermsSection(l.terms_section7_title, l.terms_section7_body),
      _TermsSection(l.terms_section8_title, l.terms_section8_body),
      _TermsSection(l.terms_section9_title, l.terms_section9_body),
      _TermsSection(l.terms_section10_title, l.terms_section10_body),
      _TermsSection(
        l.terms_section11_title,
        l.terms_section11_body(AppCredits.ownerName, AppCredits.supportEmail),
      ),
    ];
