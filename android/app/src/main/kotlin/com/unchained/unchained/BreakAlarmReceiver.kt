package com.unchained.unchained

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Wakes the phone at the three moments of a commitment break and posts the
 * matching notification (see [BreakNotifier] for the why).
 *
 * This is the only piece of the break feature that runs when the app is closed,
 * so it is deliberately tiny: no Flutter engine, no database, nothing but the
 * SharedPreferences mirror [BreakNotifier] keeps.
 */
class BreakAlarmReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_FIRE = "com.unchained.unchained.BREAK_ALARM"
        const val EXTRA_KIND = "kind"

        const val KIND_AVAILABLE = "available"
        const val KIND_ENDING_SOON = "ending_soon"
        const val KIND_ENDED = "ended"

        private const val TAG = BreakNotifier.TAG
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val kind = intent?.getStringExtra(EXTRA_KIND) ?: return
        Log.i(TAG, "break alarm fired: $kind")
        BreakNotifier.ensureChannel(context)

        when (kind) {
            KIND_AVAILABLE -> BreakNotifier.showAvailable(context)

            KIND_ENDING_SOON -> {
                val endsAt = BreakNotifier.breakEndsAt(context)
                // A break that was already ended early (user re-armed protection)
                // must not resurrect its countdown card.
                if (endsAt > System.currentTimeMillis()) {
                    BreakNotifier.showRunning(context, endsAt, endingSoon = true)
                }
            }

            KIND_ENDED -> BreakNotifier.showEnded(context, restored = restoreProtection(context))
        }
    }

    /**
     * Puts the shield back up the moment the break expires.
     *
     * Without this, closing the app during a break left the phone unprotected
     * until the user happened to reopen it — the Dart-side enforcement in
     * `commitmentStatusProvider` only runs while the app is alive. Re-arming
     * here is what makes "protection comes back on by itself" literally true.
     *
     * [BlockingService.setDesiredEnabled] must be flipped back first: claiming
     * the break went through the user's own "turn protection off", which
     * recorded their intent as off. The break expiring is the moment that
     * intent reverts.
     *
     * Returns false (and the notification says so instead of lying) when the
     * VPN consent is gone or the OS refuses the background service start.
     */
    private fun restoreProtection(context: Context): Boolean {
        return try {
            BlockingService.setDesiredEnabled(context, true)
            BlockingService.isRunning || BlockingService.restoreIfDesired(context, "break-end")
        } catch (e: Exception) {
            Log.e(TAG, "break-end restore failed", e)
            false
        }
    }
}
