package com.unchained.unchained

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.SystemClock
import android.util.TypedValue
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/// Home-screen widget for the prayer streak (the "days giving thanks" count
/// from PrayerRepository.streakFrom on the Dart side). PrayerStreakWidgetService
/// pushes the current value here via HomeWidget.saveWidgetData + updateWidget
/// every time it changes, so this widget is readable without opening the app.
///
/// Android gives a RemoteViews widget no way to keep animating on its own —
/// it's redrawn by the launcher process from static snapshots the app hands
/// it, not by a running loop. So rather than faking constant animation, this
/// plays a short multi-frame "flicker to life" burst (see scheduleBurst)
/// every time there's actually something to show for: the streak changed,
/// the widget was just placed/resized, or the OS's own periodic refresh
/// (android:updatePeriodMillis, floor 30 minutes) fires.
class PrayerStreakWidgetProvider : HomeWidgetProvider() {

    companion object {
        private const val ACTION_FLAME_TICK = "com.unchained.unchained.WIDGET_FLAME_TICK"
        private const val EXTRA_WIDGET_ID = "widget_id"
        private const val EXTRA_FRAME = "frame"
        private const val FRAME_COUNT = 6
        private const val FRAME_INTERVAL_MS = 170L

        // Flame size at each burst frame, as a fraction of the tier's resting
        // size. RemoteViews has no scale/rotation API, but resizing the
        // ImageView itself reads as a flicker just as well.
        private val FRAME_SCALE = floatArrayOf(1.00f, 1.20f, 0.90f, 1.12f, 0.96f, 1.00f)

        private fun tierFor(streak: Int): Int = when {
            streak <= 0 -> 0
            streak < 3 -> 1
            streak < 7 -> 2
            streak < 30 -> 3
            else -> 4
        }

        // Tiers 0-3 climb through unlit -> ember -> orange -> gold as the
        // streak builds (matching streakMilestones' 7-day "on fire" mark);
        // tier 4 (30+ days) pays off in the app's own brand blue instead of
        // the expected red/orange, a deliberate signature touch.
        private val TIER_COLOR = intArrayOf(
            0xFF6B7280.toInt(),
            0xFFFF8A3D.toInt(),
            0xFFFF5A1F.toInt(),
            0xFFFFB020.toInt(),
            0xFF1E5FFF.toInt(),
        )
        private val TIER_BASE_DP = floatArrayOf(42f, 48f, 54f, 60f, 66f)

        private fun streakLabel(streak: Int): String =
            if (streak <= 0) "START TODAY" else "DAY STREAK"

        private fun widgetIds(context: Context): IntArray =
            AppWidgetManager.getInstance(context).getAppWidgetIds(
                ComponentName(context, PrayerStreakWidgetProvider::class.java),
            )

        private fun buildViews(context: Context, streak: Int, frame: Int): RemoteViews {
            val tier = tierFor(streak)
            val color = TIER_COLOR[tier]
            val scale = FRAME_SCALE[frame.coerceIn(0, FRAME_COUNT - 1)]
            val sizeDp = TIER_BASE_DP[tier] * scale

            return RemoteViews(context.packageName, R.layout.widget_prayer_streak).apply {
                setTextViewText(R.id.widget_streak_number, streak.toString())
                setTextViewText(R.id.widget_streak_label, streakLabel(streak))
                setInt(R.id.widget_flame, "setColorFilter", color)

                // setViewLayoutWidth/Height (API 31+) is what actually makes the
                // flame pulse; below that it still shows the right tier size and
                // color, just without the burst animation.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    setViewLayoutWidth(R.id.widget_flame, sizeDp, TypedValue.COMPLEX_UNIT_DIP)
                    setViewLayoutHeight(R.id.widget_flame, sizeDp, TypedValue.COMPLEX_UNIT_DIP)
                }

                val openApp = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("unchainedwidget://streak"),
                )
                setOnClickPendingIntent(R.id.widget_root, openApp)
            }
        }

        private fun tickPendingIntent(context: Context, widgetId: Int, frame: Int): PendingIntent {
            val intent = Intent(context, PrayerStreakWidgetProvider::class.java).apply {
                action = ACTION_FLAME_TICK
                putExtra(EXTRA_WIDGET_ID, widgetId)
                putExtra(EXTRA_FRAME, frame)
            }
            var flags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                flags = flags or PendingIntent.FLAG_IMMUTABLE
            }
            // Distinct request code per (widget, frame) so the six ticks of a
            // burst don't collapse into a single pending intent.
            return PendingIntent.getBroadcast(context, widgetId * 100 + frame, intent, flags)
        }

        /** Schedules frames 1..FRAME_COUNT-1; frame 0 is drawn immediately by the caller. */
        private fun scheduleBurst(context: Context, widgetId: Int) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            for (frame in 1 until FRAME_COUNT) {
                val triggerAt = SystemClock.elapsedRealtime() + FRAME_INTERVAL_MS * frame
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.ELAPSED_REALTIME_WAKEUP,
                    triggerAt,
                    tickPendingIntent(context, widgetId, frame),
                )
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val streak = widgetData.getInt("streak_days", 0)
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, buildViews(context, streak, 0))
            scheduleBurst(context, widgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_FLAME_TICK) {
            val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, -1)
            if (widgetId == -1 || widgetId !in widgetIds(context)) return
            val frame = intent.getIntExtra(EXTRA_FRAME, 0)
            val streak = HomeWidgetPlugin.getData(context).getInt("streak_days", 0)
            AppWidgetManager.getInstance(context)
                .updateAppWidget(widgetId, buildViews(context, streak, frame))
            return
        }
        super.onReceive(context, intent)
    }
}
