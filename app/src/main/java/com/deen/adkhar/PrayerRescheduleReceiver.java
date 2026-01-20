package com.deen.adkhar;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

public class PrayerRescheduleReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        SharedPreferences prefs = context.getSharedPreferences("prayer_prefs", Context.MODE_PRIVATE);
        if (!prefs.contains("prayer_lat") || !prefs.contains("prayer_lon")) {
            return;
        }
        double lat = Double.longBitsToDouble(prefs.getLong("prayer_lat", 0));
        double lon = Double.longBitsToDouble(prefs.getLong("prayer_lon", 0));
        PrayerTimesScheduler.scheduleForToday(context, lat, lon);
    }
}
