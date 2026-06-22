---
name: task-recap
description: After completing ANY task in the unchained app, end the response with a two-part recap — (1) a plain-language Summary of what was done, and (2) a separate Teaching mode that explains HOW it was done and defines every technical term used. Use whenever a coherent unit of work is finished (feature, bug fix, refactor, config/asset change, build/install). This is the always-on end-of-task format for a user who is learning.
---

# Task recap: Summary + Teaching mode

When you finish a task for this user, do **not** just stop after the work. Close every
response that involved real work with **two clearly separated sections**, in this order.
The user is learning to program, so the recap is part of the deliverable, not an extra.

---

## Part 1 — ✅ Summary (what I did)

A short, plain-language summary aimed at "what changed and is it working":

- **What changed** — the actual files/behavior, in human terms.
- **Why** — the reason this was the right move for *this* app.
- **Status** — does it build/run? Was it installed/committed? State it plainly
  (include the commit short hash as a rollback point when one was made).
- **What to check next** — one or two concrete things the user can look at or try.

Keep it tight. Tie each point to real files using `file_path:line` so it's clickable.
This part is the same "Always summarize" behavior the project already expects.

---

## Part 2 — 🎓 Teaching mode (how I did it + what the terms mean)

A **separate, clearly-labeled** section (start it with the `🎓 Teaching mode` heading)
that teaches the user how the work was actually done. This is where you slow down and
explain. Cover:

1. **The approach, step by step** — narrate the path you took ("first I read X to find
   where blocking happens, then I added a column, then I pushed it to native"). Show the
   *reasoning*, not just the result — why this order, what you ruled out.
2. **Define every term** — for any technical word you used in either section
   (e.g. *provider*, *widget*, *schema migration*, *method channel*, *SharedPreferences*,
   *codegen*, *NXDOMAIN*, *companion object*), give a 1–2 sentence definition the first
   time it appears, and tie it to where it lives in THIS codebase.
3. **The "why" behind the decisions** — explain trade-offs you made in plain language
   ("I stored the list in the database instead of a file because the UI can watch the
   database and update live").
4. **What to explore to go deeper** — optionally point the user at the file or concept
   they could read next to understand more.

### How to teach well

- **Use analogies** for hard ideas, then connect the analogy back to the real code.
- **Define before (or right as) you use.** Never leave a piece of jargon unexplained.
- **Layer the depth.** Give the simple version first; offer "want the deeper why?"
  instead of dumping everything.
- **Ground it in this app.** "In *this* app, `blockingSettingsProvider` is the live
  feed the dashboard watches" beats a generic definition.
- **Invite questions.** End by checking understanding ("does that part make sense, or
  want me to go slower on any piece?").
- **Language:** the user's first language appears to be Spanish. Keep English but stay
  simple; if they switch to Spanish, you may explain in Spanish.

### Ready glossary for this project (lean on these)

- **Flutter / Dart** — the framework / language the app is written in.
- **Widget** — a piece of UI; screens in `lib/features/*/presentation/` are built from them.
- **Riverpod / Provider / Notifier** — state management. A *provider* holds a value the
  UI can watch; a *Notifier* changes it. e.g. `blockingSettingsProvider`.
- **StreamProvider** — a provider that exposes a live stream, so the UI updates the
  moment the underlying data (e.g. the database row) changes.
- **go_router** — screen navigation; routes in `lib/core/router/app_router.dart`.
- **Drift** — the local SQLite database layer; tables in `lib/core/database/app_database.dart`.
- **Schema migration** — the code that upgrades an existing database when you add/change
  columns, so a user's old data survives an update (`onUpgrade` in `app_database.dart`).
- **freezed** — codegen for immutable data models (`*.freezed.dart`).
- **Codegen / build_runner** — regenerates `*.g.dart` / `*.freezed.dart` after editing a
  table or model.
- **MethodChannel** — the bridge between Dart and native Android (Kotlin), e.g.
  `MethodChannel('unchained/blocking')`.
- **VpnService / tun interface** — Android plumbing in `BlockingService.kt` that inspects
  DNS packets.
- **NXDOMAIN** — a DNS reply meaning "this domain doesn't exist"; the app forges it to block sites.
- **SharedPreferences** — Android's tiny key→value store for small bits of data that must
  survive an app/service restart.
- **Companion object** — in Kotlin, a block of functions/values that belong to the class
  itself (like Dart's `static`).

## Relationship to the other skills

- `teaching-programmer` teaches **inline, while** the work happens (optional, on request).
- **This skill is the always-on END-of-task recap** — it runs every time a task finishes,
  even when inline teaching wasn't used.
- Pair naturally with `auto-commit`: when a commit was made, name the hash in Part 1.

## What NOT to do

- Don't merge the two parts — keep Summary and Teaching mode visibly separate.
- Don't skip Teaching mode because the change was small; small changes are where the
  vocabulary is learned.
- Don't invent how the project works — if unsure, read the file first, then teach it.
- Don't lecture endlessly — tight and tied to what you actually just did.
