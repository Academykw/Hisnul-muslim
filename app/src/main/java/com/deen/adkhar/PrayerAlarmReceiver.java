package com.deen.adkhar;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

public class PrayerAlarmReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        String prayerName = intent.getStringExtra(PrayerTimesScheduler.EXTRA_PRAYER_NAME);
        int notificationId = intent.getIntExtra(PrayerTimesScheduler.EXTRA_NOTIFICATION_ID, 1001);

        Intent serviceIntent = new Intent(context, PrayerAdhanService.class);
        serviceIntent.putExtra(PrayerTimesScheduler.EXTRA_PRAYER_NAME, prayerName);
        serviceIntent.putExtra(PrayerTimesScheduler.EXTRA_NOTIFICATION_ID, notificationId);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent);
        } else {
            context.startService(serviceIntent);
        }
    }
}
