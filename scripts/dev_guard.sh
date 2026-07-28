#!/usr/bin/env bash
#
# Developer-only control of unchained's uninstall protection, over adb.
#
# WHY THIS EXISTS
#   While the app holds active *device admin*, this test device refuses in-place APK
#   replacement as well as uninstall: `flutter install` / `adb install -r` report
#   "Success" and then silently keep running the OLD build (lastUpdateTime never moves).
#   Without this hatch the only way to push a new build was a human completing the
#   800-letter scripture challenge inside the app — which is how the phone ended up
#   stuck several commits behind.
#
#   This talks to DevGuardReceiver (android/.../DevGuardReceiver.kt), an exported
#   receiver gated by (a) android.permission.DUMP — which only the adb shell uid and
#   privileged apps hold, never a third-party app — and (b) the shared token below.
#   Nothing in the Flutter UI can reach it, so the app's own user can't tap their way
#   to it; it needs a computer with authorised USB debugging.
#
# USAGE
#   bash scripts/dev_guard.sh status    Show every protection layer's current state.
#   bash scripts/dev_guard.sh unlock    Drop the guard so an APK can install.
#   bash scripts/dev_guard.sh relock    Re-arm everything that can be re-armed w/o a tap.
#   bash scripts/dev_guard.sh install   unlock -> install -> verify it took -> re-arm.
#
#   `install` uses `adb install -r` on purpose. `flutter install` uninstalls the old
#   copy first, and once the guard is down that uninstall SUCCEEDS — wiping the DB
#   (onboarding history, active plan, terms acceptance, commitment-lock anchor) on
#   every dev install. `-r` replaces the APK in place and keeps app data.
#
set -uo pipefail

APP_PKG="com.beunchained.app"
ACTION="com.unchained.unchained.DEV_GUARD"
RECEIVER="${APP_PKG}/com.unchained.unchained.DevGuardReceiver"
ADMIN="${APP_PKG}/com.unchained.unchained.UnchainedDeviceAdminReceiver"
# Must match DevGuardReceiver.TOKEN.
TOKEN="unchained-dev-7f3a91c4e5b28d60"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- locate adb (PATH first, then the known SDK locations) ------------------
find_adb() {
  if command -v adb >/dev/null 2>&1; then command -v adb; return 0; fi
  for p in \
    "/run/media/isuale/e5806df2-8353-4cdb-8ad8-44e0b7524785/dev/android-sdk/platform-tools/adb" \
    "$HOME/Android/Sdk/platform-tools/adb" \
    "$HOME/android-sdk/platform-tools/adb"; do
    [ -x "$p" ] && { echo "$p"; return 0; }
  done
  return 1
}

ADB="$(find_adb)" || { echo "adb not found"; exit 1; }

STATE="$("$ADB" get-state 2>/dev/null)"
if [ "$STATE" != "device" ]; then
  echo "No device connected (adb state: ${STATE:-none})."
  exit 1
fi

if ! "$ADB" shell pm list packages 2>/dev/null | grep -q "package:${APP_PKG}$"; then
  echo "$APP_PKG is not installed on the device."
  exit 1
fi

# --- send one command to the receiver and print what it answered ------------
# `am broadcast` echoes the receiver's result data, which is how DevGuardReceiver
# reports the resulting state back to us.
send() {
  local cmd="$1"
  local out
  out="$("$ADB" shell am broadcast \
    -a "$ACTION" \
    -n "$RECEIVER" \
    --es token "$TOKEN" \
    --es cmd "$cmd" 2>&1 | tr -d '\r')"

  local data
  data="$(printf '%s' "$out" | sed -n 's/.*data="\(.*\)"$/\1/p')"

  if [ -z "$data" ]; then
    echo "  ! No reply from the app."
    # The most common cause by far: the installed build predates DevGuardReceiver.
    printf '%s\n' "$out" | sed 's/^/    /'
    echo "    (If the installed build is older than this hatch, the receiver isn't in it"
    echo "     yet — disable protection once inside the app, install, and it's free after.)"
    return 1
  fi
  echo "  $data"
  case "$data" in REJECTED*|UNKNOWN*) return 1 ;; esac
  return 0
}

# --- ground truth straight from the OS, not from the app --------------------
report_os_state() {
  local admin="NOT active"
  "$ADB" shell dumpsys device_policy 2>/dev/null \
    | grep -q "UnchainedDeviceAdminReceiver" && admin="ACTIVE (blocks uninstall AND APK replacement)"
  local acc
  acc="$("$ADB" shell settings get secure enabled_accessibility_services 2>/dev/null | tr -d '\r')"
  local watchdog="OFF"
  case ":$acc:" in *"UninstallGuardService"*) watchdog="ON" ;; esac
  echo "  OS view -> device admin: $admin | accessibility watchdog: $watchdog"
}

# Re-grant device admin without a human tap.
#
# `unlock` gives the role back by calling the app's own removeActiveAdmin() — the adb
# counterpart `dpm remove-active-admin` is refused for a non-test admin. Granting is the
# other way round: the app can only ask via a system consent dialog, but the adb shell
# holds MANAGE_DEVICE_ADMINS and `dpm set-active-admin` just works. Using each side's
# working half keeps the whole dev cycle hands-free.
rearm_admin() {
  if "$ADB" shell dumpsys device_policy 2>/dev/null | grep -q "UnchainedDeviceAdminReceiver"; then
    return 0
  fi
  local out
  out="$("$ADB" shell dpm set-active-admin "$ADMIN" 2>&1 | tr -d '\r')"
  case "$out" in
    Success*) echo "  Device admin re-granted over adb." ;;
    *) echo "  ! Could not re-grant device admin over adb: $out"
       echo "    Activate it by hand: app > Uninstall protection > Activate." ;;
  esac
}

installed_stamp() {
  "$ADB" shell dumpsys package "$APP_PKG" 2>/dev/null \
    | grep -m1 lastUpdateTime | tr -d '\r' | sed 's/^ *//'
}

CMD="${1:-status}"

case "$CMD" in
  status)
    echo "Protection status:"
    send status
    report_os_state
    echo "  Installed build: $(installed_stamp)"
    ;;

  unlock)
    echo "Unlocking protection (developer hatch)…"
    send unlock || exit 1
    report_os_state
    echo
    echo "Protection is DOWN. Install now, then run: bash scripts/dev_guard.sh relock"
    echo
    echo "Install with:  adb install -r build/app/outputs/flutter-apk/app-release.apk"
    echo "Do NOT use \`flutter install\` while unlocked — it uninstalls the old copy"
    echo "first, and with the guard down that succeeds and WIPES the app's data."
    echo "(\`bash scripts/dev_guard.sh install\` does the safe thing for you.)"
    ;;

  relock)
    echo "Re-arming protection…"
    # Admin first, so the receiver's own reply below reports the finished state.
    rearm_admin
    send relock
    # The watchdog is an accessibility service, which Android switches off on every
    # reinstall — the existing script re-enables it and reports all three layers.
    bash "$REPO_ROOT/scripts/rearm_uninstall_protection.sh"
    report_os_state
    ;;

  install)
    APK="$REPO_ROOT/build/app/outputs/flutter-apk/app-release.apk"
    if [ ! -f "$APK" ]; then
      echo "No release APK at $APK — run: flutter build apk --release"
      exit 1
    fi
    BEFORE="$(installed_stamp)"
    echo "Installed before: $BEFORE"
    echo
    echo "1/3 Unlocking…"
    send unlock || exit 1
    echo
    echo "2/3 Installing…"
    # NOT `flutter install`: that command uninstalls the old copy first, and with the
    # guard down that uninstall now SUCCEEDS — wiping the DB (onboarding history,
    # active plan, terms acceptance, commitment-lock anchor) on every dev install.
    # `adb install -r` replaces the APK in place and keeps app data.
    INSTALL_OUT="$("$ADB" install -r -d "$APK" 2>&1)"
    printf '%s\n' "$INSTALL_OUT"
    if ! printf '%s' "$INSTALL_OUT" | grep -q "Success"; then
      # Since release signing was wired up (android/key.properties), release builds
      # carry the upload key while anything installed before that was debug-signed.
      # Android never replaces an app across a signing-key change, so this is the one
      # install failure that a retry can never fix — say what actually has to happen.
      if printf '%s' "$INSTALL_OUT" | grep -qE "INSTALL_FAILED_UPDATE_INCOMPATIBLE|signatures do not match"; then
        echo
        echo "  ! The installed app is signed with a DIFFERENT key than this build."
        echo "    Android refuses to replace an app across a signing-key change, so"
        echo "    retrying cannot help. You must uninstall first, which DELETES the"
        echo "    app's data (onboarding history, plan, terms, commitment anchor):"
        echo "      adb uninstall $APP_PKG"
        echo "    Protection is already down, so that uninstall will succeed."
      fi
      echo "adb install failed — leaving protection down so you can retry."
      exit 1
    fi
    AFTER="$(installed_stamp)"
    echo
    echo "Installed after:  $AFTER"
    if [ "$BEFORE" = "$AFTER" ]; then
      # The exact silent-no-op failure this hatch exists to prevent: adb says
      # "Success" while PackageManager quietly kept the old APK. Never report a
      # stale install as done.
      echo "  ! lastUpdateTime did NOT advance — the install was a silent no-op."
      echo "    Protection left DOWN. Check the unlock output above before retrying."
      exit 1
    fi
    echo "  ✓ Install took effect."
    echo
    echo "3/3 Re-arming…"
    rearm_admin
    send relock
    bash "$REPO_ROOT/scripts/rearm_uninstall_protection.sh"
    report_os_state
    ;;

  *)
    echo "Usage: bash scripts/dev_guard.sh [status|unlock|relock|install]"
    exit 2
    ;;
esac
