import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unchained/features/blocking/blocking_provider.dart';
import 'package:unchained/l10n/app_localizations.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _accent = Color(0xFF1E5FFF);
  static const _onColor = Color(0xFF4ADE80);
  static const _offColor = Colors.white54;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final isActive = ref.watch(blockingProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.app_title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.white12 : _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  onPressed: () =>
                      ref.read(blockingProvider.notifier).toggle(),
                  child: Text(
                    isActive ? l.protection_stop : l.protection_activate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isActive ? l.protection_status_on : l.protection_status_off,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  color: isActive ? _onColor : _offColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
