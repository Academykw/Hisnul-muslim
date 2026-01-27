package com.deen.adkhar;

import android.app.Application;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import androidx.appcompat.app.AppCompatDelegate;

import com.google.android.gms.ads.MobileAds;
import com.google.firebase.remoteconfig.FirebaseRemoteConfig;
import com.google.firebase.remoteconfig.FirebaseRemoteConfigSettings;
import com.mikepenz.fontawesome_typeface_library.FontAwesome;
import com.mikepenz.iconics.Iconics;

import java.util.HashMap;
import java.util.Map;

public class MyApplication extends Application {
    private static final String PRAYER_PREFS = "prayer_prefs";
    private static final String PRAYER_LAT = "prayer_lat";
    private static final String PRAYER_LON = "prayer_lon";

    @Override
    public void onCreate() {
        super.onCreate();
        
        // Register Icon Fonts
        Iconics.init(getApplicationContext());
        Iconics.registerFont(new FontAwesome());

        SharedPreferences sharedPreferences = PreferenceManager.getDefaultSharedPreferences(this);
        String themePref = sharedPreferences.getString("pref_key_theme", "system");
        
        int mode;
        switch (themePref) {
            case "light":
                mode = AppCompatDelegate.MODE_NIGHT_NO;
                break;
            case "dark":
                mode = AppCompatDelegate.MODE_NIGHT_YES;
                break;
            default:
                mode = AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM;
                break;
        }
        AppCompatDelegate.setDefaultNightMode(mode);

        MobileAds.initialize(this);
        initRemoteConfig();
        schedulePrayerAlarmsIfAvailable();
    }

    private void initRemoteConfig() {
        FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.getInstance();
        FirebaseRemoteConfigSettings settings = new FirebaseRemoteConfigSettings.Builder()
                .setMinimumFetchIntervalInSeconds(BuildConfig.DEBUG ? 0 : 3600)
                .build();
        remoteConfig.setConfigSettingsAsync(settings);
        Map<String, Object> defaults = new HashMap<>();
        defaults.put(AdBannerHelper.REMOTE_CONFIG_AD_UNIT, getString(R.string.ad_banner_unit_id));
        remoteConfig.setDefaultsAsync(defaults);
        remoteConfig.fetchAndActivate();
    }

    private void schedulePrayerAlarmsIfAvailable() {
        SharedPreferences prefs = getSharedPreferences(PRAYER_PREFS, MODE_PRIVATE);
        if (!prefs.contains(PRAYER_LAT) || !prefs.contains(PRAYER_LON)) {
            return;
        }
        double lat = Double.longBitsToDouble(prefs.getLong(PRAYER_LAT, 0));
        double lon = Double.longBitsToDouble(prefs.getLong(PRAYER_LON, 0));
        PrayerTimesScheduler.scheduleForToday(this, lat, lon);
    }
}
