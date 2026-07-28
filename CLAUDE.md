# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`unchained` is a Flutter (Dart SDK ^3.11.5) Android app for blocking adult/distracting content. The user is onboarded through a questionnaire that scores their "addiction level" and recommends a subscription plan, then a dashboard controls a native Android VPN that performs DNS-based domain blocking.

> Note: the parent directory of this project is a tools/SDK root (Android SDK, Flutter SDK, JDK). Run all commands below from this `unchained/` directory.

> **Scope:** The user also keeps an unrelated `minecraft*` directory under `/home/isuale/dev`. It is **not** part of this project — never read, edit, search, or reference anything under a `minecraft*` path. When searching near `/home/isuale/dev`, exclude it (e.g. `rg --glob '!**/minecraft*/**'`). Stay inside the `unchained` app tree.

> **Always commit AND push:** After finishing any working feature or change, make a git commit so the user can always roll back if a function breaks, **then push it to `origin` immediately** — local commits alone are not a backup. Commit only at a stable point (run codegen / `flutter analyze` first), stage specific paths, write a clear present-tense message, commit to the current branch, then `git push`. (On 2026-07-23 local `main` was found 50 commits / 12 days ahead of `origin/main` because pushes were being skipped by default — do not let that recur.) **Always proactively tell the user — without being asked — that a commit was made and pushed, stating the short hash as their rollback point.** See the `auto-commit` skill for the full procedure.

> **Always build & install:** After finishing any working feature or change (and after committing it), build the app and install it on the connected device (`flutter install -d <device-id>`, or `flutter devices` first if the id isn't already known) so the user is always running the latest code. **`flutter install` can silently reinstall a stale cached APK without recompiling** — after installing, always verify the fix is actually present: compare `sha256sum` of the local `build/app/outputs/flutter-apk/app-release.apk` against the APK pulled back from the device (`adb shell pm path <pkg>` then `adb pull`), and confirm the local APK's mtime is newer than the source edit. Never report an install as done without this check. Because reinstalling can disable the accessibility watchdog, immediately follow with the `arm-uninstall-protection` skill to re-arm and verify all three uninstall-protection layers, and report their state. Skip this only if no device is connected (say so) or the change has no runtime surface to install (e.g. docs-only).
>
> **On "reinstall fresh" / "clear old data" requests:** A true `adb uninstall` is blocked by the app's own device-admin uninstall-protection (`DELETE_FAILED_DEVICE_POLICY_MANAGER`) — this is the feature working as intended, and neither `adb` nor `dpm remove-active-admin` can bypass it (Android refuses at the OS level for a non-test admin); only a human tapping through the phone's Settings UI or the app's own toggle can deactivate it. Don't try to work around this. If the user wants a clean state without stale leftover data, offer `adb shell pm clear com.beunchained.app` (wipes the DB/settings/commitment-lock/onboarding history, equivalent to a fresh install) as the practical alternative — but confirm with them first since it destroys real app data (onboarding history, active plan, terms acceptance, commitment-lock anchor).

> **Always recap (summary + teaching mode):** End every response that involved doing work with a **two-part recap**: (1) a short, plain-language **Summary** of what was done (what changed, why, status/commit hash, what to check next), and (2) a separate **🎓 Teaching mode** section that explains *how* it was done step by step and **defines every technical term used**, tied to the actual files. The user is learning, so the teaching breakdown is part of the deliverable — never skip it, even for small changes. See the `task-recap` skill for the full format and project glossary.

> **Always improve on the user's idea:** The user is a non-engineer describing features in plain, sometimes rough terms — the literal request is a starting point, not the ceiling. Before implementing, actively look for the gap between what they described and what would actually make the feature good: inconsistent behavior it would create (e.g. a mode change that silently doesn't do what its label implies), a related toggle/screen left half-wired, a missing confirmation before a surprising behavior change, a rough edge a real user would hit immediately. When you find one, fix it as part of the same change and say what you improved and why in the recap — don't just note it as a suggestion for later. This does **not** override the "don't build things beyond what's needed" instinct for unrelated speculative work — it's specifically about closing gaps *within* the feature just requested. If an improvement is genuinely a bigger, separate decision (new cost, new permission, a real tradeoff), surface it and ask instead of silently expanding scope.

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

flutter build apk                            # release build (applicationId: com.beunchained.app)
flutter build appbundle                      # .aab for the Play Store (signed with the upload key)
```

`test/widget_test.dart` is the stale default Flutter counter test and does **not** match this app (no counter widget) — it will fail if run. Replace it before relying on `flutter test`.

## Release signing

Release builds are signed with a real **upload key**, not the debug key (wired up 2026-07-28 for the Play Store). `android/app/build.gradle.kts` reads `android/key.properties` for the credentials; both that file and the keystore are gitignored, and the keystore itself lives **outside the repo** at `~/keystores/unchained-upload-keystore.p12` (alias `upload`, PKCS12). If `key.properties` is missing — a fresh clone, CI — the build falls back to debug signing so it still compiles; such a build runs on a device but Play rejects it.

**Losing the keystore means never being able to update the app on Play again.** It is not reproducible and not in git. Confirm it is backed up somewhere off this machine before relying on it.

**Gotcha:** Android refuses to replace an installed app with one signed by a different key. Any device still carrying an older debug-signed build must be **uninstalled** (destroying its app data) before a release-signed build will install — no `-r` flag gets around it. `scripts/dev_guard.sh install` detects this specific failure and says so rather than suggesting a pointless retry.

Verify what a built artifact is actually signed with — never assume:
```bash
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk   # APK (v2/v3 signing)
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab   # AAB (JAR signing)
```
Debug-signed output says `CN=Android Debug`; correctly signed output says `CN=Be Unchained`.

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

Beyond the hardcoded `BLOCKLIST`, `BlockingService.kt` also layers in: a `DOH_BOOTSTRAP` set (DNS-over-HTTPS bootstrap hosts like `use-application-dns.net`, `cloudflare-dns.com`, `dns.google` — blocked unconditionally, checked *before* the allowlist, so a browser can't sidestep the DNS block via DoH) and a per-user custom allow/blocklist persisted in native SharedPreferences (`KEY_USER_BLOCKLIST` / `KEY_USER_ALLOWLIST`, checked via `USER_BLOCKLIST`/`USER_ALLOWLIST`). The allowlist wins over every block rule.

### Uninstall protection ("guard")
A second Dart↔native bridge, `MethodChannel('unchained/guard')`, layered independently of the blocking channel:

- `lib/features/guard/uninstall_guard_service.dart` — Dart wrapper, same try/catch-returns-safe-default shape as `BlockingService`.
- `android/.../UninstallGuardService.kt` — an `AccessibilityService` watchdog. It cannot hook the system Settings/installer UI directly, so it watches the foreground window for four "escape doors" (our app's Settings **App-info** page, the package-installer uninstall dialog, our Play Store listing, and the Accessibility-settings page for this very service) and slams the lock screen over them when detected. Detection matches on the app's visible label + danger-control text in the node tree (language-independent), not fixed button captions.
- `android/.../GuardAdmin.kt` — wraps `DevicePolicyManager` for two layered strengths: **device admin** (blocks uninstall until the admin is deactivated, one consent dialog) and, opportunistically, **device owner** (`setUninstallBlocked` — uninstall becomes flatly impossible, no deactivate door; requires `dpm set-device-owner` on an account-free device).
- `android/.../GuardState.kt` — SharedPreferences-backed `enabled` flag (the watchdog's on/off gate) plus an in-memory grace window (`GRACE_MS` = 60s) that stands the watchdog down right after a passed challenge so the user can actually navigate away.
- `lib/features/guard/presentation/scripture_lock_screen.dart` (route `/lock`) — the fixed **800-letter** scripture-copying challenge the user must complete to get through. `lib/features/guard/lock_visibility.dart` exposes `scriptureLockActive`, a `ValueNotifier<bool>` read in `main.dart`'s `MaterialApp.router` builder to hide the app footer while the lock is up.
- Cold-start handling in `main.dart`: `UninstallGuardService.registerLockHandler` reacts to a live push from native; `consumePendingLock()` is polled once after first frame to catch the case where the watchdog cold-launched the app specifically to show the lock (a live push fired before the handler was registered would otherwise strand the user on the normal app).
- No plugin is involved anywhere in this feature — device admin, the accessibility watchdog, and the challenge are all hand-rolled native Kotlin + Dart, not backed by a package.

#### Developer escape hatch (`scripts/dev_guard.sh`)
`android/.../DevGuardReceiver.kt` is a **developer-only** back door for lowering uninstall protection over adb, so a new build can be pushed to the test phone without a human completing the 800-letter scripture challenge. It exists because protection is deliberately human-only to turn off, which previously left the device stranded on stale commits.

It is **not reachable from any Flutter screen** — there is no widget, route, or MethodChannel method for it. It is an exported `BroadcastReceiver` gated by two independent things: `android:permission="android.permission.DUMP"` in the manifest (a `signature|privileged` permission that only the adb shell uid and privileged apps hold — no third-party app can send the broadcast) and a secret `token` extra checked in `onReceive`. Reaching it requires a computer with authorised USB debugging.

```bash
bash scripts/dev_guard.sh status     # every layer's state, app-side and OS-side
bash scripts/dev_guard.sh unlock     # guard off + device admin released
bash scripts/dev_guard.sh relock     # re-arm every layer
bash scripts/dev_guard.sh install    # unlock → install → verify it took → re-arm
```

Two behaviours worth keeping if this code is touched:
- **`install` uses `adb install -r`, never `flutter install`.** `flutter install` uninstalls the old copy first; with the guard *up* that uninstall fails harmlessly and it falls back to in-place replacement, but with the guard *down* it succeeds and **wipes the DB** (onboarding history, active plan, terms acceptance, commitment-lock anchor).
- **Admin removal and admin granting use opposite mechanisms.** `dpm remove-active-admin` is refused for a non-test admin, so `unlock` gives the role back through the app's own `removeActiveAdmin()`; the app can only *request* admin via a system consent dialog, so `relock` re-grants it with `dpm set-active-admin` from the adb shell (which holds `MANAGE_DEVICE_ADMINS`). Each side uses its working half, which is what makes the cycle hands-free.

Verify a real install by `lastUpdateTime` advancing while `firstInstallTime` stays put (`adb shell dumpsys package com.beunchained.app`) — that pair proves both "the install took effect" and "app data survived".

### Commitment lock
`lib/features/dashboard/domain/commitment.dart` is a pure, testable module (no Dart/native boundary) describing how long protection is locked on. The plan picked at onboarding sets a `CommitmentSchedule` (`CommitmentMode.none/forever/fixed/cycle`, `totalDays`, `breakCount`); the lock only starts running (an `startedAt` anchor is recorded) the first time the user turns protection on. `computeStatus()` derives the live `CommitmentStatus` (locked / on a break / completed) from the anchor and current time; `advanceCycle()` rolls a `cycle` schedule's anchor forward if the device was off long enough to miss whole spans. Consumed by `blocking_settings_provider.dart` and the plan/dashboard screens to decide whether the protection toggle is locked.

`CommitmentStatus.testMode` (currently `false`) is a dev-only switch that reinterprets "days" as minutes for fast manual testing of the lock → break → re-lock cycle — check it's `false` before any release-facing work.

### Terms & Conditions gate
`lib/features/legal/presentation/terms_screen.dart` (route `/terms`) is not a router redirect — `splash_screen.dart` decides on every cold start: a returning user (`settings.activePlan != null`) goes to `/dashboard` if `settings.termsAccepted`, else `/terms`. In gate mode (`isGate: true`, the default) the screen is undismissable (no system-back exit) and holds a `wakelock_plus` lock so the screen can't sleep out from under the reader; it ends only via "Agree" or "Continue at own risk". Opened from Settings instead, `isGate: false` makes it a plain read-only view.

### Password-gated plan switching
`lib/features/plans/presentation/widgets/plan_password_dialog.dart` holds a hardcoded password (`_planChangePassword`) so a tester can't weaken protection by switching off the plan the onboarding questionnaire recommended. `all_plans_screen.dart` skips the dialog when the tapped plan **is** the recommended one, and requires it for any other plan.

### Persistence (Drift)
`lib/core/database/app_database.dart` defines two tables and `schemaVersion = 6` (bump it and add an `onUpgrade` branch for any schema change — this has grown steadily as commitment-lock, terms-acceptance, and custom-list columns were added, so check the current value before assuming it's still low):
- `UserAssessments` — append-only history of onboarding results.
- `BlockingSettings` — a **singleton row pinned to `id = 1`**. `_ensureSettingsRow()` runs in `onCreate`, `onUpgrade`, and `beforeOpen` to guarantee the row exists. Repositories always query `id == 1`. Besides the feature toggles, it stores the commitment fields (`commitmentMode`/`commitmentTotalDays`/`commitmentBreakCount`/`commitmentCycle`), `activePlan`, `termsAccepted`, and the custom `customBlocklist`/`customAllowlist` text columns.

`appDatabaseProvider` (in `core/database/user_assessment_repository.dart`) is the single DB instance. Access goes through repository providers (`blockingSettingsRepositoryProvider`, `userAssessmentRepositoryProvider`) — UI watches `blockingSettingsProvider` (a `StreamProvider` over `watchSettings()`) for live updates. Boolean settings are toggled by **string field name** via `BlockingSettingsRepository.toggleField(field, value)`, which switch-maps the name to a `Companion`; adding a new boolean column means adding both the column and a case here.

### Onboarding → plan scoring
`lib/features/onboarding/domain/data/onboarding_questions_data.dart` holds the static questions (each answer carries `points`). `domain/plan_recommendation.dart` sums points, maps to a `percentage` and `AddictionLevel`, and picks a `planId` (`free_trial` / `monthly` / `ai_plan` / `forever`) by threshold. Results are saved to `UserAssessments`. The plan-screen routes under `/plans/*` correspond to these IDs.

### Localization
ARB files in `lib/l10n/`; the **template is Spanish** (`app_es.arb`, see `l10n.yaml`) with an English translation (`app_en.arb`). The app currently forces `locale: Locale('en')` in `main.dart`. Onboarding strings are resolved dynamically by string key through `core/i18n/localized_text.dart` (`AppLocalizations.byKey('...')`) — when you add an onboarding question/answer string, you must register its getter in the `_byKey` map there or `byKey` throws at runtime.

### Theming
Global dark theme is defined inline in `main.dart` using `google_fonts` (DM Serif Display for headlines, Inter for body). Background is pure black (`0xFF000000`), primary blue `0xFF1E5FFF`. There is no separate theme file.
