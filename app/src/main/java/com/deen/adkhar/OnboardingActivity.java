package com.deen.adkhar;

import android.Manifest;
import android.app.AlarmManager;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.preference.PreferenceManager;
import androidx.viewpager2.widget.ViewPager2;

import java.util.ArrayList;
import java.util.List;

public class OnboardingActivity extends AppCompatActivity {

    private static final String PREF_ONBOARDING_DONE = "pref_onboarding_done";
    private static final int REQUEST_PERMISSIONS = 3101;

    private ViewPager2 viewPager;
    private LinearLayout indicatorLayout;
    private TextView skipButton;
    private Button nextButton;
    private final List<View> indicators = new ArrayList<>();
    private List<OnboardingPage> pages;
    private boolean permissionsRequested;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_onboarding);

        viewPager = findViewById(R.id.onboarding_pager);
        indicatorLayout = findViewById(R.id.onboarding_indicator);
        skipButton = findViewById(R.id.onboarding_skip);
        nextButton = findViewById(R.id.onboarding_next);

        pages = buildPages();
        viewPager.setAdapter(new OnboardingAdapter(pages));
        setupIndicators(pages.size());
        updateIndicators(0);
        updateControls(0);

        viewPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override
            public void onPageSelected(int position) {
                updateIndicators(position);
                updateControls(position);
            }
        });

        skipButton.setOnClickListener(v -> finishOnboarding());
        nextButton.setOnClickListener(v -> {
            int position = viewPager.getCurrentItem();
            if (position < pages.size() - 1) {
                viewPager.setCurrentItem(position + 1, true);
            } else {
                finishOnboarding();
            }
        });
    }

    private List<OnboardingPage> buildPages() {
        List<OnboardingPage> list = new ArrayList<>();
        list.add(new OnboardingPage(
                R.drawable.ic_prayer,
                R.string.onboarding_title_prayer,
                R.string.onboarding_body_prayer));
        list.add(new OnboardingPage(
                R.drawable.ic_hijrah_calendar,
                R.string.onboarding_title_calendar,
                R.string.onboarding_body_calendar));
        list.add(new OnboardingPage(
                R.drawable.ic_zakat,
                R.string.onboarding_title_permissions,
                R.string.onboarding_body_permissions));
        return list;
    }

    private void setupIndicators(int count) {
        indicatorLayout.removeAllViews();
        indicators.clear();
        for (int i = 0; i < count; i++) {
            View dot = new View(this);
            int size = getResources().getDimensionPixelSize(R.dimen.onboarding_dot_size);
            LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(size, size);
            params.setMargins(size / 2, 0, size / 2, 0);
            dot.setLayoutParams(params);
            dot.setBackgroundResource(R.drawable.onboarding_dot_inactive);
            indicatorLayout.addView(dot);
            indicators.add(dot);
        }
    }

    private void updateIndicators(int position) {
        for (int i = 0; i < indicators.size(); i++) {
            int drawable = (i == position)
                    ? R.drawable.onboarding_dot_active
                    : R.drawable.onboarding_dot_inactive;
            indicators.get(i).setBackgroundResource(drawable);
        }
    }

    private void updateControls(int position) {
        boolean last = position == pages.size() - 1;
        skipButton.setVisibility(last ? View.INVISIBLE : View.VISIBLE);
        nextButton.setText(last
                ? getString(R.string.onboarding_cta_enable)
                : getString(R.string.onboarding_cta_next));
    }

    private void finishOnboarding() {
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
        prefs.edit().putBoolean(PREF_ONBOARDING_DONE, true).apply();

        requestExactAlarmIfNeeded();
        if (requestRuntimePermissionsIfNeeded()) {
            permissionsRequested = true;
            return;
        }
        goToHome();
    }

    private boolean requestRuntimePermissionsIfNeeded() {
        List<String> permissions = new ArrayList<>();
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            permissions.add(Manifest.permission.ACCESS_FINE_LOCATION);
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                    != PackageManager.PERMISSION_GRANTED) {
                permissions.add(Manifest.permission.POST_NOTIFICATIONS);
            }
        }
        if (!permissions.isEmpty()) {
            ActivityCompat.requestPermissions(this,
                    permissions.toArray(new String[0]),
                    REQUEST_PERMISSIONS);
            return true;
        }
        return false;
    }

    private void requestExactAlarmIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            AlarmManager alarmManager = (AlarmManager) getSystemService(ALARM_SERVICE);
            if (alarmManager != null && !alarmManager.canScheduleExactAlarms()) {
                Intent intent = new Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM);
                startActivity(intent);
            }
        }
    }


    private void goToHome() {
        Intent mainIntent = new Intent(this, DuaGroupActivity.class);
        startActivity(mainIntent);
        finish();
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_PERMISSIONS && permissionsRequested) {
            goToHome();
        }
    }
}
