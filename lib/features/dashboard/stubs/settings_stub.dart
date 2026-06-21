import 'package:flutter/material.dart';
import 'package:unchained/features/dashboard/stubs/stub_screen.dart';
import 'package:unchained/l10n/app_localizations.dart';

class SettingsStub extends StatelessWidget {
  const SettingsStub({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return StubScreen(
      icon: Icons.settings_outlined,
      title: l.stub_settings_title,
      subtitle: l.common_coming_soon,
    );
  }
}
