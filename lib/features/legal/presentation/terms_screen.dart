import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
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
    context.go('/dashboard');
  }

  Future<void> _continueAtOwnRisk() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _bg,
        title: const Text(
          'Continue without reading?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Reading the Terms & Conditions is strongly recommended. If you '
          'choose to continue without reading them, you do so entirely at your '
          'own responsibility and accept them in full.',
          style: TextStyle(color: _body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Go back',
              style: TextStyle(color: _muted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'I take responsibility',
              style: TextStyle(
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
          title: const Text('Terms & Conditions'),
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
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: _primary, size: 22),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Please read these Terms & Conditions before '
                                'using the control panel. If you choose not to '
                                'read them, you use this app entirely at your '
                                'own responsibility.',
                                style: TextStyle(
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
                    ..._terms.map(_section),
                    const SizedBox(height: 8),
                    const Text(
                      'By continuing you confirm that you have read, '
                      'understood, and agree to these Terms & Conditions.',
                      style: TextStyle(
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
              if (isGate) _gateActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gateActions() {
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
              child: const Text(
                'I have read and I agree',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _continueAtOwnRisk,
            child: const Text(
              "I don't want to read — continue at my own risk",
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 13),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Owner & developer',
            style: TextStyle(
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
                      '${AppCredits.supportEmail}  (report a bug)',
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

const List<_TermsSection> _terms = [
  _TermsSection(
    '1. Acceptance of these Terms',
    'Unchained ("the app") is a personal tool that helps you block adult and '
        'distracting content. By using the app you agree to these Terms & '
        'Conditions. If you do not agree with any part of them, you should not '
        'use the app.',
  ),
  _TermsSection(
    '2. Purpose and intended use',
    'The app is intended to support healthy digital habits by filtering '
        'content at the network level on your own device. It is a self-help '
        'aid only and is not a substitute for professional, medical, or '
        'psychological advice or treatment.',
  ),
  _TermsSection(
    '3. No guarantee of effectiveness',
    'Content blocking is based on DNS-level domain filtering. No filter is '
        'perfect: some unwanted content may still get through, and some '
        'legitimate content may occasionally be blocked. The app cannot '
        'guarantee that every harmful site or app will be blocked at all times.',
  ),
  _TermsSection(
    '4. Use at your own responsibility',
    'You use the app at your own responsibility and risk. Reading these terms '
        'is your responsibility. If you choose to continue without reading '
        'them, you accept them in full and assume all responsibility for your '
        'use of the app and any outcome that results from it.',
  ),
  _TermsSection(
    '5. Your data and privacy',
    'The app stores your settings and assessment results locally on your '
        'device. It does not sell your personal data. Network requests are '
        'processed on-device to decide what to block; the app does not require '
        'an account to function.',
  ),
  _TermsSection(
    '6. Device permissions',
    'To work, the app may use a local VPN service for DNS filtering and, if you '
        'enable it, accessibility and device-administration features for '
        'uninstall protection. You can review or revoke these permissions in '
        'your device settings at any time, which may reduce protection.',
  ),
  _TermsSection(
    '7. Limitation of liability',
    'To the maximum extent permitted by law, the owner and developer of the '
        'app shall not be liable for any direct, indirect, or incidental '
        'damages arising from the use of, or inability to use, the app, '
        'including any content that is or is not blocked.',
  ),
  _TermsSection(
    '8. Changes to these Terms',
    'These Terms may be updated as the app evolves. Continued use of the app '
        'after an update means you accept the revised Terms.',
  ),
  _TermsSection(
    '9. Contact & support',
    'For questions, bug reports, or support, contact the owner and developer '
        '${AppCredits.ownerName} at ${AppCredits.supportEmail}.',
  ),
];
