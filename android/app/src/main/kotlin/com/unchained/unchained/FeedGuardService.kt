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
 * Daily time-budget watchdog for short-video/story feeds (Instagram Reels,
 * YouTube Shorts, TikTok, Snapchat Stories) AND, more generally, for the
 * "App Time Limits" feature — any other app the user picks, each with its
 * own daily minute budget. The four feeds above are baked in with their own
 * detection quirks (see below); a user-picked app is always tracked as a
 * whole-app timer, keyed by its own package name (see [FeedGuardState] for
 * how that dynamic package set is tracked) rather than a fixed target key.
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
 * just bounces the user straight back out. [FeedGuardState] then holds that
 * target locked for a full 24 hours from the moment it was exhausted (not
 * just until local midnight, and not editable in the meantime) before handing
 * back a fresh budget.
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
            diagLog(target) { "pkg=$pkg target=$target NOT ENABLED (config never reached native)" }
            stopTracking()
            return
        }

        val matched = if (needsSubScreenMatch(target)) {
            activeScreenMatches(event, needlesFor(target))
        } else {
            true
        }

        if (!matched) {
            diagLog(target) {
                "pkg=$pkg target=$target enabled but NOT MATCHED. " +
                    "Looking for ${needlesFor(target)}. ${sampleSignals(event)}"
            }
            if (activeTarget == target) stopTracking()
            return
        }
        Log.d(TAG, "pkg=$pkg target=$target MATCHED, tracking")

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
        val stillThere = if (needsSubScreenMatch(target)) {
            rootInActiveWindow?.let { root ->
                try {
                    nodeTreeMatches(root, needlesFor(target))
                } finally {
                    root.recycle()
                }
            } ?: false
        } else {
            lastForegroundPackage?.let { targetForPackage(it) == target } == true
        }
        if (!stillThere) {
            Log.d(TAG, "tick: $target no longer on screen, stop tracking")
            stopTracking()
            return
        }
        val used = FeedGuardState.addUsedSeconds(this, target, 1)
        if (used % 10 == 0) Log.d(TAG, "tick: $target used=${used}s")
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
                "${friendlyName(target)} — daily limit reached. Locked for 24 hours.",
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

    /** Whether the event's own window (or the active window) has a node matching any
     * of [needles]. Mirrors [UninstallGuardService.activeScreenContains]. */
    private fun activeScreenMatches(event: AccessibilityEvent, needles: List<String>): Boolean {
        event.source?.let { src ->
            try {
                if (nodeTreeMatches(src, needles)) return true
            } finally {
                src.recycle()
            }
        }
        rootInActiveWindow?.let { root ->
            try {
                if (nodeTreeMatches(root, needles)) return true
            } finally {
                root.recycle()
            }
        }
        return false
    }

    /** True if any node in the tree has a resource-id, content-description, or text
     * containing one of [needles]. Instagram Reels exposes its only stable signal as a
     * content-description ("Reel by <user>. Double tap…"), not a resource-id — so
     * id-only matching (which is enough for YouTube Shorts) misses it entirely. */
    private fun nodeTreeMatches(
        node: AccessibilityNodeInfo?,
        needles: List<String>,
        depth: Int = 0,
    ): Boolean {
        if (node == null || depth > MAX_DEPTH) return false
        val id = node.viewIdResourceName
        if (id != null && needles.any { id.contains(it) }) return true
        val desc = node.contentDescription?.toString()
        if (desc != null && needles.any { desc.contains(it) }) return true
        val text = node.text?.toString()
        if (text != null && needles.any { text.contains(it) }) return true
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            val hit = nodeTreeMatches(child, needles, depth + 1)
            child?.recycle()
            if (hit) return true
        }
        return false
    }

    /** Diagnostic-only: collects up to [DIAG_MAX_IDS] distinct resource ids, on-screen
     * texts, and content-descriptions visible in the active window. Instagram Reels was
     * found to strip resource-ids almost entirely (only `search_row`/`ig_text` leak out),
     * so we also sample text + content-description — the labels a screen-reader would
     * announce — to find a stable signal for the Reels player. Read straight out of
     * logcat instead of guessed at. */
    private fun sampleSignals(event: AccessibilityEvent): String {
        val ids = LinkedHashSet<String>()
        val texts = LinkedHashSet<String>()
        val descs = LinkedHashSet<String>()
        fun collect(node: AccessibilityNodeInfo?, depth: Int) {
            if (node == null || depth > 14) return
            if (ids.size < DIAG_MAX_IDS) node.viewIdResourceName?.let { ids.add(it) }
            if (texts.size < DIAG_MAX_IDS) {
                node.text?.toString()?.trim()?.takeIf { it.isNotEmpty() }?.let { texts.add(it.take(32)) }
            }
            if (descs.size < DIAG_MAX_IDS) {
                node.contentDescription?.toString()?.trim()?.takeIf { it.isNotEmpty() }?.let { descs.add(it.take(32)) }
            }
            for (i in 0 until node.childCount) {
                val child = node.getChild(i)
                collect(child, depth + 1)
                child?.recycle()
            }
        }
        rootInActiveWindow?.let { root ->
            try {
                collect(root, 0)
            } finally {
                root.recycle()
            }
        }
        return "ids=$ids | texts=$texts | descs=$descs"
    }

    private val lastDiagLogElapsed = HashMap<String, Long>()

    /** Throttles a diagnostic log line to once every [DIAG_THROTTLE_MS] per target,
     * so scrolling through Instagram/YouTube doesn't flood logcat. */
    private inline fun diagLog(target: String, message: () -> String) {
        val now = SystemClock.elapsedRealtime()
        val last = lastDiagLogElapsed[target] ?: 0L
        if (now - last < DIAG_THROTTLE_MS) return
        lastDiagLogElapsed[target] = now
        Log.d(TAG, message())
    }

    /** Fixed feeds first; falls back to a user-picked App Time Limits package,
     * whose target key is simply the package name itself. */
    private fun targetForPackage(pkg: String): String? =
        TARGET_PACKAGES.entries.firstOrNull { pkg in it.value }?.key
            ?: pkg.takeIf { FeedGuardState.appLimitPackages(this).contains(it) }

    /** Only Reels/Shorts need a sub-screen match; every other target (the two
     * whole-app feeds plus every user-picked App Time Limits package) is
     * satisfied by foreground presence alone. */
    private fun needsSubScreenMatch(target: String): Boolean =
        target == "blockReels" || target == "blockShorts"

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
        else -> FeedGuardState.label(this, target) ?: target
    }

    companion object {
        private const val TAG = "UnchainedFeedGuard"
        private const val TICK_MS = 1000L
        private const val MAX_DEPTH = 40
        // Guards against re-firing the BACK action on every content-changed event
        // that arrives while the exhausted screen is still settling off-screen.
        private const val KICK_DEBOUNCE_MS = 1200L
        // Diagnostic-only throttles (see diagLog/sampleResourceIds).
        private const val DIAG_THROTTLE_MS = 3000L
        private const val DIAG_MAX_IDS = 60

        // Signals observed to appear only while the Reels/Shorts player itself is
        // showing. Undocumented by Meta/Google; may drift across app versions.
        // Instagram strips resource-ids on Reels (only search_row/ig_text leak out),
        // but every reel carries a content-description "Reel by <user>. Double tap…"
        // whose username tracks the visible reel — confirmed from on-device
        // diagnostics. "clips_viewer" is kept as a fallback for builds that still
        // expose it. NOTE: "Reel by " is English; if Instagram's own language is
        // changed, this needle must be localized too.
        private val REELS_NEEDLES = listOf("Reel by ", "clips_viewer")
        // YouTube (like Instagram) exposes NO resource-ids on the Shorts player
        // (on-device diagnostics show ids=[] the whole time), so the old
        // reel_recycler/reel_player_page_container ids never matched. It does
        // expose stable content-descriptions unique to the Shorts player: the
        // sound pivot "See more videos using this sound" (present on every Short)
        // and the remix action "Remix this Short along with …". Both are matched
        // as substrings by nodeTreeMatches. Deliberately NOT the bare nav word
        // "Shorts", which sits in the bottom nav bar on every YouTube screen and
        // would false-positive across the whole app. NOTE: these are English; if
        // YouTube's language is changed, they must be localized too.
        private val SHORTS_NEEDLES = listOf(
            "See more videos using this sound",
            "Remix this Short",
        )

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
