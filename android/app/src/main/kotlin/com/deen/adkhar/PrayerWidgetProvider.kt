package com.deen.adkhar

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.prayer_widget).apply {
                val prayerName = widgetData.getString("next_prayer_name", "---")
                val prayerTime = widgetData.getString("next_prayer_time", "00:00")
                val location = widgetData.getString("location_name", "Detecting location...")

                setTextViewText(R.id.next_prayer_name, prayerName?.uppercase())
                setTextViewText(R.id.next_prayer_time, prayerTime)
                setTextViewText(R.id.location_name, location)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
