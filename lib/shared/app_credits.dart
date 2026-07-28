import 'package:flutter/material.dart';
import 'package:unchained/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

/// Single source of truth for the app's authorship credit and support contact.
/// Shown app-wide by [AppFooter] (pinned to the bottom of every screen via the
/// global builder in main.dart) and on the Terms & Conditions screen.
class AppCredits {
  AppCredits._();

  static const String ownerName = 'Alessandro Lozada Alvarez';
  static const String supportEmail = 'imblueale@gmail.com';
  static const String bugReportSubject = 'Be Unchained — Bug report';

  /// Opens the user's mail app with a pre-filled message to the support address.
  /// Silently no-ops if no mail client is available, so it is safe to call from
  /// anywhere without a Scaffold/SnackBar context.
  static Future<void> contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=${Uri.encodeComponent(bugReportSubject)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// A subtle one-line signature bar pinned to the bottom of every screen. Credits
/// the owner and exposes the support email as a tappable bug-report link. Hides
/// itself while the soft keyboard is open so it never steals room from text
/// fields or overflows.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const Color _muted = Color(0xFF5A6172);
  static const Color _link = Color(0xFF8AA6FF);

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    if (keyboardOpen) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;

    return Material(
      color: Colors.black,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 5),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              const Text(
                '© ${AppCredits.ownerName}  ·  ',
                style: TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  height: 1.2,
                ),
              ),
              GestureDetector(
                onTap: AppCredits.contactSupport,
                child: const Text(
                  AppCredits.supportEmail,
                  style: TextStyle(
                    color: _link,
                    fontSize: 10.5,
                    height: 1.2,
                    decoration: TextDecoration.underline,
                    decorationColor: _link,
                  ),
                ),
              ),
              Text(
                '  ·  ${l.footer_inspired_by}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
