package com.deen.adkhar;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.preference.PreferenceManager;

public class Splash extends AppCompatActivity {


    int SPLASH_DISPLAY_LENGTH = 1000;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);
        getWindow().setFlags(1024, 1024);

        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                boolean onboardingDone = PreferenceManager.getDefaultSharedPreferences(Splash.this)
                        .getBoolean("pref_onboarding_done", false);
                Intent intent = onboardingDone
                        ? new Intent(Splash.this, DuaGroupActivity.class)
                        : new Intent(Splash.this, OnboardingActivity.class);
                Splash.this.startActivity(intent);
                Splash.this.finish();
            }
        },SPLASH_DISPLAY_LENGTH);
    }
}
