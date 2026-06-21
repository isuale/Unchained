# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`unchained` is a Flutter (Dart SDK ^3.11.5) Android app for blocking adult/distracting content. The user is onboarded through a questionnaire that scores their "addiction level" and recommends a subscription plan, then a dashboard controls a native Android VPN that performs DNS-based domain blocking.

> Note: the parent directory of this project is a tools/SDK root (Android SDK, Flutter SDK, JDK). Run all commands below from this `unchained/` directory.

> **Scope:** The user also keeps an unrelated `minecraft*` directory under `/home/isuale/dev`. It is **not** part of this project — never read, edit, search, or reference anything under a `minecraft*` path. When searching near `/home/isuale/dev`, exclude it (e.g. `rg --glob '!**/minecraft*/**'`). Stay inside the `unchained` app tree.

> **Always commit:** After finishing any working feature or change, make a git commit so the user can always roll back if a function breaks. Commit only at a stable point (run codegen / `flutter analyze` first), stage specific paths, write a clear present-tense message, and commit to the current branch. Do **not** push unless asked. **Always proactively tell the user — without being asked — that a commit was made, stating the short hash as their rollback point** (and whether it was pushed; default is not pushed). See the `auto-commit` skill for the full procedure.

> **Always summarize:** End every response that involved doing work with a short, plain-language summary of what was done (what changed, why, and what to check next). The user is learning, so keep it clear and tie it to the actual files.

## Commands

```bash
flutter pub get                              # install deps
flutter run                                  # run on connected device/emulator (locale forced to 'en')
flutter analyze                              # lint (flutter_lints) — the only static-analysis gate
flutter test                                 # run all tests
flutter test test/widget_test.dart           # run a single test file
flutter test --plain-name "smoke test"       # run a single test by name

# Codegen — REQUIRED after editing any Drift table or @freezed class.
# Generated files (*.g.dart, *.freezed.dart) are committed; regenerate, don't hand-edit.
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs   # continuous during dev

flutter gen-l10n                             # regenerate localizations from lib/l10n/*.arb
flutter pub run flutter_launcher_icons       # regenerate Android launcher icons from assets/images/logo.png

flutter build apk                            # release build (applicationId: com.unchained.app)
```

`test/widget_test.dart` is the stale default Flutter counter test and does **not** match this app (no counter widget) — it will fail if run. Replace it before relying on `flutter test`.

## Architecture

State management is **Riverpod 3** (`Notifier`/`NotifierProvider`, `StreamProvider`, `FutureProvider`). Navigation is **go_router** with a flat route table in `lib/core/router/app_router.dart` (initial route `/splash`). Persistence is **Drift** (SQLite). Models use **freezed**. There is no backend — everything is local.

### Layout convention
Code is organized by feature under `lib/features/<feature>/`, each split into `presentation/` (screens + widgets), `application/` (Riverpod notifiers/state), `domain/` (models, pure logic, static data), and `data/` (repositories). Cross-cutting code lives in `lib/core/` (database, router, i18n). `lib/shared/` is for shared widgets.

### The blocking pipeline (the core feature)
This crosses the Dart/native boundary via a single `MethodChannel('unchained/blocking')`:

- `lib/features/blocking/blocking_service.dart` — thin Dart wrapper exposing `prepare()` / `start()` / `stop()` / `isRunning()`. All calls are wrapped in try/catch and return `bool`; a failed channel call returns `false` rather than throwing.
- `android/.../MainActivity.kt` — handles the channel. `prepareVpn` triggers Android's `VpnService.prepare()` consent dialog (async, resolved in `onActivityResult`); start/stop dispatch intents to the foreground service.
- `android/.../BlockingService.kt` — a `VpnService` that establishes a tun interface (`10.0.0.1` DNS), reads packets in a loop, parses **IPv4/UDP/port-53 DNS queries only**, and returns a forged **NXDOMAIN** for domains in the hardcoded `BLOCKLIST`, forwarding everything else to upstream `1.1.1.1`. The actual blocklist lives here in Kotlin, not in Dart. IPv6 and non-DNS traffic pass through untouched.

The toggle is driven by `features/dashboard/providers/blocking_settings_provider.dart` (`blockingSettingsActionsProvider`), which both flips the native VPN and persists the `protectionEnabled` DB flag.

This notifier **reconciles state from native on build** (`isRunning()`), because the VPN can be revoked or killed by the OS independent of the app. When changing toggle logic, preserve this reconcile-from-truth pattern.

### Persistence (Drift)
`lib/core/database/app_database.dart` defines two tables and `schemaVersion = 2` (bump it and add an `onUpgrade` branch for any schema change):
- `UserAssessments` — append-only history of onboarding results.
- `BlockingSettings` — a **singleton row pinned to `id = 1`**. `_ensureSettingsRow()` runs in `onCreate`, `onUpgrade`, and `beforeOpen` to guarantee the row exists. Repositories always query `id == 1`.

`appDatabaseProvider` (in `core/database/user_assessment_repository.dart`) is the single DB instance. Access goes through repository providers (`blockingSettingsRepositoryProvider`, `userAssessmentRepositoryProvider`) — UI watches `blockingSettingsProvider` (a `StreamProvider` over `watchSettings()`) for live updates. Boolean settings are toggled by **string field name** via `BlockingSettingsRepository.toggleField(field, value)`, which switch-maps the name to a `Companion`; adding a new boolean column means adding both the column and a case here.

### Onboarding → plan scoring
`lib/features/onboarding/domain/data/onboarding_questions_data.dart` holds the static questions (each answer carries `points`). `domain/plan_recommendation.dart` sums points, maps to a `percentage` and `AddictionLevel`, and picks a `planId` (`free_trial` / `monthly` / `ai_plan` / `forever`) by threshold. Results are saved to `UserAssessments`. The plan-screen routes under `/plans/*` correspond to these IDs.

### Localization
ARB files in `lib/l10n/`; the **template is Spanish** (`app_es.arb`, see `l10n.yaml`) with an English translation (`app_en.arb`). The app currently forces `locale: Locale('en')` in `main.dart`. Onboarding strings are resolved dynamically by string key through `core/i18n/localized_text.dart` (`AppLocalizations.byKey('...')`) — when you add an onboarding question/answer string, you must register its getter in the `_byKey` map there or `byKey` throws at runtime.

### Theming
Global dark theme is defined inline in `main.dart` using `google_fonts` (DM Serif Display for headlines, Inter for body). Background is pure black (`0xFF000000`), primary blue `0xFF1E5FFF`. There is no separate theme file.
