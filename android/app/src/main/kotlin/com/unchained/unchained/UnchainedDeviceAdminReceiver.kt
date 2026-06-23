package com.unchained.unchained

import android.app.admin.DeviceAdminReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

/**
 * Device-administration receiver for the hard uninstall block.
 *
 * Being an **active device administrator** is itself enough for Android to refuse
 * an uninstall: the system greys the Uninstall control out until the admin is
 * deactivated, so the only escape door becomes the "Deactivate" screen under
 * Settings (which the accessibility watchdog already covers, because it lives in
 * `com.android.settings` and shows our app label).
 *
 * If the app is additionally promoted to **device owner** (via
 * `adb shell dpm set-device-owner com.unchained.app/com.unchained.unchained.UnchainedDeviceAdminReceiver`
 * on a device with no accounts), [DevicePolicyManager.setUninstallBlocked] makes
 * the uninstall *impossible* — there is no deactivate door at all. See
 * [GuardAdmin] for the helper that drives both.
 *
 * [onDisableRequested] returns the warning the system shows on the deactivate
 * confirmation screen — a last reminder of why this is here.
 */
class UnchainedDeviceAdminReceiver : DeviceAdminReceiver() {

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence =
        "Deactivating this removes Unchained's uninstall protection. Stay the course."

    companion object {
        /** The admin component, resolved against the runtime package (`com.unchained.app`). */
        fun component(context: Context): ComponentName =
            ComponentName(context.applicationContext, UnchainedDeviceAdminReceiver::class.java)
    }
}
