package com.deen.adkhar

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val serviceIntent = Intent(context, AdhanPlaybackService::class.java).apply {
            action = AdhanPlaybackService.ACTION_PLAY
            putExtra(
                AdhanAlarmScheduler.EXTRA_ID,
                intent.getIntExtra(AdhanAlarmScheduler.EXTRA_ID, 0)
            )
            putExtra(
                AdhanAlarmScheduler.EXTRA_PRAYER_NAME,
                intent.getStringExtra(AdhanAlarmScheduler.EXTRA_PRAYER_NAME) ?: "Prayer"
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
