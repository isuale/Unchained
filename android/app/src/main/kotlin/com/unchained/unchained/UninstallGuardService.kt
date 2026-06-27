package com.unchained.unchained

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo

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
        if (!GuardState.isEnabled(this)) return

        val type = event.eventType
        if (type != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            type != AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        ) {
            return
        }

        val pkg = event.packageName?.toString() ?: return
        // Never react to ourselves (the lock screen itself, or our setup deep-links).
        if (pkg == packageName) return

        val watched = pkg in SETTINGS_PACKAGES || pkg in INSTALLER_PACKAGES || pkg in STORE_PACKAGES
        if (watched) Log.d(TAG, "watched window pkg=$pkg type=$type")

        val now = SystemClock.elapsedRealtime()
        // The user just passed the challenge — let them through their grace window.
        if (now < GuardState.graceUntilElapsed) return
        // Debounce: one window can fire many content-changed events in a row.
        if (now - lastTriggerElapsed < TRIGGER_DEBOUNCE_MS) return

        val door = when {
            pkg in SETTINGS_PACKAGES -> isOurAppOrAccessibilityScreen(event)
            pkg in INSTALLER_PACKAGES -> mentionsUs(event)
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
     * True when the active Settings window is our app's **App info** page or the
     * **Accessibility** detail page for our app — both prominently show "Unchained".
     */
    private fun isOurAppOrAccessibilityScreen(event: AccessibilityEvent): Boolean =
        mentionsUs(event)

    /** Play Store listing for us: our name is present alongside an uninstall control. */
    private fun isOurStoreListing(event: AccessibilityEvent): Boolean =
        screenContains(event, APP_LABELS) && screenContains(event, UNINSTALL_HINTS)

    /** Our app label appears somewhere on the current screen. */
    private fun mentionsUs(event: AccessibilityEvent): Boolean =
        screenContains(event, APP_LABELS)

    /**
     * Whether any of [needles] appears anywhere the user can currently see.
     *
     * We deliberately do *not* trust [rootInActiveWindow] alone: during the window
     * transition into Force-stop / Uninstall, or when a confirm dialog is layered over
     * Settings, the "active" window can momentarily be systemui or a stale node and the
     * dangerous screen would slip past. So we look in three places and trigger if *any*
     * of them mentions us: the event's own source node, the active window, and every
     * interactive window the service can enumerate.
     */
    private fun screenContains(event: AccessibilityEvent, needles: List<String>): Boolean {
        // 1) The node that fired this event.
        event.source?.let { src ->
            try {
                if (nodeTreeContains(src, needles)) return true
            } finally {
                src.recycle()
            }
        }
        // 2) The current active window.
        rootInActiveWindow?.let { root ->
            try {
                if (nodeTreeContains(root, needles)) return true
            } finally {
                root.recycle()
            }
        }
        // 3) Every window the service can see (covers transitions / layered dialogs).
        val all: List<AccessibilityWindowInfo> = try {
            windows ?: emptyList()
        } catch (_: Exception) {
            emptyList()
        }
        for (w in all) {
            val root = w.root ?: continue
            try {
                if (nodeTreeContains(root, needles)) return true
            } finally {
                root.recycle()
            }
        }
        return false
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

        private var lastTriggerElapsed = 0L

        // Our user-visible label (see android:label in the manifest). Lowercase.
        private val APP_LABELS = listOf("unchained")

        // Localised-but-common uninstall captions, lowercase. Used only to harden the
        // Play Store heuristic; App-info / installer detection keys off the app label.
        private val UNINSTALL_HINTS = listOf("uninstall", "desinstalar")

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
