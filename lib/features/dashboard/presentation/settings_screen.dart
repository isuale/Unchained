import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/providers/blocking_settings_provider.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';
import 'package:unchained/features/prayer/domain/prayer_strings.dart';
import 'package:unchained/features/prayer/domain/prayers.dart';
import 'package:unchained/l10n/app_localizations.dart';
import 'package:unchained/shared/app_credits.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _danger = Color(0xFFFF4D4F);
  static const _card = Color(0xFF0A0E18);

  Future<void> _leaveSession(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _card,
        title: Text(
          l.settings_leave_session_dialog_title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          l.settings_leave_session_dialog_body,
          style: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l.common_cancel,
              style: const TextStyle(color: Color(0xFF888888)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l.settings_leave_session_action,
              style: const TextStyle(
                color: _danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final left =
        await ref.read(blockingSettingsActionsProvider.notifier).leaveSession();

    if (!context.mounted) return;
    if (!left) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.commitment_cannot_leave),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _card,
        ),
      );
      return;
    }
    context.go('/welcome');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
          children: [
            Text(
              l.stub_settings_title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 28),
            Text(
              l.settings_section_session.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.logout, color: _danger),
                title: Text(
                  l.settings_leave_session_title,
                  style: const TextStyle(
                    color: _danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  l.settings_leave_session_subtitle,
                  style: const TextStyle(color: Color(0xFF888888)),
                ),
                onTap: () => _leaveSession(context, ref),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              l.settings_section_language.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _LanguageCard(currentLang: ref.watch(appLanguageProvider).asData?.value ?? Lang.es),
            const SizedBox(height: 28),
            Text(
              l.settings_section_about.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined,
                        color: Color(0xFF8AA6FF)),
                    title: Text(
                      l.terms_title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFF666666)),
                    onTap: () => context.push('/terms', extra: false),
                  ),
                  const Divider(height: 1, color: Color(0xFF1A1F2E)),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined,
                        color: Color(0xFF8AA6FF)),
                    title: Text(
                      l.settings_report_bug_title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      AppCredits.supportEmail,
                      style: TextStyle(color: Color(0xFF888888)),
                    ),
                    onTap: AppCredits.contactSupport,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                l.settings_designed_by(AppCredits.ownerName),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of the three supported languages; tapping one sets the app-wide
/// language (see [appLanguageProvider]). Each name is shown in its own
/// language, not translated, per convention (a Spanish speaker still
/// recognizes "English").
class _LanguageCard extends ConsumerWidget {
  const _LanguageCard({required this.currentLang});

  final Lang currentLang;

  static const _card = Color(0xFF0A0E18);
  static const _accent = Color(0xFF1E5FFF);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final l in Lang.values) ...[
            if (l != Lang.values.first)
              const Divider(height: 1, color: Color(0xFF1A1F2E)),
            ListTile(
              leading: Icon(Icons.language,
                  color: l == currentLang ? _accent : const Color(0xFF666666)),
              title: Text(
                PS.langName(l),
                style: const TextStyle(color: Colors.white),
              ),
              trailing: l == currentLang
                  ? const Icon(Icons.check, color: _accent)
                  : null,
              onTap: () => ref.read(prayerRepositoryProvider).setLanguage(l),
            ),
          ],
        ],
      ),
    );
  }
}
