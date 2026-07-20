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
import io.flutter.plugins.GeneratedPluginRegistrant

import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import net.sf.sevenzipjbinding.SevenZip
import net.sf.sevenzipjbinding.IInArchive
import net.sf.sevenzipjbinding.impl.RandomAccessFileInStream
import net.sf.sevenzipjbinding.simple.ISimpleInArchive
import net.sf.sevenzipjbinding.simple.ISimpleInArchiveItem
import net.sf.sevenzipjbinding.ExtractOperationResult

import net.sf.sevenzipjbinding.IArchiveExtractCallback
import net.sf.sevenzipjbinding.ISequentialOutStream
import net.sf.sevenzipjbinding.ExtractAskMode
import net.sf.sevenzipjbinding.PropID
import net.sf.sevenzipjbinding.SevenZipException

class MainActivity : FlutterActivity() {
    private val channelName = "com.chanomhub.chanolite/download_notifications"
    private val extractorChannelName = "com.chanomhub.chanolite/native_extractor"
    private val notificationChannelId = "download_notifications_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, extractorChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "extractArchive" -> {
                        val archivePath = call.argument<String>("archivePath")
                        val destPath = call.argument<String>("destPath")
                        if (archivePath.isNullOrEmpty() || destPath.isNullOrEmpty()) {
                            result.error("INVALID_ARGUMENTS", "Missing archivePath or destPath", null)
                        } else {
                            // Extract in background thread to avoid blocking UI
                            Thread {
                                try {
                                    val success = extractArchive(this, archivePath, destPath)
                                    runOnUiThread {
                                        if (success) {
                                            result.success(true)
                                        } else {
                                            result.error("EXTRACTION_FAILED", "Failed to extract archive", null)
                                        }
                                    }
                                } catch (e: Exception) {
                                    runOnUiThread {
                                        result.error("EXTRACTION_ERROR", e.message, null)
                                    }
                                }
                            }.start()
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun extractArchive(context: Context, archivePath: String, destPath: String): Boolean {
        var randomAccessFile: RandomAccessFile? = null
        var inArchive: IInArchive? = null
        try {
            // Initialize 7-Zip JBinding
            SevenZip.initSevenZipFromPlatformJAR(context.cacheDir)

            val archiveFile = File(archivePath)
            val destDir = File(destPath)
            if (!destDir.exists()) {
                destDir.mkdirs()
            }

            randomAccessFile = RandomAccessFile(archiveFile, "r")
            inArchive = SevenZip.openInArchive(null, RandomAccessFileInStream(randomAccessFile))

            val callback = ExtractCallback(inArchive, destDir) { progress, fileName ->
                runOnUiThread {
                    MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, extractorChannelName)
                        .invokeMethod("onProgress", mapOf(
                            "progress" to progress,
                            "fileName" to fileName
                        ))
                }
            }
            inArchive.extract(null, false, callback)
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        } finally {
            try {
                inArchive?.close()
            } catch (ignored: Exception) {}
            try {
                randomAccessFile?.close()
            } catch (ignored: Exception) {}
        }
    }

    private class ExtractCallback(
        private val inArchive: IInArchive,
        private val destDir: File,
        private val onProgress: (Int, String) -> Unit
    ) : IArchiveExtractCallback {
        private var currentOutStream: FileOutputStream? = null
        private val totalItems = inArchive.numberOfItems

        override fun getStream(index: Int, extractAskMode: ExtractAskMode): ISequentialOutStream? {
            if (extractAskMode != ExtractAskMode.EXTRACT) {
                return null
            }

            val isFolder = inArchive.getProperty(index, PropID.IS_FOLDER) as? Boolean ?: false
            val path = inArchive.getProperty(index, PropID.PATH) as? String ?: return null
            val destFile = File(destDir, path)

            val progressPercent = ((index + 1) * 100) / totalItems
            onProgress(progressPercent, path)

            if (isFolder) {
                destFile.mkdirs()
                return null
            }

            destFile.parentFile?.mkdirs()

            try {
                currentOutStream?.close()
            } catch (ignored: Exception) {}

            val fos = FileOutputStream(destFile)
            currentOutStream = fos

            return ISequentialOutStream { data ->
                fos.write(data)
                data.size
            }
        }

        override fun prepareOperation(extractAskMode: ExtractAskMode) {}

        override fun setOperationResult(extractOperationResult: ExtractOperationResult) {
            try {
                currentOutStream?.close()
            } catch (ignored: Exception) {}
            currentOutStream = null
        }

        override fun setTotal(total: Long) {}

        override fun setCompleted(completeValue: Long) {}
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
