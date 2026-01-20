package com.deen.adkhar;

import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

public class PrayerCancelReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        int notificationId = intent.getIntExtra(PrayerTimesScheduler.EXTRA_NOTIFICATION_ID, -1);
        if (notificationId == -1) {
            return;
        }
        context.stopService(new Intent(context, PrayerAdhanService.class));
        NotificationManager manager =
                (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager != null) {
            manager.cancel(notificationId);
        }
    }
}
