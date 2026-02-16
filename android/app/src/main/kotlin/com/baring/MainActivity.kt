package com.baring

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.baring/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAppSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:${packageName}")
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "checkPermissions" -> {
                    val camera = ContextCompat.checkSelfPermission(
                        this, Manifest.permission.CAMERA
                    ) == PackageManager.PERMISSION_GRANTED

                    val notification = NotificationManagerCompat.from(this).areNotificationsEnabled()

                    val calendar = ContextCompat.checkSelfPermission(
                        this, Manifest.permission.READ_CALENDAR
                    ) == PackageManager.PERMISSION_GRANTED

                    result.success(mapOf(
                        "camera" to camera,
                        "notification" to notification,
                        "calendar" to calendar
                    ))
                }
                else -> result.notImplemented()
            }
        }
    }
}
