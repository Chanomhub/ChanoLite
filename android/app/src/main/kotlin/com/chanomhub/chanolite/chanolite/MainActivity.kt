package com.chanomhub.chanolite.chanolite

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.chanomhub.chanolite/download_notifications"
    private val notificationChannelId = "download_notifications_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        createNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "notifyDownloadStarted" -> {
                        val fileName = call.argument<String>("fileName")
                        if (fileName.isNullOrEmpty()) {
                            result.error("INVALID_ARGUMENTS", "Missing fileName", null)
                        } else {
                            showNotification(fileName)
                            result.success(null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                notificationChannelId,
                "Download Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            channel.description = "Notifications for game downloads"

            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun showNotification(fileName: String) {
        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle("Download Started")
            .setContentText("Starting download for $fileName")
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .build()

        NotificationManagerCompat.from(this).notify(fileName.hashCode(), notification)
    }
}
