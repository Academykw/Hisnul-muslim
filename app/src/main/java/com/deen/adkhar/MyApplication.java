package com.deen.adkhar;

import android.app.Application;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import androidx.appcompat.app.AppCompatDelegate;

import com.mikepenz.fontawesome_typeface_library.FontAwesome;
import com.mikepenz.iconics.Iconics;

public class MyApplication extends Application {
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
    }
}
