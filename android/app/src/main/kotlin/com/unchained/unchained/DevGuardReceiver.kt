package com.unchained.unchained

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * **Developer-only** back door for turning uninstall protection off from a computer.
 *
 * ### Why this exists
 * While the app holds active **device admin**, this device refuses not just uninstall
 * but also *in-place APK replacement*: `flutter install` / `adb install -r` print
 * `Success` and then silently keep running the old build (`lastUpdateTime` never
 * advances). The only documented way out was a human tapping through the 800-letter
 * scripture challenge inside the app — which makes shipping a new build to the test
 * phone a manual chore, and left the phone stuck on a stale commit.
 *
 * This receiver gives the *person building the app* an adb-only escape hatch that
 * lowers the guard long enough to install, then puts it back. It is deliberately
 * **not** reachable from any Flutter screen, so the app's own user can never find or
 * tap their way to it.
 *
 * ### Why a user can't abuse it
 * Three independent gates, all of which must be satisfied at once:
 *  1. **`android.permission.DUMP` on the sender** (declared in the manifest). That is a
 *     `signature|privileged` permission: no third-party app on the phone can hold it.
 *     `adb shell` (uid `shell`, i.e. `com.android.shell`) does — so effectively only a
 *     USB-connected computer with USB debugging already authorised can send it.
 *  2. **A shared secret** ([TOKEN]) that must be passed as the `token` extra. Knowing
 *     the action name alone is useless.
 *  3. **A non-obvious action name** that appears nowhere in the UI or in any string the
 *     app ever shows.
 *
 * A determined user who decompiles the APK could read [TOKEN] — but they would still
 * need a computer and an authorised adb connection, at which point they could simply
 * factory-reset the phone anyway. The threat model here is "user wants to weaken their
 * own protection in a weak moment", not "nation-state with my laptop".
 *
 * ### Usage (from the repo root)
 *
 *     bash scripts/dev_guard.sh status     # what's armed right now
 *     bash scripts/dev_guard.sh unlock     # drop the guard so an APK can install
 *     bash scripts/dev_guard.sh relock     # put back what can be put back
 *     bash scripts/dev_guard.sh install    # unlock -> flutter install -> re-arm
 *
 * @see GuardAdmin for the device-admin / device-owner layers this toggles.
 * @see GuardState for the accessibility watchdog's on/off gate.
 */
class DevGuardReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "UnchainedDevGuard"

        /** Intent action the adb broadcast must use. Mirrored in scripts/dev_guard.sh. */
        const val ACTION = "com.unchained.unchained.DEV_GUARD"

        /**
         * Shared secret required in the `token` extra.
         *
         * Not a password in the cryptographic sense — it exists so that merely knowing
         * or guessing [ACTION] isn't enough to fire this. Changing it means changing
         * `scripts/dev_guard.sh` to match.
         */
        private const val TOKEN = "unchained-dev-7f3a91c4e5b28d60"

        private const val EXTRA_TOKEN = "token"
        private const val EXTRA_CMD = "cmd"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != ACTION) return

        if (intent.getStringExtra(EXTRA_TOKEN) != TOKEN) {
            Log.w(TAG, "rejected: bad or missing token")
            reply(context, "REJECTED bad token")
            return
        }

        when (val cmd = intent.getStringExtra(EXTRA_CMD)?.lowercase()) {
            "unlock" -> unlock(context)
            "relock" -> relock(context)
            "status", null -> reply(context, status(context))
            else -> {
                Log.w(TAG, "unknown cmd=$cmd")
                reply(context, "UNKNOWN cmd=$cmd (use status|unlock|relock)")
            }
        }
    }

    /**
     * Stand every layer down: the watchdog stops gating escape doors, the device-owner
     * uninstall block is lifted, and we hand back the device-admin role — which is the
     * one that actually blocks APK replacement.
     */
    private fun unlock(context: Context) {
        GuardState.setEnabled(context, false)
        GuardState.grantGrace()
        GuardAdmin.removeAdmin(context)
        Log.i(TAG, "unlocked: guard off, device admin released")
        // Deliberately NOT reporting isAdminActive() here: removeActiveAdmin() is
        // asynchronous, so querying it on this same line still answers `true` and the
        // reply would claim the block is up when it is on its way down. The caller
        // (scripts/dev_guard.sh) prints the OS's own view straight after, which is the
        // ground truth worth trusting.
        reply(
            context,
            "UNLOCKED guardEnabled=" + GuardState.isEnabled(context) +
                " deviceAdmin=release-requested (async — see the OS view below)",
        )
    }

    /**
     * Put back what can be put back without a human.
     *
     * The watchdog gate and (if we're device owner) the hard uninstall block are ours to
     * set. Re-granting **device admin** is not: Android only ever activates an admin
     * through its own consent screen, so that layer needs one tap inside the app. The
     * reply says so explicitly rather than silently reporting a half-armed state as OK.
     */
    private fun relock(context: Context) {
        GuardState.setEnabled(context, true)
        val ownerBlock = GuardAdmin.lockUninstall(context, true)
        val adminActive = GuardAdmin.isAdminActive(context)
        Log.i(TAG, "relocked: ownerBlock=$ownerBlock adminActive=$adminActive")
        val note = if (adminActive) {
            ""
        } else {
            " NEEDS_TAP=device-admin (open the app > Uninstall protection > Activate)"
        }
        reply(context, "RELOCKED " + status(context) + note)
    }

    private fun status(context: Context): String = buildString {
        append("guardEnabled=").append(GuardState.isEnabled(context))
        append(" deviceAdmin=").append(GuardAdmin.isAdminActive(context))
        append(" deviceOwner=").append(GuardAdmin.isDeviceOwner(context))
    }

    /**
     * `am broadcast` prints whatever the last receiver sets as result data, so this is
     * how the script shows the outcome. Guarded because the result slot only exists for
     * ordered broadcasts (which `am broadcast` always sends).
     */
    private fun reply(context: Context, message: String) {
        Log.i(TAG, message)
        if (isOrderedBroadcast) {
            resultCode = 0
            resultData = message
        }
    }
}
