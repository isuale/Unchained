package com.unchained.unchained

import android.Manifest
import android.app.Activity
import android.app.admin.DevicePolicyManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.text.TextUtils
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "unchained/blocking"
    private val guardChannelName = "unchained/guard"
    private val feedGuardChannelName = "unchained/feed_guard"
    private val appLimitsChannelName = "unchained/app_limits"
    private val appsChannelName = "unchained/apps"
    private val appLockChannelName = "unchained/applock"
    private var pendingPrepareResult: MethodChannel.Result? = null

    private var guardChannel: MethodChannel? = null
    private var appLockChannel: MethodChannel? = null
    // Set when the watchdog launched us before the Flutter engine/channel was ready.
    private var pendingShowLock = false
    // The locked package that raised the prayer gate, if launched before ready.
    private var pendingPrayerPackage: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    REQ_NOTIF
                )
            }
        }
        if (intent?.getBooleanExtra(EXTRA_SHOW_LOCK, false) == true) {
            pendingShowLock = true
        }
        if (intent?.getBooleanExtra(EXTRA_SHOW_PRAYER, false) == true) {
            pendingPrayerPackage = intent?.getStringExtra(EXTRA_PRAYER_PACKAGE)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_SHOW_LOCK, false)) {
            // Engine is already up on a re-launch; deliver immediately.
            guardChannel?.invokeMethod("showLock", null) ?: run { pendingShowLock = true }
        }
        if (intent.getBooleanExtra(EXTRA_SHOW_PRAYER, false)) {
            val p = intent.getStringExtra(EXTRA_PRAYER_PACKAGE)
            appLockChannel?.invokeMethod("showPrayer", p)
                ?: run { pendingPrayerPackage = p }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "prepareVpn" -> handlePrepare(result)
                    "startBlocking" -> {
                        val intent = Intent(this, BlockingService::class.java)
                            .setAction(BlockingService.ACTION_START)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success(true)
                    }
                    "stopBlocking" -> {
                        val intent = Intent(this, BlockingService::class.java)
                            .setAction(BlockingService.ACTION_STOP)
                        startService(intent)
                        result.success(true)
                    }
                    "isRunning" -> result.success(BlockingService.isRunning)
                    "setUserLists" -> {
                        @Suppress("UNCHECKED_CAST")
                        val block = (call.argument<List<String>>("blocklist")) ?: emptyList()
                        @Suppress("UNCHECKED_CAST")
                        val allow = (call.argument<List<String>>("allowlist")) ?: emptyList()
                        BlockingService.setUserLists(applicationContext, block, allow)
                        result.success(true)
                    }
                    "getBuiltinBlocklist" -> result.success(BlockingService.builtinBlocklist())
                    "getBuiltinBlocklistCount" ->
                        result.success(BlockingService.builtinBlocklistCount(applicationContext))
                    "getBlockedHistory" -> result.success(
                        BlockingStats.history(applicationContext).map { (day, count) ->
                            mapOf("day" to day, "count" to count)
                        }
                    )
                    else -> result.notImplemented()
                }
            }

        guardChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            guardChannelName
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" -> result.success(isAccessibilityServiceEnabled())
                    "isOverlayGranted" -> result.success(Settings.canDrawOverlays(this))
                    "isGuardEnabled" -> result.success(GuardState.isEnabled(this))
                    "setGuardEnabled" -> {
                        GuardState.setEnabled(this, call.arguments as? Boolean ?: false)
                        result.success(true)
                    }
                    "openAccessibilitySettings" -> {
                        // Grace so our own deep-link to enable the service isn't re-gated.
                        GuardState.grantGrace()
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    "openOverlaySettings" -> {
                        startActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:$packageName")
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    "challengePassed" -> {
                        GuardState.grantGrace()
                        result.success(true)
                    }
                    "consumePendingLock" -> {
                        // Cold-start safety net: when the watchdog cold-launches us to
                        // show the lock, a *pushed* showLock can be lost if it fires before
                        // Dart registers its handler — leaving the user on the normal app
                        // (splash → dashboard) instead of the 800 letters. So Dart instead
                        // *pulls* this once it's ready; we report whether this launch was
                        // for the lock and clear the flag so a later normal open won't lock.
                        val launchedForLock = pendingShowLock ||
                            (intent?.getBooleanExtra(EXTRA_SHOW_LOCK, false) == true)
                        pendingShowLock = false
                        intent?.removeExtra(EXTRA_SHOW_LOCK)
                        result.success(launchedForLock)
                    }
                    "isDeviceAdminActive" -> result.success(GuardAdmin.isAdminActive(this))
                    "isDeviceOwner" -> result.success(GuardAdmin.isDeviceOwner(this))
                    "requestDeviceAdmin" -> {
                        // Grace so the watchdog doesn't fight our own deep-link into the
                        // device-admin grant screen.
                        GuardState.grantGrace()
                        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
                            .putExtra(
                                DevicePolicyManager.EXTRA_DEVICE_ADMIN,
                                UnchainedDeviceAdminReceiver.component(this),
                            )
                            .putExtra(
                                DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                                getString(R.string.device_admin_explanation),
                            )
                        // IMPORTANT: do NOT add FLAG_ACTIVITY_NEW_TASK here. The system's
                        // DeviceAdminAdd screen calls finish() immediately when it is started
                        // as a new task ("Cannot start ADD_DEVICE_ADMIN as a new task"), so the
                        // grant dialog would never appear — the button would do nothing. We are
                        // an Activity, so startActivityForResult launches it into our own task,
                        // which the screen accepts.
                        startActivityForResult(intent, REQ_DEVICE_ADMIN)
                        result.success(true)
                    }
                    "lockUninstall" -> {
                        val blocked = call.arguments as? Boolean ?: true
                        result.success(GuardAdmin.lockUninstall(this, blocked))
                    }
                    "removeDeviceAdmin" -> {
                        // Only reachable after the scripture lock is passed (disable flow).
                        GuardAdmin.removeAdmin(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, feedGuardChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" ->
                        result.success(isAccessibilityServiceEnabled(FeedGuardService::class.java))
                    "openAccessibilitySettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    "setSocialMode" -> {
                        val mode = call.argument<String>("mode") ?: "reelsAndShorts"
                        FeedGuardState.setSocialMode(this, mode)
                        result.success(true)
                    }
                    "setTargetConfig" -> {
                        val target = call.argument<String>("target")
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val limitMinutes = call.argument<Int>("limitMinutes") ?: 30
                        if (target == null || target !in FeedGuardState.TARGETS) {
                            result.success(false)
                        } else {
                            // Returns false (and leaves the old config in place) if the
                            // target is currently in its 24h exhaustion lock.
                            result.success(FeedGuardState.setConfig(this, target, enabled, limitMinutes))
                        }
                    }
                    "resetTarget" -> {
                        // DEV_TOOLS-gated on the Dart side: clears a target's
                        // usage and drops its 24h exhaustion lock. Bypasses the
                        // anti-circumvention cooldown on purpose, for testing.
                        val target = call.argument<String>("target")
                        if (target == null || target !in FeedGuardState.TARGETS) {
                            result.success(false)
                        } else {
                            FeedGuardState.resetTarget(this, target)
                            result.success(true)
                        }
                    }
                    "getStatuses" -> {
                        val statuses = FeedGuardState.TARGETS.associateWith { target ->
                            mapOf(
                                "usedSeconds" to FeedGuardState.usedSeconds(this, target),
                                "remainingSeconds" to FeedGuardState.remainingSeconds(this, target),
                                "lockedUntilMillis" to FeedGuardState.lockedUntilMillis(this, target),
                            )
                        }
                        result.success(statuses)
                    }
                    "getHistory" -> {
                        val history = FeedGuardState.TARGETS.associateWith { target ->
                            FeedGuardState.history(this, target).map { (day, usedSeconds) ->
                                mapOf("day" to day, "usedSeconds" to usedSeconds)
                            }
                        }
                        result.success(history)
                    }
                    else -> result.notImplemented()
                }
            }

        // "App Time Limits": any user-picked app, each with its own daily minute
        // budget. Reuses FeedGuardState/FeedGuardService (the same watchdog that
        // powers Reels/Shorts/TikTok/Snapchat) keyed by package name instead of a
        // fixed target key — see FeedGuardState's class doc.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appLimitsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAccessibilityEnabled" ->
                        result.success(isAccessibilityServiceEnabled(FeedGuardService::class.java))
                    "openAccessibilitySettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        )
                        result.success(true)
                    }
                    "setAppLimitConfig" -> {
                        val pkg = call.argument<String>("package")
                        val label = call.argument<String>("label")
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val limitMinutes = call.argument<Int>("limitMinutes") ?: 30
                        if (pkg == null || label == null) {
                            result.success(false)
                        } else {
                            result.success(
                                FeedGuardState.setAppLimitConfig(this, pkg, label, enabled, limitMinutes)
                            )
                        }
                    }
                    "removeAppLimit" -> {
                        val pkg = call.argument<String>("package")
                        if (pkg == null) {
                            result.success(false)
                        } else {
                            FeedGuardState.removeAppLimit(this, pkg)
                            result.success(true)
                        }
                    }
                    "resetAppLimit" -> {
                        // DEV_TOOLS-gated on the Dart side, mirrors feed_guard's resetTarget.
                        val pkg = call.argument<String>("package")
                        if (pkg == null) {
                            result.success(false)
                        } else {
                            FeedGuardState.resetTarget(this, pkg)
                            result.success(true)
                        }
                    }
                    "getStatuses" -> {
                        val packages = FeedGuardState.appLimitPackages(this)
                        val statuses = packages.associateWith { pkg ->
                            mapOf(
                                "usedSeconds" to FeedGuardState.usedSeconds(this, pkg),
                                "remainingSeconds" to FeedGuardState.remainingSeconds(this, pkg),
                                "lockedUntilMillis" to FeedGuardState.lockedUntilMillis(this, pkg),
                            )
                        }
                        result.success(statuses)
                    }
                    "getHistory" -> {
                        val packages = FeedGuardState.appLimitPackages(this)
                        val history = packages.associateWith { pkg ->
                            FeedGuardState.history(this, pkg).map { (day, usedSeconds) ->
                                mapOf("day" to day, "usedSeconds" to usedSeconds)
                            }
                        }
                        result.success(history)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, appsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInstalledApps" -> {
                        // Enumerating + rendering every launcher icon is too heavy
                        // for the main thread; do it on a background thread and post
                        // the reply back on the main looper (MethodChannel requires
                        // result callbacks on the platform thread).
                        Thread {
                            val apps = try {
                                InstalledApps.list(applicationContext)
                            } catch (e: Exception) {
                                emptyList()
                            }
                            runOnUiThread { result.success(apps) }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }

        appLockChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            appLockChannelName
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "setConfig" -> {
                        // Absent "enabled" means an older Dart side that predates the
                        // master switch — treat it as on, matching AppLockState's default.
                        val enabled = call.argument<Boolean>("enabled") ?: true
                        val lockAll = call.argument<Boolean>("lockAll") ?: false
                        val pkgs = call.argument<List<String>>("packages") ?: emptyList()
                        AppLockState.setConfig(
                            applicationContext, enabled, lockAll, pkgs.toSet()
                        )
                        result.success(true)
                    }
                    "openUnlockWindow" -> {
                        val hours = call.argument<Int>("hours") ?: 24
                        AppLockState.openUnlockWindow(applicationContext, hours)
                        result.success(true)
                    }
                    "consumePendingPrayer" -> {
                        // Cold-start safety net, mirroring consumePendingLock: if the
                        // watchdog cold-launched us to pray, report the package once and
                        // clear the intent extra so a later normal open won't re-trigger.
                        val p = pendingPrayerPackage
                            ?: if (intent?.getBooleanExtra(EXTRA_SHOW_PRAYER, false) == true) {
                                intent?.getStringExtra(EXTRA_PRAYER_PACKAGE)
                            } else {
                                null
                            }
                        pendingPrayerPackage = null
                        intent?.removeExtra(EXTRA_SHOW_PRAYER)
                        result.success(p)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        if (pendingShowLock) {
            pendingShowLock = false
            guardChannel?.invokeMethod("showLock", null)
        }
        pendingPrayerPackage?.let { p ->
            pendingPrayerPackage = null
            appLockChannel?.invokeMethod("showPrayer", p)
        }
    }

    /** Whether our [UninstallGuardService] is currently enabled in system settings. */
    private fun isAccessibilityServiceEnabled(): Boolean =
        isAccessibilityServiceEnabled(UninstallGuardService::class.java)

    /** Whether the given accessibility service class is currently enabled in system settings. */
    private fun isAccessibilityServiceEnabled(serviceClass: Class<*>): Boolean {
        val expected = "$packageName/${serviceClass.name}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val splitter = TextUtils.SimpleStringSplitter(':')
        splitter.setString(enabledServices)
        for (service in splitter) {
            if (service.equals(expected, ignoreCase = true)) return true
        }
        return false
    }

    private fun handlePrepare(result: MethodChannel.Result) {
        if (pendingPrepareResult != null) {
            result.success(false)
            return
        }
        val intent = VpnService.prepare(this)
        if (intent == null) {
            result.success(true)
        } else {
            pendingPrepareResult = result
            startActivityForResult(intent, REQ_VPN)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_VPN) {
            val granted = resultCode == Activity.RESULT_OK
            pendingPrepareResult?.success(granted)
            pendingPrepareResult = null
        } else if (requestCode == REQ_DEVICE_ADMIN) {
            // Returned from the device-admin grant screen. Keep the watchdog standing
            // down a moment longer (the window transition back to us can still surface
            // the Settings page), and, if we are device owner, clamp the OS-level block.
            GuardState.grantGrace()
            if (resultCode == Activity.RESULT_OK && GuardState.isEnabled(this)) {
                GuardAdmin.lockUninstall(this, true)
            }
        }
    }

    companion object {
        const val EXTRA_SHOW_LOCK = "com.unchained.unchained.SHOW_LOCK"
        const val EXTRA_SHOW_PRAYER = "com.unchained.unchained.SHOW_PRAYER"
        const val EXTRA_PRAYER_PACKAGE = "com.unchained.unchained.PRAYER_PACKAGE"
        private const val REQ_VPN = 7001
        private const val REQ_NOTIF = 7002
        private const val REQ_DEVICE_ADMIN = 7003
    }
}
