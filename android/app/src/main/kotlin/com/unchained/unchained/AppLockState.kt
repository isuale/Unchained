package com.unchained.unchained

import android.content.Context

/**
 * SharedPreferences-backed state for the prayer app-locker, written from Dart
 * (via the `unchained/applock` channel) and read by [UninstallGuardService].
 *
 * - which apps are locked (a per-package set, or "lock everything")
 * - the unlock window: once a prayer is completed, all locked apps are usable
 *   until [KEY_UNLOCKED_UNTIL] (wall-clock millis), then they re-lock.
 */
object AppLockState {
    private const val PREFS = "applock_state"
    private const val KEY_ENABLED = "lock_enabled"
    private const val KEY_LOCK_ALL = "lock_all"
    private const val KEY_PKGS = "locked_pkgs"
    private const val KEY_UNLOCKED_UNTIL = "unlocked_until"

    private fun prefs(ctx: Context) =
        ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun setConfig(ctx: Context, enabled: Boolean, lockAll: Boolean, pkgs: Set<String>) {
        prefs(ctx).edit()
            .putBoolean(KEY_ENABLED, enabled)
            .putBoolean(KEY_LOCK_ALL, lockAll)
            // Copy into a fresh set — SharedPreferences must not be handed a set
            // it will keep a reference to.
            .putStringSet(KEY_PKGS, HashSet(pkgs))
            .apply()
    }

    /**
     * The master switch. The prayer content is Christian, so a user of another
     * faith can switch the whole locker off in Settings; when off we gate
     * nothing, whatever the lock mode and package set still say.
     *
     * Defaults to true so an install that has never synced from Dart keeps the
     * historical behaviour rather than silently unlocking every app.
     */
    fun isEnabled(ctx: Context): Boolean = prefs(ctx).getBoolean(KEY_ENABLED, true)

    fun isLockAll(ctx: Context): Boolean = prefs(ctx).getBoolean(KEY_LOCK_ALL, false)

    fun lockedPkgs(ctx: Context): Set<String> =
        prefs(ctx).getStringSet(KEY_PKGS, emptySet()) ?: emptySet()

    /** Whether the locker guards anything at all. */
    fun isActive(ctx: Context): Boolean =
        isEnabled(ctx) && (isLockAll(ctx) || lockedPkgs(ctx).isNotEmpty())

    /** Open the "apps unlocked" window for [hours] from now. */
    fun openUnlockWindow(ctx: Context, hours: Int) {
        val until = System.currentTimeMillis() + hours.toLong() * 3_600_000L
        prefs(ctx).edit().putLong(KEY_UNLOCKED_UNTIL, until).apply()
    }

    fun isUnlocked(ctx: Context): Boolean =
        System.currentTimeMillis() < prefs(ctx).getLong(KEY_UNLOCKED_UNTIL, 0L)

    /**
     * Whether opening [pkg] should raise the prayer gate right now: the locker
     * is guarding this app, we're outside the unlock window, and it isn't an
     * exempt (system / launcher / our own) package.
     */
    fun shouldLock(ctx: Context, pkg: String, exempt: Set<String>): Boolean {
        if (!isEnabled(ctx)) return false
        if (pkg in exempt) return false
        if (isUnlocked(ctx)) return false
        if (isLockAll(ctx)) return true
        return pkg in lockedPkgs(ctx)
    }
}
