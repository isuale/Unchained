import 'package:flutter/material.dart';
import 'package:unchained/features/dashboard/stubs/stub_screen.dart';
import 'package:unchained/l10n/app_localizations.dart';

class BlocklistStub extends StatelessWidget {
  const BlocklistStub({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StubScreen(
      icon: Icons.block_flipped,
      title: l.stub_blocklist_title,
      subtitle: l.common_coming_soon,
    );
  }
}
