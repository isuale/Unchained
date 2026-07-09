package com.unchained.unchained

import android.content.Context

/**
 * Day-bucketed count of blocked DNS queries (BlockingService's NXDOMAIN
 * responses), so the Progress tab can show a real "blocked temptations"
 * trend instead of just a static blocklist size. Counts queries, not site
 * visits — one page load can trigger several blocked lookups (trackers,
 * CDNs) — so this is a proxy signal, not a literal visit count.
 */
object BlockingStats {

    private const val PREFS = "unchained_blocking_stats"
    private const val KEY_HISTORY = "blocked_history"
    const val MAX_DAYS = 14

    fun recordBlocked(context: Context) {
        val map = DayHistory.parse(prefs(context).getString(KEY_HISTORY, null)).toMutableMap()
        val today = DayHistory.today()
        map[today] = (map[today] ?: 0) + 1
        save(context, DayHistory.trimmed(map, MAX_DAYS))
    }

    /** Last [days] days, oldest first, zero-filled for days with no blocks. */
    fun history(context: Context, days: Int = MAX_DAYS): List<Pair<Long, Int>> =
        DayHistory.zeroFilled(DayHistory.parse(prefs(context).getString(KEY_HISTORY, null)), days)

    private fun save(context: Context, map: Map<Long, Int>) {
        prefs(context).edit().putString(KEY_HISTORY, DayHistory.serialize(map)).apply()
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
