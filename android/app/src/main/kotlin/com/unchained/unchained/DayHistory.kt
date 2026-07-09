package com.unchained.unchained

import java.time.LocalDate

/**
 * Shared day-bucketed integer history, serialized as
 * "epochDay:value,epochDay:value,...". Used by [BlockingStats] (blocked DNS
 * queries per day) and [FeedGuardState] (feed usage seconds per day) so both
 * trackers share one parse/serialize/trim implementation instead of two.
 */
object DayHistory {

    fun today(): Long = LocalDate.now().toEpochDay()

    fun parse(raw: String?): Map<Long, Int> {
        if (raw.isNullOrEmpty()) return emptyMap()
        return raw.split(",").mapNotNull { entry ->
            val parts = entry.split(":")
            if (parts.size != 2) return@mapNotNull null
            val day = parts[0].toLongOrNull() ?: return@mapNotNull null
            val value = parts[1].toIntOrNull() ?: return@mapNotNull null
            day to value
        }.toMap()
    }

    fun serialize(map: Map<Long, Int>): String =
        map.entries.joinToString(",") { "${it.key}:${it.value}" }

    /** Keeps only the [maxDays] most recent entries. */
    fun trimmed(map: Map<Long, Int>, maxDays: Int): Map<Long, Int> {
        if (map.size <= maxDays) return map
        return map.entries.sortedByDescending { it.key }
            .take(maxDays)
            .associate { it.key to it.value }
    }

    /** The last [days] days ending today, oldest first, gaps filled with 0. */
    fun zeroFilled(map: Map<Long, Int>, days: Int): List<Pair<Long, Int>> {
        val t = today()
        return (days - 1 downTo 0).map { offset ->
            val day = t - offset
            day to (map[day] ?: 0)
        }
    }
}
