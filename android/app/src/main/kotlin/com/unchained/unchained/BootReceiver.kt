package com.unchained.unchained

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/// Brings the DNS-blocking tunnel back up after the device restarts.
///
/// Without this, rebooting the phone was a free escape: the VPN service dies with
/// the OS, nothing restarts it, and protection stays off until the user opens the
/// app and toggles it back on by hand. The Drift `protectionEnabled` flag still
/// said "on", but nothing acted on it.
///
/// We can't read the Drift DB from here (it's Dart-side, and no Flutter engine is
/// running this early), so we read the native mirror written by
/// [BlockingService.setDesiredEnabled] on every explicit start/stop.
class BootReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent?) {
        val action = intent?.action ?: return
        Log.d(TAG, "onReceive action=$action")

        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_MY_PACKAGE_REPLACED -> restoreProtection(context)
            else -> return
        }
    }

    private fun restoreProtection(context: Context) {
        BlockingService.restoreIfDesired(context, "boot")
    }
}
