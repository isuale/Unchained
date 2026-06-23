package com.unchained.unchained

import android.app.admin.DevicePolicyManager
import android.content.Context

/**
 * Thin wrapper over [DevicePolicyManager] for the uninstall-protection feature.
 *
 * Two strengths of block, best-effort and layered:
 *  1. **Device admin** — once [isAdminActive], Android blocks the uninstall until
 *     the admin is deactivated under Settings (watchdog-guarded). No special
 *     provisioning needed; the user just confirms one system dialog.
 *  2. **Device owner** — if the app was promoted to device owner, [lockUninstall]
 *     calls [DevicePolicyManager.setUninstallBlocked], which makes the uninstall
 *     flatly impossible (no deactivate door). Requires `dpm set-device-owner` on a
 *     device with no accounts, so it is opportunistic: we apply it when we can and
 *     fall back to the device-admin block otherwise.
 */
object GuardAdmin {

    private fun dpm(context: Context): DevicePolicyManager =
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager

    fun isAdminActive(context: Context): Boolean =
        dpm(context).isAdminActive(UnchainedDeviceAdminReceiver.component(context))

    fun isDeviceOwner(context: Context): Boolean =
        dpm(context).isDeviceOwnerApp(context.packageName)

    /**
     * When we are device owner, hard-block (or unblock) uninstall of ourselves via
     * the OS. Returns true if the policy was applied, false if we lack the role.
     */
    fun lockUninstall(context: Context, blocked: Boolean): Boolean {
        val manager = dpm(context)
        if (!manager.isDeviceOwnerApp(context.packageName)) return false
        return try {
            manager.setUninstallBlocked(
                UnchainedDeviceAdminReceiver.component(context),
                context.packageName,
                blocked,
            )
            true
        } catch (_: SecurityException) {
            false
        }
    }

    /** Voluntarily relinquish the device-admin role (used by the guarded turn-off flow). */
    fun removeAdmin(context: Context) {
        val manager = dpm(context)
        val component = UnchainedDeviceAdminReceiver.component(context)
        // Lift the device-owner uninstall block first, or removal is refused.
        if (manager.isDeviceOwnerApp(context.packageName)) {
            try {
                manager.setUninstallBlocked(component, context.packageName, false)
            } catch (_: SecurityException) {
                // ignore — best effort
            }
        }
        if (manager.isAdminActive(component)) {
            manager.removeActiveAdmin(component)
        }
    }
}
