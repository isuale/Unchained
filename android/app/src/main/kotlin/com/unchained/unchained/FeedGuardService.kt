package com.unchained.unchained

import android.accessibilityservice.AccessibilityService
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast

/**
 * Daily time-budget watchdog for short-video/story feeds: Instagram Reels,
 * YouTube Shorts, TikTok and Snapchat Stories.
 *
 * Android's DNS-based VPN blocking (see [BlockingService]) can only block or
 * allow a whole domain, so it can't tell "Instagram" apart from "Instagram
 * Reels" — both hit the same hosts. Enforcing a feed-specific limit instead
 * requires watching the foreground screen the same way [UninstallGuardService]
 * does: as an AccessibilityService inspecting the active window's node tree.
 *
 * Two different detection strategies are used, because the four targets
 * aren't equally inspectable:
 *  - Instagram Reels / YouTube Shorts: the app has plenty of other legitimate
 *    uses (DMs, search, subscriptions...), so we look for a stable resource-id
 *    substring that only appears while the Reels/Shorts *player* itself is on
 *    screen (`clips_viewer` / `reel_recycler` / `reel_player_page_container`).
 *    These ids are undocumented and can drift across app versions/regions.
 *  - TikTok / Snapchat Stories: TikTok's entire app is essentially one
 *    continuous feed, and Snapchat's Stories/camera UI is largely
 *    GL-rendered and doesn't reliably expose text to the accessibility tree.
 *    Both are treated as a whole-app timer instead of a sub-screen match.
 *
 * Time is tracked with a self-rescheduling 1-second [Handler] tick while a
 * target is active, rather than off event timestamps, since accessibility
 * events don't fire at a steady rate. Once a target's daily budget (persisted
 * in [FeedGuardState]) is used up, every further detection of that target
 * immediately backs out via [performGlobalAction] — so re-opening the feed
 * just bounces the user straight back out for the rest of the day.
 */
class FeedGuardService : AccessibilityService() {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var lastForegroundPackage: String? = null
    private var activeTarget: String? = null
    private var lastKickElapsed = 0L
    private val tickRunnable = object : Runnable {
        override fun run() {
            tick()
            mainHandler.postDelayed(this, TICK_MS)
        }
    }
    private var ticking = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "feed guard connected")
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
        lastForegroundPackage = pkg

        val target = targetForPackage(pkg) ?: run { stopTracking(); return }
        if (!FeedGuardState.isEnabled(this, target)) {
            stopTracking()
            return
        }

        val matched = if (target in WHOLE_APP_TARGETS) {
            true
        } else {
            activeScreenHasResourceId(event, needlesFor(target))
        }

        if (!matched) {
            if (activeTarget == target) stopTracking()
            return
        }

        if (activeTarget != target) {
            activeTarget = target
            startTicking()
        }
        enforceBudget(target)
    }

    override fun onInterrupt() {}

    /** One-second heartbeat: keep counting only while the tracked target is still on screen. */
    private fun tick() {
        val target = activeTarget ?: return
        val stillThere = if (target in WHOLE_APP_TARGETS) {
            lastForegroundPackage?.let { targetForPackage(it) == target } == true
        } else {
            rootInActiveWindow?.let { root ->
                try {
                    nodeTreeHasResourceId(root, needlesFor(target))
                } finally {
                    root.recycle()
                }
            } ?: false
        }
        if (!stillThere) {
            stopTracking()
            return
        }
        FeedGuardState.addUsedSeconds(this, target, 1)
        enforceBudget(target)
    }

    private fun enforceBudget(target: String) {
        if (!FeedGuardState.isBudgetExhausted(this, target)) return
        val now = SystemClock.elapsedRealtime()
        if (now - lastKickElapsed < KICK_DEBOUNCE_MS) return
        lastKickElapsed = now
        Log.d(TAG, "budget exhausted for $target, backing out")
        performGlobalAction(GLOBAL_ACTION_BACK)
        mainHandler.post {
            Toast.makeText(
                applicationContext,
                "${friendlyName(target)} — daily limit reached",
                Toast.LENGTH_SHORT,
            ).show()
        }
        stopTracking()
    }

    private fun startTicking() {
        if (ticking) return
        ticking = true
        mainHandler.postDelayed(tickRunnable, TICK_MS)
    }

    private fun stopTracking() {
        activeTarget = null
        if (ticking) {
            ticking = false
            mainHandler.removeCallbacks(tickRunnable)
        }
    }

    /** Whether the event's own window (or the active window) has a node whose
     * resource id contains any of [needles]. Mirrors
     * [UninstallGuardService.activeScreenContains], but matches resource ids
     * instead of text/content-description. */
    private fun activeScreenHasResourceId(event: AccessibilityEvent, needles: List<String>): Boolean {
        event.source?.let { src ->
            try {
                if (nodeTreeHasResourceId(src, needles)) return true
            } finally {
                src.recycle()
            }
        }
        rootInActiveWindow?.let { root ->
            try {
                if (nodeTreeHasResourceId(root, needles)) return true
            } finally {
                root.recycle()
            }
        }
        return false
    }

    private fun nodeTreeHasResourceId(
        node: AccessibilityNodeInfo?,
        needles: List<String>,
        depth: Int = 0,
    ): Boolean {
        if (node == null || depth > MAX_DEPTH) return false
        val id = node.viewIdResourceName
        if (id != null && needles.any { id.contains(it) }) return true
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val hit = nodeTreeHasResourceId(child, needles, depth + 1)
            child?.recycle()
            if (hit) return true
        }
        return false
    }

    private fun targetForPackage(pkg: String): String? =
        TARGET_PACKAGES.entries.firstOrNull { pkg in it.value }?.key

    private fun needlesFor(target: String): List<String> = when (target) {
        "blockReels" -> REELS_NEEDLES
        "blockShorts" -> SHORTS_NEEDLES
        else -> emptyList()
    }

    private fun friendlyName(target: String): String = when (target) {
        "blockReels" -> "Instagram Reels"
        "blockShorts" -> "YouTube Shorts"
        "blockTikTok" -> "TikTok"
        "blockSnapchatStories" -> "Snapchat Stories"
        else -> target
    }

    companion object {
        private const val TAG = "UnchainedFeedGuard"
        private const val TICK_MS = 1000L
        private const val MAX_DEPTH = 40
        // Guards against re-firing the BACK action on every content-changed event
        // that arrives while the exhausted screen is still settling off-screen.
        private const val KICK_DEBOUNCE_MS = 1200L

        // Resource-id substrings observed (by multiple independent open-source
        // app-blockers) to appear only while the Reels/Shorts player itself is
        // showing. Undocumented by Meta/Google; may drift across app versions.
        private val REELS_NEEDLES = listOf("clips_viewer")
        private val SHORTS_NEEDLES = listOf("reel_recycler", "reel_player_page_container")

        private val WHOLE_APP_TARGETS = setOf("blockTikTok", "blockSnapchatStories")

        private val TARGET_PACKAGES: Map<String, Set<String>> = mapOf(
            "blockReels" to setOf("com.instagram.android"),
            "blockShorts" to setOf(
                "com.google.android.youtube",
                "app.revanced.android.youtube",
            ),
            "blockTikTok" to setOf(
                "com.zhiliaoapp.musically",
                "com.ss.android.ugc.trill",
            ),
            "blockSnapchatStories" to setOf("com.snapchat.android"),
        )
    }
}
