package com.unchained.unchained

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Build
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
        if (!BlockingService.desiredEnabled(context)) {
            Log.d(TAG, "Protection was off before reboot; nothing to restore")
            return
        }

        // VpnService.prepare() returns null when the user has already granted VPN
        // consent to us and no other VPN app has taken over since. Non-null means
        // consent is needed — that requires an activity and a user tap, which we
        // cannot do from a boot broadcast, so we bail rather than crash. The app
        // will re-ask on next launch through the normal prepare() flow.
        if (VpnService.prepare(context) != null) {
            Log.w(TAG, "VPN consent not held at boot; cannot auto-start")
            return
        }

        val svc = Intent(context, BlockingService::class.java)
            .setAction(BlockingService.ACTION_START)
        try {
            // A receiver handling BOOT_COMPLETED is exempt from the Android 12+
            // background foreground-service start restriction, so this is allowed
            // here even though the app has no visible UI.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(svc)
            } else {
                context.startService(svc)
            }
            Log.i(TAG, "Protection restored after boot")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restore protection after boot", e)
        }
    }
}
