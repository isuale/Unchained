---
name: arm-uninstall-protection
description: Re-arm and verify the unchained uninstall-protection watchdog after a build/install. Use whenever prevent-uninstall "stopped working", after any flutter run / flutter install / adb install, or to check that all protection layers (accessibility watchdog, device admin, overlay) are on. Android disables the accessibility watchdog on every reinstall, so it must be re-enabled.
---

# Re-arm uninstall protection

The unchained "prevent uninstall" feature has three layers:

1. **Accessibility watchdog** (`UninstallGuardService`) — covers Force-stop / Uninstall
   screens with the Scripture lock.
2. **Device administrator** — makes Android grey out Uninstall (the hard block).
3. **Overlay** (`SYSTEM_ALERT_WINDOW`) — lets the watchdog draw over Settings.

**The recurring problem:** Android **disables an app's accessibility service on every
reinstall/update** (a security rule). So every `flutter run`, `flutter install`, or
`adb install` silently turns the watchdog OFF — prevent-uninstall "stops working" even
though nothing in the code changed. This is the thing that keeps needing to be fixed.

There is also a [PostToolUse hook](../../settings.json) that runs the same script
automatically after install/build commands, so in normal use this should self-heal.
Invoke this skill to re-arm/verify **on demand** (e.g. after a manual install in a
session whose hook wasn't loaded, or to confirm the state).

## How to run it

Run the project script from the repo root — it re-enables the watchdog (preserving any
other accessibility services) and prints the state of all three layers:

```bash
bash scripts/rearm_uninstall_protection.sh
```

It is idempotent and safe to run anytime. It no-ops cleanly if no device is connected
or the app isn't installed.

## Interpreting the output

- **Accessibility watchdog: was OFF → re-enabled** — this is the normal post-install
  case; it's now fixed.
- **Device admin: NOT active** — the OS-level hard uninstall block is off. It can only
  be (re)activated from inside the app: open the Uninstall-protection card and tap
  **Activate** on "Device administrator". (Device admin normally survives a reinstall,
  so this should be rare.)
- **The in-app "protection ON" toggle** lives in app data and **cannot** be set over
  adb. If the card shows OFF, tell the user to open it and tap **Turn on protection**.

## After running

Tell the user plainly which layers were restored and which (if any) still need a tap
inside the app. Don't claim prevent-uninstall is fully armed unless the watchdog is on
AND device admin is active AND the in-app toggle is on.
