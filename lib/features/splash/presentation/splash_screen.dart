import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/dashboard/data/blocking_settings_repository.dart';
import 'package:unchained/features/guard/lock_visibility.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final repo = ref.read(blockingSettingsRepositoryProvider);
    final settingsFuture = repo.getSettings();
    final minDelay = Future<void>.delayed(const Duration(seconds: 2));
    final settings = await settingsFuture;
    await minDelay;

    if (!mounted) return;
    // If the watchdog cold-launched us for the lock, never navigate over it.
    if (scriptureLockActive.value) return;
    if (settings?.activePlan != null) {
      // Returning user: gate the control panel behind the Terms & Conditions
      // until they have accepted them once.
      context.go(settings?.termsAccepted == true ? '/dashboard' : '/terms');
    } else {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}
