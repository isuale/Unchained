import 'package:flutter/material.dart';
import 'package:unchained/features/plans/presentation/widgets/owner_unlock_dialog.dart';
import 'package:unchained/l10n/app_localizations.dart';

/// Small, low-contrast entry point shown at the bottom of each plan screen.
/// Only someone who already knows it's there would notice it; tapping it
/// prompts [showOwnerUnlockDialog] and, on success, runs [onUnlocked].
class OwnerEntryButton extends StatelessWidget {
  const OwnerEntryButton({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF33394A),
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        onPressed: () async {
          final unlocked = await showOwnerUnlockDialog(context);
          if (unlocked) onUnlocked();
        },
        child: Text(
          AppLocalizations.of(context)!.owner_entry_label,
          style: const TextStyle(fontSize: 11, letterSpacing: 0.5),
        ),
      ),
    );
  }
}
