import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/providers/blocking_settings_provider.dart';
import 'package:unchained/l10n/app_localizations.dart';

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

    await ref.read(blockingSettingsActionsProvider.notifier).leaveSession();

    if (!context.mounted) return;
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
            Container(
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(14),
              ),
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
          ],
        ),
      ),
    );
  }
}
