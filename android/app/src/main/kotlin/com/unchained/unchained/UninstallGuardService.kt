package com.unchained.unchained

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

/**
 * The "uninstall protection" watchdog.
 *
 * Android does not let an app hook into the system Settings / package-installer UI,
 * so the only reliable way to know the user has reached the **Force stop / Uninstall**
 * screen is to listen as an AccessibilityService and inspect whichever window is in
 * the foreground. When we recognise one of the "escape doors" below, we slam the
 * Flutter scripture-challenge screen ([MainActivity] routed to `/lock`) on top of it.
 *
 * The doors we guard:
 *  - the Settings **App info** page for our app (Force stop / Uninstall live there)
 *  - the package-installer **uninstall confirmation** dialog
 *  - our **Play Store** listing (also has an Uninstall button)
 *  - the **Accessibility settings** detail page for our app (where a determined user
 *    would try to switch *this very service* off — the obvious bypass)
 *
 * Detection is keyed off our visible app label ("Unchained") rather than the
 * button captions, so it survives whatever language the system UI is in.
 *
 * Background-activity-start from a service is blocked on modern Android *unless* the
 * app holds the "Display over other apps" (SYSTEM_ALERT_WINDOW) permission, which is
 * why the feature requires that grant in addition to enabling this service.
 */
class UninstallGuardService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "service connected; guardEnabled=${GuardState.isEnabled(this)}")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        val type = event.eventType
        if (type != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            type != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) {
            return
        }

        val pkg = event.packageName?.toString() ?: return
        // Never react to ourselves (the lock/prayer screen itself, or our deep-links).
        if (pkg == packageName) return

        // Prayer app-lock: raise the prayer gate when a locked app is brought to
        // the foreground. Runs independently of the uninstall guard, but only on
        // a real app switch (WINDOW_STATE_CHANGED), never on content churn.
        if (type == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            maybeLockApp(pkg)
        }

        // Everything below is the uninstall guard, which requires it to be on.
        if (!GuardState.isEnabled(this)) return

        val watched = pkg in SETTINGS_PACKAGES || pkg in INSTALLER_PACKAGES || pkg in STORE_PACKAGES
        if (watched) Log.d(TAG, "watched window pkg=$pkg type=$type")

        val now = SystemClock.elapsedRealtime()
        // The user just passed the challenge — let them through their grace window.
        if (now < GuardState.graceUntilElapsed) return
        // Debounce: one window can fire many content-changed events in a row.
        if (now - lastTriggerElapsed < TRIGGER_DEBOUNCE_MS) return

        val door = when {
            pkg in SETTINGS_PACKAGES -> isOurAppInfoPage(event)
            pkg in INSTALLER_PACKAGES -> isOurUninstallDialog(event)
            pkg in STORE_PACKAGES -> isOurStoreListing(event)
            else -> false
        }

        if (watched) Log.d(TAG, "door=$door for pkg=$pkg")

        if (door) {
            lastTriggerElapsed = now
            Log.d(TAG, "TRIGGER: covering $pkg with lock")
            // Cancel the dangerous dialog/screen underneath, then cover with the lock.
            // The BACK kicks off a window transition in the target app; launching the
            // lock in the same instant races that transition and can lose the z-order
            // fight (the lock never surfaces and the user is just bounced back). Let the
            // BACK settle, then launch — so the lock reliably comes to the foreground.
            performGlobalAction(GLOBAL_ACTION_BACK)
            mainHandler.postDelayed({ launchLock() }, LAUNCH_DELAY_MS)
        }
    }

    override fun onInterrupt() {}

    /**
     * True ONLY when the active Settings window is **our app's App-info page** —
     * the one screen that holds Force stop / Uninstall. We require BOTH our app
     * label *and* a Force-stop/Uninstall control to be present in the same active
     * window, so merely opening Settings, searching, or scrolling the Apps list
     * (where our name appears without those controls) does NOT trigger the lock.
     * The user keeps free access to all of Settings except this page.
     */
    private fun isOurAppInfoPage(event: AccessibilityEvent): Boolean =
        activeScreenContains(event, APP_LABELS) &&
            activeScreenContains(event, DANGER_CONTROLS)

    /** The package-installer's uninstall confirmation dialog for *our* app. */
    private fun isOurUninstallDialog(event: AccessibilityEvent): Boolean =
        activeScreenContains(event, APP_LABELS) &&
            activeScreenContains(event, UNINSTALL_HINTS)

    /** Play Store listing for us: our name is present alongside an uninstall control. */
    private fun isOurStoreListing(event: AccessibilityEvent): Boolean =
        activeScreenContains(event, APP_LABELS) &&
            activeScreenContains(event, UNINSTALL_HINTS)

    /**
     * Whether all of [needles] appear in the window the user is actually looking at
     * — the event's own source node or the active window. We deliberately do NOT
     * scan every enumerable window: that picked up our app label from unrelated or
     * lingering windows (even our own lock), firing the guard when the user merely
     * opened Settings and bouncing them in and out of the lock.
     */
    private fun activeScreenContains(event: AccessibilityEvent, needles: List<String>): Boolean {
        // 1) The node that fired this event.
        event.source?.let { src ->
            try {
                if (nodeTreeContains(src, needles)) return true
            } finally {
                src.recycle()
            }
        }
        // 2) The current active (foreground, focused) window.
        rootInActiveWindow?.let { root ->
            try {
                if (nodeTreeContains(root, needles)) return true
            } finally {
                root.recycle()
            }
        }
        return false
    }

    /**
     * If [pkg] is a locked app and we're outside the unlock window, bring the
     * Flutter prayer gate ([MainActivity] routed to `/pray`) to the front over
     * it. Debounced so one launch doesn't fire repeatedly.
     */
    private fun maybeLockApp(pkg: String) {
        if (!AppLockState.shouldLock(this, pkg, exemptPackages())) return
        val now = SystemClock.elapsedRealtime()
        if (now - lastPrayerLaunchElapsed < PRAYER_DEBOUNCE_MS) return
        lastPrayerLaunchElapsed = now
        Log.d(TAG, "APP-LOCK: raising prayer gate over $pkg")
        launchPrayer(pkg)
    }

    private fun launchPrayer(pkg: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            putExtra(MainActivity.EXTRA_SHOW_PRAYER, true)
            putExtra(MainActivity.EXTRA_PRAYER_PACKAGE, pkg)
        }
        startActivity(intent)
    }

    /**
     * Packages the app-lock never gates: ourselves, the system UI / framework,
     * the current launcher (locking Home would trap the user), and the Settings
     * / installer surfaces (so the phone stays usable even in "lock all" mode).
     * Cached after first resolution.
     */
    private fun exemptPackages(): Set<String> {
        cachedExempt?.let { return it }
        val set = HashSet<String>()
        set.add(packageName)
        set.add("com.android.systemui")
        set.add("android")
        set.addAll(SETTINGS_PACKAGES)
        set.addAll(INSTALLER_PACKAGES)
        defaultLauncher()?.let { set.add(it) }
        cachedExempt = set
        return set
    }

    private fun defaultLauncher(): String? = try {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        packageManager
            .resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
            ?.activityInfo
            ?.packageName
    } catch (e: Exception) {
        null
    }

    private fun launchLock() {
        val intent = Intent(this, MainActivity::class.java).apply {
            // CLEAR_TOP (vs. the old REORDER_TO_FRONT) forces a real bring-to-front of
            // our existing instance and delivers onNewIntent, instead of a soft reorder
            // that can be overridden by a competing transition and never become visible.
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            )
            putExtra(MainActivity.EXTRA_SHOW_LOCK, true)
        }
        startActivity(intent)
    }

    /**
     * Depth-limited scan of the node tree for any of [needles] (case-insensitive,
     * matched against both text and content-description). Recycles as it goes.
     */
    private fun nodeTreeContains(
        node: AccessibilityNodeInfo?,
        needles: List<String>,
        depth: Int = 0,
    ): Boolean {
        if (node == null || depth > MAX_DEPTH) return false
        val text = node.text?.toString()?.lowercase()
        val desc = node.contentDescription?.toString()?.lowercase()
        if (needles.any { (text?.contains(it) == true) || (desc?.contains(it) == true) }) {
            return true
        }
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val hit = nodeTreeContains(child, needles, depth + 1)
            child?.recycle()
            if (hit) return true
        }
        return false
    }

    /** Posts the delayed lock launch onto the main thread. */
    private val mainHandler = Handler(Looper.getMainLooper())

    companion object {
        private const val TAG = "UnchainedGuard"
        // Short enough to re-cover almost immediately if the user dismisses us, long
        // enough that one screen's burst of content-changed events fires us only once.
        private const val TRIGGER_DEBOUNCE_MS = 700L
        private const val MAX_DEPTH = 40

        /** Wait for the BACK transition to settle before launching the lock. */
        private const val LAUNCH_DELAY_MS = 150L

        // Debounce for the prayer gate so one app open raises it once, not on
        // every follow-up window event within the same app.
        private const val PRAYER_DEBOUNCE_MS = 1500L

        private var lastTriggerElapsed = 0L
        private var lastPrayerLaunchElapsed = 0L

        // Resolved once: the packages the app-lock must never gate.
        private var cachedExempt: Set<String>? = null

        // Our user-visible label (see android:label in the manifest). Lowercase.
        private val APP_LABELS = listOf("unchained")

        // Uninstall captions (lowercase, EN + ES). Used for the installer dialog and
        // the Play Store listing.
        private val UNINSTALL_HINTS = listOf("uninstall", "desinstalar")

        // The dangerous controls that ONLY appear on our app's App-info page: Force
        // stop and Uninstall (lowercase, EN + ES). Requiring one of these alongside
        // our app label is what pins the trigger to that single page, so the rest of
        // Settings stays freely accessible.
        private val DANGER_CONTROLS = listOf(
            "uninstall", "desinstalar",
            "force stop", "forzar detención", "forzar detencion", "forzar parada", "detener",
        )

        // System Settings across OEMs. Force stop and Uninstall both live on the
        // App-info page here; the per-OEM "security center" apps also expose an
        // app-management / uninstall surface, so guard them too. Detection still
        // keys off our app label appearing in the window, so listing extra
        // packages cannot cause a false trigger on some other app's screen.
        private val SETTINGS_PACKAGES = setOf(
            "com.android.settings",
            "com.miui.securitycenter",      // Xiaomi/MIUI
            "com.coloros.safecenter",       // Oppo/Realme/OnePlus (ColorOS)
            "com.oppo.safe",                // older ColorOS
            "com.samsung.android.sm",       // Samsung Device care
        )

        // The package installer that shows the uninstall confirmation dialog.
        private val INSTALLER_PACKAGES = setOf(
            "com.google.android.packageinstaller",
            "com.android.packageinstaller",
            "com.miui.packageinstaller",                // Xiaomi/MIUI
            "com.samsung.android.packageinstaller",     // Samsung
            "com.huawei.packageinstaller",              // Huawei/Honor
            "com.vivo.packageinstaller",                // Vivo
        )

        private val STORE_PACKAGES = setOf(
            "com.android.vending",
            "com.sec.android.app.samsungapps",          // Samsung Galaxy Store
            "com.huawei.appmarket",                     // Huawei AppGallery
            "com.xiaomi.market",                        // Xiaomi GetApps
        )
    }
}
