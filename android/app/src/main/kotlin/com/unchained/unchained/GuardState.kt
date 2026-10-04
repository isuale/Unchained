package com.unchained.unchained

import android.content.Context
import android.os.SystemClock
import android.provider.Settings

/**
 * Tiny shared state between the Flutter side, [MainActivity] and
 * [UninstallGuardService] (all in the same process).
 *
 * - `enabled` is persisted in SharedPreferences so the watchdog keeps guarding
 *   across restarts. It is the single source of truth for "is uninstall protection on".
 * - `graceUntilElapsed` is a volatile, in-memory deadline: once the user passes the
 *   scripture challenge we open a short window during which the watchdog stands down,
 *   so they can actually reach the screen they were heading for.
 */
object GuardState {

    private const val PREFS = "unchained_guard"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_ARM_PENDING = "arm_pending"

    /** How long the watchdog stands down after a successful challenge. */
    const val GRACE_MS = 60_000L

    @Volatile
    var graceUntilElapsed: Long = 0L
        private set

    fun isEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
        // Turning protection on means "guard from this second": a grace window left
        // over from a deep-link into Settings must not keep the watchdog asleep.
        if (enabled) graceUntilElapsed = 0L
    }

    fun grantGrace(ms: Long = GRACE_MS) {
        graceUntilElapsed = SystemClock.elapsedRealtime() + ms
    }

    /**
     * "Arm as soon as the permissions land." Set by the dashboard's turn-on sheet so
     * the watchdog itself can switch protection on the instant the user grants the
     * last permission in system Settings — without waiting for them to come back to
     * the app (which left a gap where Settings > Uninstall was still unguarded).
     * Persisted so it survives the activity being torn down while in Settings.
     */
    fun isArmPending(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ARM_PENDING, false)

    fun setArmPending(context: Context, pending: Boolean) {
        prefs(context).edit().putBoolean(KEY_ARM_PENDING, pending).apply()
    }

    /**
     * If an arm is pending and every permission is now in place, turn protection on
     * (plus the device-owner hard block, when we hold that role). Returns true if it
     * armed. Called from the watchdog on connect and on every window event.
     */
    fun armIfPendingAndReady(context: Context): Boolean {
        if (!isArmPending(context)) return false
        if (!Settings.canDrawOverlays(context)) return false
        setArmPending(context, false)
        setEnabled(context, true)
        GuardAdmin.lockUninstall(context, true)
        return true
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
