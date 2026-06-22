import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unchained/core/router/app_router.dart';
import 'package:unchained/features/guard/uninstall_guard_service.dart';
import 'package:unchained/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // When the native watchdog catches an uninstall / force-stop attempt it asks us
  // to throw up the scripture lock over whatever route is showing.
  UninstallGuardService.registerLockHandler(() => appRouter.go('/lock'));
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
      title: 'Flutter Demo',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
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
    );
  }
}
