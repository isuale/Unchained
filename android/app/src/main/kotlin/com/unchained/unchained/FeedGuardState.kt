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
 */
object FeedGuardState {

    val TARGETS = listOf(
        "blockReels", "blockShorts", "blockTikTok", "blockSnapchatStories",
    )

    private const val PREFS = "unchained_feed_guard"
    private const val MAX_HISTORY_DAYS = 14

    fun isEnabled(context: Context, target: String): Boolean =
        prefs(context).getBoolean(keyEnabled(target), false)

    fun limitMinutes(context: Context, target: String): Int =
        prefs(context).getInt(keyLimit(target), 30)

    fun setConfig(context: Context, target: String, enabled: Boolean, limitMinutes: Int) {
        prefs(context).edit()
            .putBoolean(keyEnabled(target), enabled)
            .putInt(keyLimit(target), limitMinutes)
            .apply()
    }

    /** Seconds used today, resetting to 0 first if the stored day has rolled over. */
    fun usedSeconds(context: Context, target: String): Int {
        rolloverIfNeeded(context, target)
        return prefs(context).getInt(keyUsed(target), 0)
    }

    /** Adds [seconds] to today's usage (rolling over first if needed) and returns the new total. */
    fun addUsedSeconds(context: Context, target: String, seconds: Int): Int {
        rolloverIfNeeded(context, target)
        val p = prefs(context)
        val total = p.getInt(keyUsed(target), 0) + seconds
        p.edit().putInt(keyUsed(target), total).apply()
        return total
    }

    fun remainingSeconds(context: Context, target: String): Int {
        val limitSec = limitMinutes(context, target) * 60
        return (limitSec - usedSeconds(context, target)).coerceAtLeast(0)
    }

    fun isBudgetExhausted(context: Context, target: String): Boolean =
        remainingSeconds(context, target) <= 0

    /**
     * Last [days] days of usage for [target], oldest first, zero-filled for
     * gaps (including days before this history existed). Today's entry is
     * always the live count, not the last-saved snapshot.
     */
    fun history(context: Context, target: String, days: Int = MAX_HISTORY_DAYS): List<Pair<Long, Int>> {
        usedSeconds(context, target) // force rollover so today's bucket is current
        val stored = DayHistory.parse(prefs(context).getString(keyHistory(target), null)).toMutableMap()
        stored[DayHistory.today()] = prefs(context).getInt(keyUsed(target), 0)
        return DayHistory.zeroFilled(stored, days)
    }

    private fun rolloverIfNeeded(context: Context, target: String) {
        val p = prefs(context)
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

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
