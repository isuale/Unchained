import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/stubs/stub_screen.dart';
import 'package:unchained/l10n/app_localizations.dart';

class AccountabilityStub extends StatelessWidget {
  const AccountabilityStub({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: StubScreen(
        icon: Icons.people_outline,
        title: l.stub_accountability_title,
        subtitle: l.common_coming_soon,
      ),
    );
  }
}
