package com.deen.adkhar

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

object AdhanAlarmScheduler {
    const val CHANNEL_NAME = "com.deen.adkhar/adhan_alarm"
    const val EXTRA_ID = "id"
    const val EXTRA_PRAYER_NAME = "prayer_name"
    const val EXTRA_TIME_MILLIS = "time_millis"

    private const val PREFS_NAME = "adhan_alarm_prefs"
    private const val PREFS_ALARMS = "alarms"

    fun scheduleAll(context: Context, alarms: List<Map<String, Any>>) {
        cancelAll(context)
        saveAlarms(context, alarms)

        alarms.forEach { alarm ->
            val id = (alarm["id"] as Number).toInt()
            val prayerName = alarm["name"] as String
            val timeMillis = (alarm["timeMillis"] as Number).toLong()

            if (timeMillis > System.currentTimeMillis()) {
                schedule(context, id, prayerName, timeMillis)
            }
        }
    }

    fun rescheduleSavedAlarms(context: Context) {
        val alarms = loadAlarms(context)
        alarms.forEach { alarm ->
            val id = alarm.getInt(EXTRA_ID)
            val prayerName = alarm.getString(EXTRA_PRAYER_NAME)
            val timeMillis = alarm.getLong(EXTRA_TIME_MILLIS)

            if (timeMillis > System.currentTimeMillis()) {
                schedule(context, id, prayerName, timeMillis)
            }
        }
    }

    fun cancelAll(context: Context) {
        loadAlarms(context).forEach { alarm ->
            cancel(context, alarm.getInt(EXTRA_ID))
        }

        repeat(5) { id ->
            cancel(context, id)
        }
    }

    private fun schedule(context: Context, id: Int, prayerName: String, timeMillis: Long) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pendingIntent = pendingIntentFor(context, id, prayerName, timeMillis)
        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        val showIntent = PendingIntent.getActivity(
            context,
            id + 1000,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        )

        alarmManager.setAlarmClock(
            AlarmManager.AlarmClockInfo(timeMillis, showIntent),
            pendingIntent
        )
    }

    private fun cancel(context: Context, id: Int) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AdhanAlarmReceiver::class.java)
        val flags = PendingIntent.FLAG_NO_CREATE or immutableFlag()
        val pendingIntent = PendingIntent.getBroadcast(context, id, intent, flags)

        if (pendingIntent != null) {
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    private fun pendingIntentFor(
        context: Context,
        id: Int,
        prayerName: String,
        timeMillis: Long
    ): PendingIntent {
        val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
            putExtra(EXTRA_ID, id)
            putExtra(EXTRA_PRAYER_NAME, prayerName)
            putExtra(EXTRA_TIME_MILLIS, timeMillis)
        }

        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        )
    }

    private fun saveAlarms(context: Context, alarms: List<Map<String, Any>>) {
        val json = JSONArray()
        alarms.forEach { alarm ->
            json.put(JSONObject().apply {
                put(EXTRA_ID, (alarm["id"] as Number).toInt())
                put(EXTRA_PRAYER_NAME, alarm["name"] as String)
                put(EXTRA_TIME_MILLIS, (alarm["timeMillis"] as Number).toLong())
            })
        }

        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(PREFS_ALARMS, json.toString())
            .apply()
    }

    private fun loadAlarms(context: Context): List<JSONObject> {
        val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(PREFS_ALARMS, "[]") ?: "[]"
        val json = JSONArray(raw)
        return List(json.length()) { index -> json.getJSONObject(index) }
    }

    private fun immutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }
}
