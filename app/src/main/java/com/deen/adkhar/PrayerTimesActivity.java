package com.deen.adkhar;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.app.AlarmManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.location.Geocoder;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.batoulapps.adhan.CalculationMethod;
import com.batoulapps.adhan.CalculationParameters;
import com.batoulapps.adhan.Coordinates;
import com.batoulapps.adhan.Madhab;
import com.batoulapps.adhan.PrayerTimes;
import com.batoulapps.adhan.data.DateComponents;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class PrayerTimesActivity extends AppCompatActivity {

    private static final int REQUEST_LOCATION = 2001;
    private static final int REQUEST_NOTIFICATIONS = 2002;
    private static final String PREFS_NAME = "prayer_prefs";
    private static final String PREF_LAT = "prayer_lat";
    private static final String PREF_LON = "prayer_lon";

    private TextView locationStatus;
    private TextView locationName;
    private TextView nextPrayerCountdown;
    private TextView fajrTime;
    private TextView sunriseTime;
    private TextView dhuhrTime;
    private TextView asrTime;
    private TextView maghribTime;
    private TextView ishaTime;
    private LinearLayout rowFajr;
    private LinearLayout rowSunrise;
    private LinearLayout rowDhuhr;
    private LinearLayout rowAsr;
    private LinearLayout rowMaghrib;
    private LinearLayout rowIsha;
    private LocationManager locationManager;
    private final Handler countdownHandler = new Handler(Looper.getMainLooper());
    private Runnable countdownRunnable;
    private double currentLat;
    private double currentLon;
    private boolean hasLocation;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_prayer_times);

        Toolbar toolbar = findViewById(R.id.my_action_bar);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            getSupportActionBar().setTitle(getString(R.string.title_activity_prayer_times));
        }

        locationStatus = findViewById(R.id.tv_location_status);
        locationName = findViewById(R.id.tv_location_name);
        nextPrayerCountdown = findViewById(R.id.tv_next_prayer);
        fajrTime = findViewById(R.id.tv_fajr_time);
        sunriseTime = findViewById(R.id.tv_sunrise_time);
        dhuhrTime = findViewById(R.id.tv_dhuhr_time);
        asrTime = findViewById(R.id.tv_asr_time);
        maghribTime = findViewById(R.id.tv_maghrib_time);
        ishaTime = findViewById(R.id.tv_isha_time);
        rowFajr = findViewById(R.id.row_fajr);
        rowSunrise = findViewById(R.id.row_sunrise);
        rowDhuhr = findViewById(R.id.row_dhuhr);
        rowAsr = findViewById(R.id.row_asr);
        rowMaghrib = findViewById(R.id.row_maghrib);
        rowIsha = findViewById(R.id.row_isha);
        Button updateLocation = findViewById(R.id.btn_update_location);
        updateLocation.setOnClickListener(v -> requestLocation());

        locationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
        requestExactAlarmPermissionIfNeeded();
        requestNotificationPermissionIfNeeded();
        loadSavedLocationOrRequest();
    }

    private void requestExactAlarmPermissionIfNeeded() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
            AlarmManager alarmManager = (AlarmManager) getSystemService(Context.ALARM_SERVICE);
            if (alarmManager != null && !alarmManager.canScheduleExactAlarms()) {
                Intent intent = new Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM);
                startActivity(intent);
            }
        }
    }

    private void requestNotificationPermissionIfNeeded() {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                    != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                        this,
                        new String[]{Manifest.permission.POST_NOTIFICATIONS},
                        REQUEST_NOTIFICATIONS
                );
            }
        }
    }

    private void loadSavedLocationOrRequest() {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        if (prefs.contains(PREF_LAT) && prefs.contains(PREF_LON)) {
            double lat = Double.longBitsToDouble(prefs.getLong(PREF_LAT, 0));
            double lon = Double.longBitsToDouble(prefs.getLong(PREF_LON, 0));
            updatePrayerTimes(lat, lon);
            locationStatus.setText(getString(R.string.prayer_location_loaded));
            fetchLocationName(lat, lon);
            PrayerTimesScheduler.scheduleForToday(this, lat, lon);
        } else {
            requestLocation();
        }
    }

    private void requestLocation() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                    this,
                    new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
                    REQUEST_LOCATION
            );
            return;
        }

        if (!locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
                && !locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) {
            locationStatus.setText(getString(R.string.prayer_location_disabled));
            startActivity(new Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS));
            return;
        }

        locationStatus.setText(getString(R.string.prayer_location_fetching));
        Location lastLocation = getLastKnownLocation();
        if (lastLocation != null) {
            onLocationReady(lastLocation);
            return;
        }

        String provider = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
                ? LocationManager.GPS_PROVIDER
                : LocationManager.NETWORK_PROVIDER;

        LocationListener listener = new LocationListener() {
            @Override
            public void onLocationChanged(@NonNull Location location) {
                onLocationReady(location);
                locationManager.removeUpdates(this);
            }
        };

        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                == PackageManager.PERMISSION_GRANTED) {
            locationManager.requestSingleUpdate(provider, listener, null);
        }
    }

    private Location getLastKnownLocation() {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            return null;
        }
        Location gps = locationManager.getLastKnownLocation(LocationManager.GPS_PROVIDER);
        Location network = locationManager.getLastKnownLocation(LocationManager.NETWORK_PROVIDER);
        if (gps != null && network != null) {
            return gps.getTime() >= network.getTime() ? gps : network;
        }
        return gps != null ? gps : network;
    }

    private void onLocationReady(Location location) {
        double lat = location.getLatitude();
        double lon = location.getLongitude();
        saveLocation(lat, lon);
        updatePrayerTimes(lat, lon);
        locationStatus.setText(getString(R.string.prayer_location_ready));
        fetchLocationName(lat, lon);
        PrayerTimesScheduler.scheduleForToday(this, lat, lon);
    }

    private void saveLocation(double lat, double lon) {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        prefs.edit()
                .putLong(PREF_LAT, Double.doubleToRawLongBits(lat))
                .putLong(PREF_LON, Double.doubleToRawLongBits(lon))
                .apply();
    }

    private void updatePrayerTimes(double lat, double lon) {
        currentLat = lat;
        currentLon = lon;
        hasLocation = true;
        PrayerTimes prayerTimes = getPrayerTimes(lat, lon, new Date());
        SimpleDateFormat formatter = new SimpleDateFormat("h:mm a", Locale.getDefault());
        fajrTime.setText(formatter.format(prayerTimes.fajr));
        sunriseTime.setText(formatter.format(prayerTimes.sunrise));
        dhuhrTime.setText(formatter.format(prayerTimes.dhuhr));
        asrTime.setText(formatter.format(prayerTimes.asr));
        maghribTime.setText(formatter.format(prayerTimes.maghrib));
        ishaTime.setText(formatter.format(prayerTimes.isha));
        updateNextPrayerHighlight();
        startCountdownTicker();
    }

    private void fetchLocationName(double lat, double lon) {
        if (!Geocoder.isPresent()) {
            locationName.setText(getString(R.string.prayer_location_name_placeholder));
            return;
        }
        new Thread(() -> {
            String name = null;
            try {
                Geocoder geocoder = new Geocoder(this, Locale.getDefault());
                List<android.location.Address> results = geocoder.getFromLocation(lat, lon, 1);
                if (results != null && !results.isEmpty()) {
                    android.location.Address address = results.get(0);
                    String street = address.getThoroughfare();
                    String area = address.getSubLocality();
                    String locality = address.getLocality();
                    String country = address.getCountryName();
                    StringBuilder builder = new StringBuilder();
                    if (street != null && !street.isEmpty()) {
                        builder.append(street);
                    }
                    if (area != null && !area.isEmpty()) {
                        if (builder.length() > 0) {
                            builder.append(", ");
                        }
                        builder.append(area);
                    }
                    if (locality != null && !locality.isEmpty()) {
                        if (builder.length() > 0) {
                            builder.append(", ");
                        }
                        builder.append(locality);
                    }
                    if (country != null && !country.isEmpty()) {
                        if (builder.length() > 0) {
                            builder.append(", ");
                        }
                        builder.append(country);
                    }
                    if (builder.length() > 0) {
                        name = builder.toString();
                    } else {
                        name = address.getAddressLine(0);
                    }
                }
            } catch (Exception ignored) {
            }
            String finalName = name;
            runOnUiThread(() -> {
                if (finalName != null && !finalName.isEmpty()) {
                    locationName.setText(finalName);
                } else {
                    locationName.setText(getString(R.string.prayer_location_name_placeholder));
                }
            });
        }).start();
    }

    private PrayerTimes getPrayerTimes(double lat, double lon, Date date) {
        Coordinates coordinates = new Coordinates(lat, lon);
        CalculationParameters params = CalculationMethod.MUSLIM_WORLD_LEAGUE.getParameters();
        params.madhab = Madhab.SHAFI;
        DateComponents components = DateComponents.from(date);
        return new PrayerTimes(coordinates, components, params);
    }

    @Override
    protected void onPause() {
        super.onPause();
        stopCountdownTicker();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (hasLocation) {
            startCountdownTicker();
        }
    }

    private void startCountdownTicker() {
        stopCountdownTicker();
        countdownRunnable = new Runnable() {
            @Override
            public void run() {
                updateNextPrayerCountdown();
                countdownHandler.postDelayed(this, 1000);
            }
        };
        countdownHandler.post(countdownRunnable);
    }

    private void stopCountdownTicker() {
        if (countdownRunnable != null) {
            countdownHandler.removeCallbacks(countdownRunnable);
        }
    }

    private void updateNextPrayerCountdown() {
        if (!hasLocation) {
            nextPrayerCountdown.setText(getString(R.string.prayer_next_placeholder));
            return;
        }
        Date now = new Date();
        NextPrayerInfo info = getNextPrayerInfo(now, currentLat, currentLon);
        if (info == null) {
            nextPrayerCountdown.setText(getString(R.string.prayer_next_placeholder));
            return;
        }
        long remainingMs = Math.max(0, info.time.getTime() - now.getTime());
        long totalSeconds = remainingMs / 1000;
        long hours = totalSeconds / 3600;
        long minutes = (totalSeconds % 3600) / 60;
        long seconds = totalSeconds % 60;
        String countdown = String.format(Locale.getDefault(), "%02d:%02d:%02d", hours, minutes, seconds);
        nextPrayerCountdown.setText(getString(R.string.prayer_next_format, info.name, countdown));
        updateNextPrayerHighlight(info.name);
    }

    private NextPrayerInfo getNextPrayerInfo(Date now, double lat, double lon) {
        PrayerTimes today = getPrayerTimes(lat, lon, now);
        NextPrayerInfo next = findNextPrayerForToday(now, today);
        if (next != null) {
            return next;
        }
        Date tomorrow = new Date(now.getTime() + 24L * 60L * 60L * 1000L);
        PrayerTimes tomorrowTimes = getPrayerTimes(lat, lon, tomorrow);
        return new NextPrayerInfo(getString(R.string.prayer_fajr), tomorrowTimes.fajr);
    }

    private NextPrayerInfo findNextPrayerForToday(Date now, PrayerTimes prayerTimes) {
        if (prayerTimes.fajr.after(now)) {
            return new NextPrayerInfo(getString(R.string.prayer_fajr), prayerTimes.fajr);
        }
        if (prayerTimes.dhuhr.after(now)) {
            return new NextPrayerInfo(getString(R.string.prayer_dhuhr), prayerTimes.dhuhr);
        }
        if (prayerTimes.asr.after(now)) {
            return new NextPrayerInfo(getString(R.string.prayer_asr), prayerTimes.asr);
        }
        if (prayerTimes.maghrib.after(now)) {
            return new NextPrayerInfo(getString(R.string.prayer_maghrib), prayerTimes.maghrib);
        }
        if (prayerTimes.isha.after(now)) {
            return new NextPrayerInfo(getString(R.string.prayer_isha), prayerTimes.isha);
        }
        return null;
    }

    private void updateNextPrayerHighlight() {
        updateNextPrayerHighlight(null);
    }

    private void updateNextPrayerHighlight(String prayerName) {
        clearRowHighlights();
        if (prayerName == null || prayerName.isEmpty()) {
            return;
        }
        if (prayerName.equals(getString(R.string.prayer_fajr))) {
            rowFajr.setBackgroundResource(R.drawable.prayer_row_highlight);
        } else if (prayerName.equals(getString(R.string.prayer_sunrise))) {
            rowSunrise.setBackgroundResource(R.drawable.prayer_row_highlight);
        } else if (prayerName.equals(getString(R.string.prayer_dhuhr))) {
            rowDhuhr.setBackgroundResource(R.drawable.prayer_row_highlight);
        } else if (prayerName.equals(getString(R.string.prayer_asr))) {
            rowAsr.setBackgroundResource(R.drawable.prayer_row_highlight);
        } else if (prayerName.equals(getString(R.string.prayer_maghrib))) {
            rowMaghrib.setBackgroundResource(R.drawable.prayer_row_highlight);
        } else if (prayerName.equals(getString(R.string.prayer_isha))) {
            rowIsha.setBackgroundResource(R.drawable.prayer_row_highlight);
        }
    }

    private void clearRowHighlights() {
        rowFajr.setBackgroundResource(R.drawable.prayer_row_bg);
        rowSunrise.setBackgroundResource(R.drawable.prayer_row_bg);
        rowDhuhr.setBackgroundResource(R.drawable.prayer_row_bg);
        rowAsr.setBackgroundResource(R.drawable.prayer_row_bg);
        rowMaghrib.setBackgroundResource(R.drawable.prayer_row_bg);
        rowIsha.setBackgroundResource(R.drawable.prayer_row_bg);
    }

    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_LOCATION) {
            if (grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                requestLocation();
            } else {
                locationStatus.setText(getString(R.string.prayer_location_denied));
            }
        } else if (requestCode == REQUEST_NOTIFICATIONS) {
            // Notifications are optional; no UI update needed.
        }
    }

    private static class NextPrayerInfo {
        final String name;
        final Date time;

        NextPrayerInfo(String name, Date time) {
            this.name = name;
            this.time = time;
        }
    }
}
