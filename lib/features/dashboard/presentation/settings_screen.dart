import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/providers/blocking_settings_provider.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';
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

  /// Turns the prayer app-locker on or off. Switching it *off* is confirmed
  /// first: the prayer content is Christian and a user of another faith is
  /// entitled to opt out, but it still unlocks every app they had gated and
  /// removes a tab, which shouldn't happen from one stray tap.
  Future<void> _setPrayerLock(
      BuildContext context, WidgetRef ref, bool enabled) async {
    if (!enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: _card,
          title: const Text(
            'Turn off the prayer lock?',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'The prayer lock uses Christian prayers, so you can switch it off '
            'if it is not part of your faith.\n\n'
            'Any apps you locked behind prayer will open normally again, and '
            'the Oración tab will be hidden. Your other blocking stays on. '
            'You can turn it back on here at any time.',
            style: TextStyle(color: Color(0xFFAAAAAA)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Keep it on',
                style: TextStyle(color: Color(0xFF888888)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Turn off',
                style: TextStyle(
                  color: _danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    await ref
        .read(blockingSettingsActionsProvider.notifier)
        .toggle('prayerLockEnabled', enabled);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final prayerLockEnabled =
        ref.watch(prayerLockEnabledProvider).asData?.value ?? true;
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
            const Text(
              'FAITH',
              style: TextStyle(
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
              child: SwitchListTile(
                value: prayerLockEnabled,
                activeThumbColor: const Color(0xFF1E5FFF),
                secondary: const Icon(Icons.volunteer_activism_outlined,
                    color: Color(0xFF8AA6FF)),
                title: const Text(
                  'Prayer app lock',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Locks the apps you choose behind a Christian prayer. '
                  'Switch it off if it is not part of your faith — the rest '
                  'of your blocking is unaffected.',
                  style: TextStyle(color: Color(0xFF888888)),
                ),
                onChanged: (v) => _setPrayerLock(context, ref, v),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'ABOUT',
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
                    title: const Text(
                      'Terms & Conditions',
                      style: TextStyle(color: Colors.white),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFF666666)),
                    onTap: () => context.push('/terms', extra: false),
                  ),
                  const Divider(height: 1, color: Color(0xFF1A1F2E)),
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined,
                        color: Color(0xFF8AA6FF)),
                    title: const Text(
                      'Report a bug',
                      style: TextStyle(color: Colors.white),
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
            const Center(
              child: Text(
                'Designed & developed by\n${AppCredits.ownerName}',
                textAlign: TextAlign.center,
                style: TextStyle(
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
