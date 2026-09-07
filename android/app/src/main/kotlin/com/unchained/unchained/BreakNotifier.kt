package com.unchained.unchained

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Phone notifications for the commitment "break" — the 30-minute window a
 * Monthly / AI plan earns partway through its span.
 *
 * ## Why this lives in Kotlin and not in Dart
 *
 * A break is *earned* at an instant nobody picks: it falls wherever the plan's
 * protected time divides evenly (a 30-day / 2-break plan earns one every ten
 * days, to the minute). Dart only computes that while the app is open, so a
 * user who never happens to have the app in the foreground at that exact minute
 * never learns their break arrived. The whole point of this file is that the
 * phone tells them, with the app closed and even after a reboot.
 *
 * Everything is driven by [AlarmManager] alarms plus a small SharedPreferences
 * mirror of the schedule, so no process of ours has to stay alive between the
 * moment the break is scheduled and the moment it lands. [BootReceiver] calls
 * [rescheduleAfterReboot] because Android drops every alarm on restart.
 *
 * ## The four moments
 *
 *  1. **Unlocked** — the break has been earned and waits to be claimed. Fired
 *     by an alarm at the computed instant.
 *  2. **Running** — the user claimed it. An *ongoing* notification carrying a
 *     live system-driven countdown (`setChronometerCountDown`), so the shade
 *     ticks 29:59 → 00:00 by itself with no service and no battery cost.
 *  3. **Ending soon** — the same notification, rewritten at T-5min and allowed
 *     to alert a second time.
 *  4. **Over** — protection is put back up (see [BreakAlarmReceiver]) and the
 *     notification says so.
 *
 * All display text is pushed down from Dart on every sync and mirrored into
 * prefs, so notifications stay in the language the user picked in-app rather
 * than the phone's system language — and remain available to an alarm that
 * fires long after the Flutter engine is gone.
 */
object BreakNotifier {

    const val TAG = "UnchainedBreaks"

    private const val PREFS = "unchained_breaks"

    // Schedule mirror.
    private const val KEY_NEXT_BREAK_AT = "next_break_at"
    private const val KEY_BREAK_ENDS_AT = "break_ends_at"
    private const val KEY_BREAKS_LEFT = "breaks_left"
    private const val KEY_BREAKS_TOTAL = "breaks_total"
    private const val KEY_BREAK_DURATION = "break_duration_ms"

    /**
     * The `next_break_at` instant whose "unlocked" notification has already been
     * announced. [sync] runs on every settings write — a social toggle, a
     * blocklist edit — and without this a user who dismissed the card would have
     * it thrown back at them by unrelated taps. The alarm itself always
     * announces; this only suppresses the *re-posts*.
     */
    private const val KEY_ANNOUNCED_FOR = "announced_for"

    /** Prefix for every pushed-down string; the Dart map keys are appended. */
    private const val TEXT_PREFIX = "t_"

    const val CHANNEL_ID = "unchained_breaks"

    // One id per *visible* notification. "Unlocked" and "over" are separate
    // moments the user may want to keep; "running" and "ending soon" are the
    // same live card being rewritten, so they deliberately share an id.
    private const val ID_AVAILABLE = 4101
    private const val ID_RUNNING = 4102
    private const val ID_ENDED = 4103

    // Alarm request codes — distinct so cancelling one never cancels another.
    private const val REQ_AVAILABLE = 41
    private const val REQ_ENDING_SOON = 42
    private const val REQ_ENDED = 43

    /** How long before the break expires the "wrap up" warning fires. */
    private const val ENDING_SOON_MS = 5 * 60 * 1000L

    /**
     * A "5 minutes left" warning only means something on a break long enough for
     * five minutes to be a meaningful slice of it. On a short break — the
     * one-minute break `CommitmentStatus.testMode` produces, or any future short
     * one — the warning would fire the instant the break started and the card
     * would open on "5 minutes left" instead of "break in progress". Below this
     * length the warning is simply skipped.
     */
    private const val MIN_BREAK_FOR_WARNING_MS = 2 * ENDING_SOON_MS

    /** Brand accent used for the notification tint. */
    private val COLOR_ACCENT = Color.parseColor("#1E5FFF")
    private val COLOR_GREEN = Color.parseColor("#00D26A")

    // ---------------------------------------------------------------- syncing

    /**
     * The single entry point from Dart. Replaces the whole schedule: any alarm
     * or notification that no longer matches the state passed in is cleared.
     *
     * @param nextBreakAt wall-clock ms when the next break becomes available,
     *   or 0 if none is coming (no breaks left, no plan, span finished).
     * @param breakAvailableNow true if a break is earned and waiting right now.
     * @param breakEndsAt wall-clock ms a claimed break expires, or 0 if none is
     *   running. Outranks the two arguments above.
     */
    fun sync(
        context: Context,
        nextBreakAt: Long,
        breakAvailableNow: Boolean,
        breakEndsAt: Long,
        breakDurationMs: Long,
        breaksLeft: Int,
        breaksTotal: Int,
        texts: Map<String, String>,
    ) {
        val prefs = prefs(context)
        prefs.edit().apply {
            putLong(KEY_NEXT_BREAK_AT, nextBreakAt)
            putLong(KEY_BREAK_ENDS_AT, breakEndsAt)
            putInt(KEY_BREAKS_LEFT, breaksLeft)
            putInt(KEY_BREAKS_TOTAL, breaksTotal)
            putLong(KEY_BREAK_DURATION, breakDurationMs)
            for ((k, v) in texts) putString(TEXT_PREFIX + k, v)
            apply()
        }
        ensureChannel(context)
        applySchedule(context, breakAvailableNow)
    }

    /**
     * Rebuilds alarms and notifications from the mirrored schedule. Used by
     * [sync] and, after a restart wipes every alarm, by [rescheduleAfterReboot].
     */
    private fun applySchedule(context: Context, breakAvailableNow: Boolean) {
        val prefs = prefs(context)
        val now = System.currentTimeMillis()
        val endsAt = prefs.getLong(KEY_BREAK_ENDS_AT, 0L)
        val nextAt = prefs.getLong(KEY_NEXT_BREAK_AT, 0L)

        cancelAlarm(context, REQ_AVAILABLE)
        cancelAlarm(context, REQ_ENDING_SOON)
        cancelAlarm(context, REQ_ENDED)

        // A running break outranks everything, exactly as in commitment.dart.
        if (endsAt > now) {
            NotificationManagerCompat.from(context).cancel(ID_AVAILABLE)
            NotificationManagerCompat.from(context).cancel(ID_ENDED)
            val lead = warningLead(prefs.getLong(KEY_BREAK_DURATION, 0L))
            showRunning(context, endsAt, endingSoon = lead > 0 && endsAt - now <= lead)
            if (lead > 0 && endsAt - now > lead) {
                setAlarm(context, REQ_ENDING_SOON, endsAt - lead,
                    BreakAlarmReceiver.KIND_ENDING_SOON)
            }
            setAlarm(context, REQ_ENDED, endsAt, BreakAlarmReceiver.KIND_ENDED)
            return
        }

        NotificationManagerCompat.from(context).cancel(ID_RUNNING)

        if (breakAvailableNow) {
            // Re-post only if this particular break was never announced — e.g.
            // the alarm was dropped by Doze, or the break was earned while the
            // phone was off. Otherwise leave the user's shade alone.
            if (prefs.getLong(KEY_ANNOUNCED_FOR, 0L) != nextAt) showAvailable(context)
            return
        }

        NotificationManagerCompat.from(context).cancel(ID_AVAILABLE)
        if (nextAt > now) {
            setAlarm(context, REQ_AVAILABLE, nextAt, BreakAlarmReceiver.KIND_AVAILABLE)
        }
    }

    /**
     * Android clears every pending alarm when the phone restarts, so a break
     * scheduled for next Tuesday silently never arrives unless we put the
     * alarms back. Called from [BootReceiver].
     */
    fun rescheduleAfterReboot(context: Context) {
        val prefs = prefs(context)
        val now = System.currentTimeMillis()
        val hasSchedule =
            prefs.getLong(KEY_NEXT_BREAK_AT, 0L) > 0L || prefs.getLong(KEY_BREAK_ENDS_AT, 0L) > 0L
        if (!hasSchedule) return
        ensureChannel(context)
        // A break earned while the phone was off still counts as available: the
        // stored instant is in the past, so surface it rather than losing it.
        val earnedWhileOff = prefs.getLong(KEY_NEXT_BREAK_AT, 0L).let { it in 1 until now }
        // A restart also wipes the notification shade, so an already-announced
        // break would silently disappear. Forget the announcement so the waiting
        // break is posted again rather than lost to a reboot.
        prefs.edit().putLong(KEY_ANNOUNCED_FOR, 0L).apply()
        applySchedule(context, breakAvailableNow = earnedWhileOff)
        Log.i(TAG, "rescheduled break alarms after boot (earnedWhileOff=$earnedWhileOff)")
    }

    /** Drops every break alarm and notification (commitment cleared / plan reset). */
    fun cancelAll(context: Context) {
        cancelAlarm(context, REQ_AVAILABLE)
        cancelAlarm(context, REQ_ENDING_SOON)
        cancelAlarm(context, REQ_ENDED)
        val nm = NotificationManagerCompat.from(context)
        nm.cancel(ID_AVAILABLE)
        nm.cancel(ID_RUNNING)
        nm.cancel(ID_ENDED)
        prefs(context).edit()
            .putLong(KEY_NEXT_BREAK_AT, 0L)
            .putLong(KEY_BREAK_ENDS_AT, 0L)
            .putLong(KEY_ANNOUNCED_FOR, 0L)
            .apply()
    }

    // ---------------------------------------------------------- notifications

    /** "Your break just unlocked." Waits indefinitely; nothing expires. */
    fun showAvailable(context: Context) {
        prefs(context).edit()
            .putLong(KEY_ANNOUNCED_FOR, prefs(context).getLong(KEY_NEXT_BREAK_AT, 0L))
            .apply()
        // Already formatted with the real counts on the Dart side — plural rules
        // differ per language and belong in the ARB files, not in here.
        val sub = text(context, "availableSub", "")
        val title = text(context, "availableTitle", "Your break is ready")
        val body = text(context, "availableBody", "Turn protection off whenever you want it.")

        notify(
            context, ID_AVAILABLE,
            base(context, R.drawable.ic_notif_break_unlocked, COLOR_GREEN)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setSubText(sub.ifBlank { null })
                .setCategory(NotificationCompat.CATEGORY_REMINDER)
                .setAutoCancel(true)
                // Re-syncs (every app launch) must not re-buzz an already
                // visible reminder; a dismissed one may legitimately alert again.
                .setOnlyAlertOnce(true)
                .addAction(
                    0,
                    text(context, "actionOpen", "Open"),
                    launchPendingIntent(context),
                )
        )
    }

    /**
     * The live break card. [setUsesChronometer] + [setChronometerCountDown] make
     * Android itself tick the remaining time down in the shade once per second —
     * no service, no alarm-per-minute, no battery cost.
     */
    fun showRunning(context: Context, endsAt: Long, endingSoon: Boolean) {
        val title = if (endingSoon) {
            text(context, "endingSoonTitle", "5 minutes left")
        } else {
            text(context, "runningTitle", "Break in progress")
        }
        val body = if (endingSoon) {
            text(context, "endingSoonBody", "Protection comes back on by itself.")
        } else {
            text(context, "runningBody", "Protection is off until the timer runs out.")
        }
        val accent = if (endingSoon) COLOR_ACCENT else COLOR_GREEN

        val builder = base(context, R.drawable.ic_notif_break_running, accent)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setWhen(endsAt)
            .setShowWhen(true)
            .setUsesChronometer(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setOngoing(true)
            .setAutoCancel(false)
            // The five-minute warning is the one update that is allowed to
            // interrupt again; every other re-post stays silent.
            .setOnlyAlertOnce(!endingSoon)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            builder.setChronometerCountDown(true)
        }
        notify(context, ID_RUNNING, builder)
    }

    /**
     * "Break over." [restored] reports whether protection actually came back up,
     * because promising a shield that isn't there would be worse than silence.
     */
    fun showEnded(context: Context, restored: Boolean) {
        NotificationManagerCompat.from(context).cancel(ID_RUNNING)
        val title = if (restored) {
            text(context, "endedTitle", "Break over — shield back up")
        } else {
            text(context, "endedFailTitle", "Break over")
        }
        val body = if (restored) {
            text(context, "endedBody", "Your commitment is running again.")
        } else {
            text(context, "endedFailBody", "Open the app to put your protection back on.")
        }
        notify(
            context, ID_ENDED,
            base(context, R.drawable.ic_notif_break_shield, COLOR_ACCENT)
                .setContentTitle(title)
                .setContentText(body)
                .setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setCategory(NotificationCompat.CATEGORY_STATUS)
                // Unrestored protection is a call to action, not an FYI: keep it
                // in the shade until the user actually deals with it.
                .setAutoCancel(true)
                .setOngoing(!restored)
                .addAction(0, text(context, "actionOpen", "Open"), launchPendingIntent(context))
        )
    }

    /** Shared skeleton: brand tint, tap-to-open, high priority, lock-screen safe. */
    private fun base(context: Context, icon: Int, accent: Int): NotificationCompat.Builder =
        NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(icon)
            .setColor(accent)
            .setContentIntent(launchPendingIntent(context))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            // The wording is deliberately neutral ("break", "protection"), so it
            // is safe to show in full on a lock screen — which is the only place
            // most users will actually see it land.
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

    private fun notify(context: Context, id: Int, builder: NotificationCompat.Builder) {
        try {
            NotificationManagerCompat.from(context).notify(id, builder.build())
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS refused on Android 13+. Nothing to do but skip.
            Log.w(TAG, "notification $id suppressed: permission not granted", e)
        }
    }

    private fun launchPendingIntent(context: Context): PendingIntent {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        return PendingIntent.getActivity(
            context, 0, launch,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            text(context, "channelName", "Breaks"),
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = text(context, "channelDesc", "Tells you the moment a break unlocks.")
            setShowBadge(true)
            enableLights(true)
            lightColor = COLOR_GREEN
            enableVibration(true)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
        }
        context.getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }

    // ----------------------------------------------------------------- alarms

    private fun setAlarm(context: Context, requestCode: Int, atMillis: Long, kind: String) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        val pi = alarmPendingIntent(context, requestCode, kind)
        try {
            // Exact where the OS allows it (Android 14 denies SCHEDULE_EXACT_ALARM
            // to non-alarm apps by default). The inexact fallback still pierces
            // Doze; it just lands within a few minutes rather than on the second,
            // which is fine for a break that then waits for the user anyway.
            val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S ||
                am.canScheduleExactAlarms()
            if (exact) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
            } else {
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
            }
            Log.i(TAG, "alarm[$kind] set for $atMillis (exact=$exact)")
        } catch (e: SecurityException) {
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, atMillis, pi)
            Log.w(TAG, "alarm[$kind] fell back to inexact", e)
        }
    }

    private fun cancelAlarm(context: Context, requestCode: Int) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        am.cancel(alarmPendingIntent(context, requestCode, kind = ""))
    }

    /**
     * The `kind` extra is deliberately NOT part of PendingIntent equality
     * (extras never are), so cancelling by request code alone works even though
     * the cancel path passes an empty kind.
     */
    private fun alarmPendingIntent(context: Context, requestCode: Int, kind: String): PendingIntent {
        val intent = Intent(context, BreakAlarmReceiver::class.java)
            .setAction(BreakAlarmReceiver.ACTION_FIRE)
            .putExtra(BreakAlarmReceiver.EXTRA_KIND, kind)
        return PendingIntent.getBroadcast(
            context, requestCode, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }

    // ------------------------------------------------------------------ prefs

    fun breakEndsAt(context: Context): Long = prefs(context).getLong(KEY_BREAK_ENDS_AT, 0L)

    /**
     * How long before the end the "wrap up" warning should fire, or 0 to skip it
     * entirely because the break is too short for the warning to make sense.
     */
    fun warningLead(breakDurationMs: Long): Long =
        if (breakDurationMs >= MIN_BREAK_FOR_WARNING_MS) ENDING_SOON_MS else 0L

    fun breakDurationMs(context: Context): Long =
        prefs(context).getLong(KEY_BREAK_DURATION, 0L)

    private fun text(context: Context, key: String, fallback: String): String =
        prefs(context).getString(TEXT_PREFIX + key, null)?.takeIf { it.isNotBlank() } ?: fallback

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
