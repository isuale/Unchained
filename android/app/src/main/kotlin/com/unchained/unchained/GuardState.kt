package com.unchained.unchained

import android.content.Context
import android.os.SystemClock

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

    /** How long the watchdog stands down after a successful challenge. */
    const val GRACE_MS = 60_000L

    @Volatile
    var graceUntilElapsed: Long = 0L
        private set

    fun isEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        prefs(context).edit().putBoolean(KEY_ENABLED, enabled).apply()
    }

    fun grantGrace() {
        graceUntilElapsed = SystemClock.elapsedRealtime() + GRACE_MS
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
