import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/core/router/app_router.dart';
import 'package:unchained/features/guard/lock_visibility.dart';
import 'package:unchained/features/guard/uninstall_guard_service.dart';
import 'package:unchained/features/prayer/data/app_lock_service.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';
import 'package:unchained/features/prayer/domain/prayers.dart';
import 'package:unchained/features/prayer/presentation/prayer_gate_screen.dart';
import 'package:unchained/l10n/app_localizations.dart';
import 'package:unchained/shared/app_credits.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Stripe checkout returns here via the unchained://paid deep link (see
  // AndroidManifest.xml's intent-filter on MainActivity). Both the live
  // stream (app already running/backgrounded) and the initial link (Android
  // killed the app while the browser was open, so this is a cold start) route
  // to the same confirmation screen, which polls the backend for payment
  // confirmation before unlocking anything.
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'unchained' && uri.host == 'paid') {
      appRouter.go('/plans/confirm');
    }
  });
  appLinks.getInitialLink().then((uri) {
    if (uri != null && uri.scheme == 'unchained' && uri.host == 'paid') {
      appRouter.go('/plans/confirm');
    }
  });
  // When the native watchdog catches an uninstall / force-stop attempt it asks us
  // to throw up the scripture lock over whatever route is showing. Flag it active
  // *before* navigating so the owner-credit footer is gone on the lock's very first
  // frame — the user must see only the 800 letters, not the app behind them.
  UninstallGuardService.registerLockHandler(() {
    scriptureLockActive.value = true;
    appRouter.go('/lock');
  });
  // Prayer app-locker: the native watchdog calls this when a locked app is
  // opened, and we raise the prayer gate in enforced mode over it.
  AppLockService.registerPrayerHandler((package) {
    appRouter.push(
      '/pray',
      extra: PrayerGateArgs(
        mode: PrayerGateMode.enforced,
        triggerPackage: package,
      ),
    );
  });

  runApp(const ProviderScope(child: MyApp()));
  // Cold-start path: if the watchdog launched us specifically to show the lock
  // (or the prayer gate), pull that fact once the engine is ready — a pushed
  // showLock/showPrayer can be lost if it fires before the handlers above are
  // registered. The uninstall lock takes priority over a prayer.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    if (await UninstallGuardService.consumePendingLock()) {
      scriptureLockActive.value = true;
      appRouter.go('/lock');
      return;
    }
    final package = await AppLockService.consumePendingPrayer();
    if (package != null) {
      appRouter.push(
        '/pray',
        extra: PrayerGateArgs(
          mode: PrayerGateMode.enforced,
          triggerPackage: package,
        ),
      );
    }
  });
}

/// Maps the app-wide [Lang] setting to the [Locale] the localizations system
/// understands.
Locale _localeFor(Lang lang) => switch (lang) {
      Lang.en => const Locale('en'),
      Lang.es => const Locale('es'),
      Lang.pt => const Locale('pt'),
    };

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Defaults to Spanish (matches PrayerRepository.watchLanguage's default)
    // until the DB row resolves on first read.
    final lang = ref.watch(appLanguageProvider).asData?.value ?? Lang.es;
    final baseInter = GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    final textTheme = baseInter.copyWith(
      displayLarge: GoogleFonts.dmSerifDisplay(
        textStyle: baseInter.displayLarge,
        color: Colors.white,
      ),
      displayMedium: GoogleFonts.dmSerifDisplay(
        textStyle: baseInter.displayMedium,
        color: Colors.white,
      ),
      displaySmall: GoogleFonts.dmSerifDisplay(
        textStyle: baseInter.displaySmall,
        color: Colors.white,
      ),
      headlineLarge: GoogleFonts.dmSerifDisplay(
        textStyle: baseInter.headlineLarge,
        color: Colors.white,
      ),
      headlineMedium: GoogleFonts.dmSerifDisplay(
        textStyle: baseInter.headlineMedium,
        color: Colors.white,
      ),
      headlineSmall: GoogleFonts.dmSerifDisplay(
        textStyle: baseInter.headlineSmall,
        color: Colors.white,
      ),
      titleLarge: GoogleFonts.inter(
        textStyle: baseInter.titleLarge,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.inter(
        textStyle: baseInter.titleMedium,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.inter(
        textStyle: baseInter.titleSmall,
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(
        textStyle: baseInter.bodyLarge,
        color: Colors.white,
        fontWeight: FontWeight.normal,
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: baseInter.bodyMedium,
        color: Colors.white,
        fontWeight: FontWeight.normal,
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: baseInter.bodySmall,
        color: Colors.white,
        fontWeight: FontWeight.normal,
      ),
      labelLarge: GoogleFonts.inter(
        textStyle: baseInter.labelLarge,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: GoogleFonts.inter(
        textStyle: baseInter.labelMedium,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: GoogleFonts.inter(
        textStyle: baseInter.labelSmall,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );

    return MaterialApp.router(
      title: 'Be Unchained',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _localeFor(lang),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000),
        primaryColor: const Color(0xFF1E5FFF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1E5FFF),
          surface: Color(0xFF0A0F1C),
        ),
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0F1C),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E5FFF),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      routerConfig: appRouter,
      // Pin the owner credit + support contact to the bottom of every screen —
      // except while the Scripture lock is up, where the user must see only the
      // 800 letters. The route subtree (child) always stays inside Expanded so no
      // screen is reparented or loses state when the footer collapses.
      builder: (context, child) {
        return Column(
          children: [
            Expanded(child: child ?? const SizedBox.shrink()),
            ValueListenableBuilder<bool>(
              valueListenable: scriptureLockActive,
              builder: (context, locked, _) =>
                  locked ? const SizedBox.shrink() : const AppFooter(),
            ),
          ],
        );
      },
    );
  }
}
