package com.deen.adkhar

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder

class AdhanPlaybackService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var currentNotificationId = NOTIFICATION_ID

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopPlayback()
                return START_NOT_STICKY
            }
            ACTION_PLAY -> {
                val prayerName = intent.getStringExtra(AdhanAlarmScheduler.EXTRA_PRAYER_NAME)
                    ?: "Prayer"
                val prayerId = intent.getIntExtra(AdhanAlarmScheduler.EXTRA_ID, 0)
                currentNotificationId = NOTIFICATION_ID + prayerId
                startForeground(currentNotificationId, buildNotification(prayerName))
                playAdhan()
                return START_NOT_STICKY
            }
        }

        stopSelf()
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        stopPlayerOnly()
        super.onDestroy()
    }

    private fun playAdhan() {
        stopPlayerOnly()

        val audioFile = resources.openRawResourceFd(R.raw.azan1)
        mediaPlayer = MediaPlayer().apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
            } else {
                @Suppress("DEPRECATION")
                setAudioStreamType(AudioManager.STREAM_ALARM)
            }

            setDataSource(audioFile.fileDescriptor, audioFile.startOffset, audioFile.length)
            audioFile.close()
            prepare()
            isLooping = false
            setOnCompletionListener {
                stopPlayback()
            }
            setOnErrorListener { _, _, _ ->
                stopPlayback()
                true
            }
            start()
        }
    }

    private fun stopPlayback() {
        stopPlayerOnly()
        stopForegroundCompat()
        stopSelf()
    }

    private fun stopPlayerOnly() {
        mediaPlayer?.setOnCompletionListener(null)
        mediaPlayer?.setOnErrorListener(null)
        mediaPlayer?.stopSafely()
        mediaPlayer?.release()
        mediaPlayer = null
    }

    private fun buildNotification(prayerName: String): Notification {
        ensureNotificationChannel()

        val stopIntent = Intent(this, AdhanPlaybackService::class.java).apply {
            action = ACTION_STOP
        }
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        val stopPendingIntent = PendingIntent.getService(this, 0, stopIntent, flags)

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val launchPendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(this, 1, launchIntent, flags)
        } else {
            null
        }

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        @Suppress("DEPRECATION")
        return builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Prayer Time")
            .setContentText("Adhan is playing for $prayerName")
            .setPriority(Notification.PRIORITY_MAX)
            .setCategory(Notification.CATEGORY_ALARM)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(launchPendingIntent)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPendingIntent)
            .build()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Active Adhan",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Controls full adhan playback"
            setSound(null, null)
        }

        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(channel)
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }

    companion object {
        const val ACTION_PLAY = "com.deen.adkhar.action.PLAY_ADHAN"
        const val ACTION_STOP = "com.deen.adkhar.action.STOP_ADHAN"

        private const val CHANNEL_ID = "native_active_adhan_v1"
        private const val NOTIFICATION_ID = 5000

        fun stop(context: Context) {
            val intent = Intent(context, AdhanPlaybackService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }
    }
}

private fun MediaPlayer.stopSafely() {
    try {
        stop()
    } catch (_: IllegalStateException) {
    }
}

private fun immutableFlag(): Int {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        PendingIntent.FLAG_IMMUTABLE
    } else {
        0
    }
}
