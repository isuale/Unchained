import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unchained/features/prayer/data/prayer_repository.dart';
import 'package:unchained/features/prayer/domain/prayer_strings.dart';
import 'package:unchained/features/prayer/domain/prayers.dart';
import 'package:unchained/l10n/app_localizations.dart';

/// First screen a brand-new user sees ("Get Started").
///
/// It carries the language picker because this is the earliest point the choice
/// can be made: the app defaults to Spanish (see [appLanguageProvider]), so an
/// English or Portuguese speaker would otherwise have to complete the whole
/// onboarding questionnaire in a language they may not read before reaching the
/// picker buried in Settings.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/welcome_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.20),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 180,
                    height: 180,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Be Unchained',
                    style:
                        Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.welcome_tagline,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 2,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 2),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go('/onboarding'),
                      child: Text(
                        AppLocalizations.of(context)!.welcome_get_started,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          // Last in the Stack so it paints — and receives taps — above the
          // centred content column, which spans the full screen.
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: _LanguagePicker(
                  current: ref.watch(appLanguageProvider).asData?.value ?? Lang.es,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact language control for the welcome screen: a translucent pill showing
/// the current language, tapping it opens the three choices.
///
/// Each language is written in its own name (English / Español / Português)
/// rather than translated — the same convention the Settings language card uses,
/// since someone who can't read the current language still recognises their own.
class _LanguagePicker extends ConsumerWidget {
  const _LanguagePicker({required this.current});

  final Lang current;

  static const _accent = Color(0xFF1E5FFF);
  static const _menu = Color(0xFF0A0E18);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<Lang>(
      tooltip: AppLocalizations.of(context)!.welcome_language,
      color: _menu,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (lang) => ref.read(prayerRepositoryProvider).setLanguage(lang),
      itemBuilder: (context) => [
        for (final lang in Lang.values)
          PopupMenuItem<Lang>(
            value: lang,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    PS.langName(lang),
                    style: TextStyle(
                      color: lang == current ? _accent : Colors.white,
                      fontWeight:
                          lang == current ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (lang == current)
                  const Icon(Icons.check, color: _accent, size: 18),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          // Readable over whatever part of the photo sits behind it.
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              PS.langName(current),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 20),
          ],
        ),
      ),
    );
  }
}
