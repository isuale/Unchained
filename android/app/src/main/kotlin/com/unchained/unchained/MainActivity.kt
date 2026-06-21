package com.unchained.unchained

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.VpnService
import android.os.Build
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "unchained/blocking"
    private var pendingPrepareResult: MethodChannel.Result? = null

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
                    else -> result.notImplemented()
                }
            }
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
        }
    }

    companion object {
        private const val REQ_VPN = 7001
        private const val REQ_NOTIF = 7002
    }
}
