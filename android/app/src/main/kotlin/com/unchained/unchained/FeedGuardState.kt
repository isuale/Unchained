package com.unchained.unchained

import android.content.Context

/**
 * Persisted state for the "feed guard" daily time budgets (Instagram Reels,
 * YouTube Shorts, TikTok, Snapchat Stories). Shared between [MainActivity]
 * (reads/writes config, reports live usage to Dart) and [FeedGuardService]
 * (the AccessibilityService that ticks `usedSeconds` and enforces the
 * budget) — both run in the same process, so plain SharedPreferences is
 * enough.
 *
 * Each target key is one of the `block*` BlockingSettings field names
 * (`blockReels`/`blockShorts`/`blockTikTok`/`blockSnapchatStories`), reused
 * as-is so the Dart side doesn't need a second naming scheme.
 *
 * Anti-circumvention lock: once a target's budget is used up, [rolloverIfNeeded]
 * would normally hand back a fresh budget at the next local midnight — trivial
 * to game by just waiting a couple hours. Instead, the moment a target first
 * hits its limit ([addUsedSeconds]) we stamp `exhausted_at` (wall-clock millis)
 * and hold usage frozen at the exhausted value, ignoring day rollover entirely,
 * until a full [LOCK_DURATION_MS] (24h) has elapsed since that stamp — see
 * [rolloverIfNeeded]. [setConfig] also refuses limit/enabled changes for the
 * duration, so the only way out is to wait out the 24h; [lockedUntilMillis]
 * exposes the deadline so Dart can show a countdown and disable its own controls.
 */
object FeedGuardState {

    val TARGETS = listOf(
        "blockReels", "blockShorts", "blockTikTok", "blockSnapchatStories",
    )

    private const val PREFS = "unchained_feed_guard"
    private const val MAX_HISTORY_DAYS = 14
    private const val LOCK_DURATION_MS = 24L * 60 * 60 * 1000

    fun isEnabled(context: Context, target: String): Boolean =
        prefs(context).getBoolean(keyEnabled(target), false)

    fun limitMinutes(context: Context, target: String): Int =
        prefs(context).getInt(keyLimit(target), 30)

    /** Applies the new config, unless [target] is currently locked out from an
     * exhausted budget — in which case it's refused entirely (false) so the
     * user can't dodge the 24h cooldown by disabling the target or raising its
     * limit. */
    fun setConfig(context: Context, target: String, enabled: Boolean, limitMinutes: Int): Boolean {
        if (isLocked(context, target)) return false
        prefs(context).edit()
            .putBoolean(keyEnabled(target), enabled)
            .putInt(keyLimit(target), limitMinutes)
            .apply()
        return true
    }

    /** Seconds used in the current period, resetting to 0 first if the period rolled over. */
    fun usedSeconds(context: Context, target: String): Int {
        rolloverIfNeeded(context, target)
        return prefs(context).getInt(keyUsed(target), 0)
    }

    /** Adds [seconds] to the current period's usage (rolling over first if needed),
     * stamping [keyExhaustedAt] the moment the budget is first used up, and returns
     * the new total. */
    fun addUsedSeconds(context: Context, target: String, seconds: Int): Int {
        rolloverIfNeeded(context, target)
        val p = prefs(context)
        val total = p.getInt(keyUsed(target), 0) + seconds
        val limitSec = limitMinutes(context, target) * 60
        val editor = p.edit().putInt(keyUsed(target), total)
        if (total >= limitSec && p.getLong(keyExhaustedAt(target), 0L) == 0L) {
            editor.putLong(keyExhaustedAt(target), System.currentTimeMillis())
        }
        editor.apply()
        return total
    }

    fun remainingSeconds(context: Context, target: String): Int {
        val limitSec = limitMinutes(context, target) * 60
        return (limitSec - usedSeconds(context, target)).coerceAtLeast(0)
    }

    fun isBudgetExhausted(context: Context, target: String): Boolean =
        remainingSeconds(context, target) <= 0

    /** Millis since epoch when the current 24h lock ends, or 0 if [target] isn't locked. */
    fun lockedUntilMillis(context: Context, target: String): Long {
        rolloverIfNeeded(context, target)
        val exhaustedAt = prefs(context).getLong(keyExhaustedAt(target), 0L)
        if (exhaustedAt == 0L) return 0L
        val until = exhaustedAt + LOCK_DURATION_MS
        return if (System.currentTimeMillis() < until) until else 0L
    }

    fun isLocked(context: Context, target: String): Boolean =
        lockedUntilMillis(context, target) != 0L

    /**
     * Last [days] days of usage for [target], oldest first, zero-filled for
     * gaps (including days before this history existed). The live count is
     * attributed to the day its period actually started (normally today, but
     * while a 24h lock is holding usage frozen past midnight it's still the
     * exhaustion day), not always the literal current date.
     */
    fun history(context: Context, target: String, days: Int = MAX_HISTORY_DAYS): List<Pair<Long, Int>> {
        usedSeconds(context, target) // force rollover so the live bucket is current
        val p = prefs(context)
        val stored = DayHistory.parse(p.getString(keyHistory(target), null)).toMutableMap()
        val liveDay = p.getLong(keyResetDay(target), DayHistory.today())
        stored[liveDay] = p.getInt(keyUsed(target), 0)
        return DayHistory.zeroFilled(stored, days)
    }

    /**
     * Normally rolls usage over at local midnight. But once a target has been
     * exhausted (`exhausted_at` set), usage stays frozen — ignoring midnight —
     * until a full 24h has passed since that stamp, at which point a fresh
     * period begins (archiving the exhausted total, clearing the lock, and
     * resetting usage to 0) regardless of how many calendar days that spanned.
     */
    private fun rolloverIfNeeded(context: Context, target: String) {
        val p = prefs(context)
        val exhaustedAt = p.getLong(keyExhaustedAt(target), 0L)
        if (exhaustedAt != 0L) {
            if (System.currentTimeMillis() < exhaustedAt + LOCK_DURATION_MS) return
            val usedInPeriod = p.getInt(keyUsed(target), 0)
            val storedDay = p.getLong(keyResetDay(target), DayHistory.today())
            val history = DayHistory.parse(p.getString(keyHistory(target), null)).toMutableMap()
            history[storedDay] = usedInPeriod
            p.edit()
                .putInt(keyUsed(target), 0)
                .putLong(keyResetDay(target), DayHistory.today())
                .putLong(keyExhaustedAt(target), 0L)
                .putString(keyHistory(target), DayHistory.serialize(DayHistory.trimmed(history, MAX_HISTORY_DAYS)))
                .apply()
            return
        }
        val today = DayHistory.today()
        val storedDay = p.getLong(keyResetDay(target), today)
        if (storedDay != today) {
            val usedYesterday = p.getInt(keyUsed(target), 0)
            val history = DayHistory.parse(p.getString(keyHistory(target), null)).toMutableMap()
            history[storedDay] = usedYesterday
            p.edit()
                .putInt(keyUsed(target), 0)
                .putLong(keyResetDay(target), today)
                .putString(keyHistory(target), DayHistory.serialize(DayHistory.trimmed(history, MAX_HISTORY_DAYS)))
                .apply()
        }
    }

    private fun keyEnabled(target: String) = "${target}_enabled"
    private fun keyLimit(target: String) = "${target}_limit_min"
    private fun keyUsed(target: String) = "${target}_used_sec"
    private fun keyResetDay(target: String) = "${target}_reset_day"
    private fun keyHistory(target: String) = "${target}_history"
    private fun keyExhaustedAt(target: String) = "${target}_exhausted_at"

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
