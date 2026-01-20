package com.deen.adkhar;

import android.annotation.SuppressLint;
import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import com.batoulapps.adhan.CalculationMethod;
import com.batoulapps.adhan.CalculationParameters;
import com.batoulapps.adhan.Coordinates;
import com.batoulapps.adhan.Madhab;
import com.batoulapps.adhan.PrayerTimes;
import com.batoulapps.adhan.data.DateComponents;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;

public final class PrayerTimesScheduler {

    public static final String EXTRA_PRAYER_NAME = "extra_prayer_name";
    public static final String EXTRA_NOTIFICATION_ID = "extra_notification_id";

    private PrayerTimesScheduler() {
    }

    public static void scheduleForToday(Context context, double lat, double lon) {
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarmManager == null) {
            return;
        }

        List<PrayerEntry> prayers = getTodayPrayers(lat, lon);
        long now = System.currentTimeMillis();
        long graceWindowMs = 2L * 60L * 1000L;
        for (PrayerEntry entry : prayers) {
            if (entry.time.getTime() + graceWindowMs <= now) {
                continue;
            }
            PendingIntent pendingIntent = buildAlarmIntent(context, entry.name, entry.notificationId);
            alarmManager.cancel(pendingIntent);
            long triggerAt = Math.max(entry.time.getTime(), now + 1000L);
            scheduleExact(context, alarmManager, triggerAt, pendingIntent);
        }

        scheduleNextDayRefresh(context, alarmManager);
    }

    private static List<PrayerEntry> getTodayPrayers(double lat, double lon) {
        Coordinates coordinates = new Coordinates(lat, lon);
        CalculationParameters params = CalculationMethod.MUSLIM_WORLD_LEAGUE.getParameters();
        params.madhab = Madhab.SHAFI;

        DateComponents components = DateComponents.from(new Date());
        PrayerTimes prayerTimes = new PrayerTimes(coordinates, components, params);

        List<PrayerEntry> prayers = new ArrayList<>();
        prayers.add(new PrayerEntry("Fajr", prayerTimes.fajr));
        prayers.add(new PrayerEntry("Dhuhr", prayerTimes.dhuhr));
        prayers.add(new PrayerEntry("Asr", prayerTimes.asr));
        prayers.add(new PrayerEntry("Maghrib", prayerTimes.maghrib));
        prayers.add(new PrayerEntry("Isha", prayerTimes.isha));
        return prayers;
    }

    private static PendingIntent buildAlarmIntent(Context context, String prayerName, int notificationId) {
        Intent intent = new Intent(context, PrayerAlarmReceiver.class);
        intent.putExtra(EXTRA_PRAYER_NAME, prayerName);
        intent.putExtra(EXTRA_NOTIFICATION_ID, notificationId);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        return PendingIntent.getBroadcast(context, notificationId, intent, flags);
    }

    @SuppressLint("ScheduleExactAlarm")
    private static void scheduleExact(Context context, AlarmManager alarmManager, long triggerAtMillis,
                                      PendingIntent pendingIntent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            PendingIntent showIntent = buildShowIntent(context);
            AlarmManager.AlarmClockInfo info = new AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent);
            alarmManager.setAlarmClock(info, pendingIntent);
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent);
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent);
        }
    }

    private static void scheduleNextDayRefresh(Context context, AlarmManager alarmManager) {
        Calendar nextMidnight = Calendar.getInstance();
        nextMidnight.add(Calendar.DAY_OF_MONTH, 1);
        nextMidnight.set(Calendar.HOUR_OF_DAY, 0);
        nextMidnight.set(Calendar.MINUTE, 5);
        nextMidnight.set(Calendar.SECOND, 0);
        nextMidnight.set(Calendar.MILLISECOND, 0);

        Intent intent = new Intent(context, PrayerRescheduleReceiver.class);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        PendingIntent pendingIntent = PendingIntent.getBroadcast(context, 9901, intent, flags);
        alarmManager.cancel(pendingIntent);
        scheduleRefresh(context, alarmManager, nextMidnight.getTimeInMillis(), pendingIntent);
    }

    private static PendingIntent buildShowIntent(Context context) {
        Intent openIntent = new Intent(context, PrayerTimesActivity.class);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        return PendingIntent.getActivity(context, 9902, openIntent, flags);
    }

    private static void scheduleRefresh(Context context, AlarmManager alarmManager, long triggerAtMillis,
                                        PendingIntent pendingIntent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent);
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent);
            }
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent);
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent);
        }
    }

    private static class PrayerEntry {
        final String name;
        final Date time;
        final int notificationId;

        PrayerEntry(String name, Date time) {
            this.name = name;
            this.time = time;
            this.notificationId = ("prayer_" + name).hashCode();
        }
    }
}
