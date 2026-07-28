#!/usr/bin/env bash
#
# Re-arm the unchained uninstall-protection watchdog.
#
# Android DISABLES an app's accessibility service every time the app is
# reinstalled/updated (a security rule). The uninstall-protection "watchdog"
# (UninstallGuardService) is an accessibility service, so every `flutter run`,
# `flutter install`, or `adb install` silently turns prevent-uninstall OFF.
#
# This script re-enables it via adb (which holds WRITE_SECURE_SETTINGS) and
# reports the state of the other two layers (device admin + overlay). It is
# idempotent and safe to run anytime.
#
# Modes:
#   (no args)   Verbose: always re-arm and print a full status report.
#   --hook      Quiet: meant to be called from a Claude Code PostToolUse hook.
#               Reads the tool-call JSON on stdin and only acts when the command
#               was an app install/build-install. Emits a JSON systemMessage so
#               the user sees that protection was restored. Never fails the hook.
#
set -uo pipefail

APP_PKG="com.beunchained.app"
# Derived from APP_PKG so a change to the app's identity can't leave this behind:
# the left half is the installed package (applicationId), the right half is the
# Kotlin class (namespace), and those two are deliberately different.
SVC="${APP_PKG}/com.unchained.unchained.UninstallGuardService"

# --- locate adb (PATH first, then the known SDK location) -------------------
find_adb() {
  if command -v adb >/dev/null 2>&1; then
    command -v adb
    return 0
  fi
  for p in \
    "/run/media/isuale/e5806df2-8353-4cdb-8ad8-44e0b7524785/dev/android-sdk/platform-tools/adb" \
    "$HOME/Android/Sdk/platform-tools/adb" \
    "$HOME/android-sdk/platform-tools/adb"; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  return 1
}

MODE="${1:-verbose}"

# In --hook mode, bail out fast unless the triggering command was an install.
if [ "$MODE" = "--hook" ]; then
  STDIN_JSON="$(cat 2>/dev/null || true)"
  # Match the ways this project pushes a new APK onto the device. Grepping the
  # raw JSON is robust and avoids a hard jq dependency; a stray match only causes
  # a harmless idempotent re-arm.
  if ! printf '%s' "$STDIN_JSON" | grep -Eq \
      'flutter[[:space:]]+(run|install)|adb[[:space:]]+install|flutter[[:space:]]+build[[:space:]]+apk|assembleRelease|assembleDebug|installRelease|installDebug'; then
    exit 0
  fi
fi

ADB="$(find_adb)" || { [ "$MODE" = "--hook" ] && exit 0 || { echo "adb not found"; exit 0; }; }

# No device connected → nothing to do.
STATE="$("$ADB" get-state 2>/dev/null)"
if [ "$STATE" != "device" ]; then
  [ "$MODE" = "--hook" ] && exit 0
  echo "No device connected (adb state: ${STATE:-none}); nothing to re-arm."
  exit 0
fi

# App not installed → this device/chat isn't about unchained.
if ! "$ADB" shell pm list packages 2>/dev/null | grep -q "package:${APP_PKG}$"; then
  [ "$MODE" = "--hook" ] && exit 0
  echo "$APP_PKG is not installed on the device; nothing to re-arm."
  exit 0
fi

# --- re-enable the accessibility watchdog (merge-safe) ----------------------
CURRENT="$("$ADB" shell settings get secure enabled_accessibility_services 2>/dev/null | tr -d '\r')"
WAS_ON=0
case ":$CURRENT:" in
  *":$SVC:"*) WAS_ON=1; NEW="$CURRENT" ;;
  *)
    if [ -z "$CURRENT" ] || [ "$CURRENT" = "null" ]; then
      NEW="$SVC"
    else
      # Preserve any other accessibility services the user has enabled.
      NEW="$CURRENT:$SVC"
    fi
    ;;
esac

"$ADB" shell settings put secure enabled_accessibility_services "$NEW" >/dev/null 2>&1
"$ADB" shell settings put secure accessibility_enabled 1 >/dev/null 2>&1

# --- gather the state of the other two layers for the report ----------------
ADMIN_ON=0
if "$ADB" shell dumpsys device_policy 2>/dev/null | grep -q "UnchainedDeviceAdminReceiver"; then
  ADMIN_ON=1
fi
OVERLAY="$("$ADB" shell appops get "$APP_PKG" SYSTEM_ALERT_WINDOW 2>/dev/null | tr -d '\r')"

admin_txt="active"; [ "$ADMIN_ON" -eq 1 ] || admin_txt="NOT active (re-activate in the app for the hard uninstall block)"

if [ "$MODE" = "--hook" ]; then
  if [ "$WAS_ON" -eq 1 ]; then
    # Watchdog survived this install — say nothing, keep the transcript quiet.
    exit 0
  fi
  printf '{"systemMessage":"🔒 Uninstall protection: the app install switched the accessibility watchdog OFF (Android does this on every reinstall) — re-enabled it via adb. Device admin: %s"}\n' "$admin_txt"
  exit 0
fi

# --- verbose report ---------------------------------------------------------
echo "Uninstall protection re-armed:"
if [ "$WAS_ON" -eq 1 ]; then
  echo "  • Accessibility watchdog : was already ON"
else
  echo "  • Accessibility watchdog : was OFF → re-enabled"
fi
echo "  • Device admin (hard block): $admin_txt"
echo "  • Overlay (SYSTEM_ALERT_WINDOW): ${OVERLAY:-unknown}"
echo
echo "Note: the in-app 'protection ON' toggle is stored in app data and can only be"
echo "set from inside the app. If the card shows OFF, open it and tap 'Turn on protection'."
