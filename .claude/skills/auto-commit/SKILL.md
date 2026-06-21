---
name: auto-commit
description: Make a git commit every time a feature is added or a meaningful change is finished in the unchained app, so the user can always roll back if a function breaks. Use after completing any working change — new feature, bug fix, refactor, or config edit.
---

# Auto-commit after every working change

Git is the safety net for this project: if a function breaks, the user wants to be
able to go back to the last working version. So **commit early and often** — every
time a feature or change is complete and the app still works, snapshot it.

## When to commit

Commit after you finish a coherent unit of work, such as:
- a new feature or screen,
- a bug fix,
- a refactor,
- a config / dependency / asset change.

Commit when the change is at a **working, stable point** — not in the middle of a
broken edit. If you ran codegen, `flutter analyze`, or tests, do that first so you're
committing a green state.

## How to commit

1. Review what changed: `git status` and `git diff` (staged + unstaged).
2. Stage the relevant files (`git add <paths>` — prefer specific paths over `git add -A`
   so you don't sweep in unrelated junk).
3. Commit with a clear, present-tense message that says **what** and **why**:
   - Good: `Add NXDOMAIN logging to BlockingService for debugging`
   - Avoid: `update`, `fix stuff`, `changes`.
4. End every commit message with this trailer (required in this environment):

   ```
   Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
   ```

5. Commit to the **current branch** (this is a solo learning repo on `main` — that's
   fine; do not open PRs or branch unless the user asks).
6. **Do NOT push** unless the user explicitly asks. Committing locally is enough to
   protect their work; pushing is a separate, outward-facing action.

## After committing

**Always** tell the user — proactively, without waiting to be asked — in one line what was
committed and the short commit hash, so they know the rollback point exists, e.g.:
`Committed "Add onboarding skip button" (a1b2c3d) — you can roll back to here anytime.`
Also state whether it was pushed (default: committed locally only, not pushed).

## Teaching note

The user is learning. When you commit, briefly remind them *why* it matters
("this saves a restore point") and, if useful, how to undo:
`git checkout <hash> -- <file>` to restore one file, or `git revert <hash>` to undo a commit.
