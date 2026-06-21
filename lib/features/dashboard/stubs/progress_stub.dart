import 'package:flutter/material.dart';
import 'package:unchained/features/dashboard/stubs/stub_screen.dart';
import 'package:unchained/l10n/app_localizations.dart';

class ProgressStub extends StatelessWidget {
  const ProgressStub({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StubScreen(
      icon: Icons.timeline,
      title: l.stub_progress_title,
      subtitle: l.common_coming_soon,
    );
  }
}
