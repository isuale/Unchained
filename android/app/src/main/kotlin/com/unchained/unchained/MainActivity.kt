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
    private var pendingPrepareResult: MethodChannel.Result? = null

    private var guardChannel: MethodChannel? = null
    // Set when the watchdog launched us before the Flutter engine/channel was ready.
    private var pendingShowLock = false

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
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.getBooleanExtra(EXTRA_SHOW_LOCK, false)) {
            // Engine is already up on a re-launch; deliver immediately.
            guardChannel?.invokeMethod("showLock", null) ?: run { pendingShowLock = true }
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

        if (pendingShowLock) {
            pendingShowLock = false
            guardChannel?.invokeMethod("showLock", null)
        }
    }

    /** Whether our [UninstallGuardService] is currently enabled in system settings. */
    private fun isAccessibilityServiceEnabled(): Boolean {
        val expected = "$packageName/${UninstallGuardService::class.java.name}"
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
        private const val REQ_VPN = 7001
        private const val REQ_NOTIF = 7002
        private const val REQ_DEVICE_ADMIN = 7003
    }
}
