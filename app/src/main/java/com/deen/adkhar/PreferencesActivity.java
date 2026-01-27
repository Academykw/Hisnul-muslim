package com.deen.adkhar;

import android.os.Build;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.preference.PreferenceFragment;
import android.view.MenuItem;
import android.view.View;
import android.content.res.AssetFileDescriptor;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.preference.Preference;


import androidx.appcompat.app.AppCompatDelegate;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;

public class PreferencesActivity extends AppCompatActivity {

    private Toolbar toolbar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_preferences );

        toolbar = (Toolbar) findViewById(R.id.my_action_bar);
        View mToolbarShadow = findViewById(R.id.view_toolbar_shadow);
        setSupportActionBar(toolbar);
        getSupportActionBar().setDisplayHomeAsUpEnabled(true);

        // Display the fragment as the main content.
        getFragmentManager().beginTransaction()
                .replace(R.id.content_view, new SettingsFragment())
                .commit();

        if (Build.VERSION.SDK_INT >= 21) {
            mToolbarShadow.setVisibility(View.GONE);
        }

        AdBannerHelper.loadBanner(this, R.id.ad_view);
    }

    public static class SettingsFragment extends PreferenceFragment implements SharedPreferences.OnSharedPreferenceChangeListener {
        private MediaPlayer mediaPlayer;

        @Override
        public void onCreate(Bundle paramBundle) {
            super.onCreate(paramBundle);
            addPreferencesFromResource(R.xml.preferences);

            Preference previewPreference = findPreference("pref_adhan_preview");
            if (previewPreference != null) {
                previewPreference.setOnPreferenceClickListener(preference -> {
                    playAdhanPreview();
                    return true;
                });
            }
        }

        @Override
        public void onResume() {
            super.onResume();
            getPreferenceScreen().getSharedPreferences()
                    .registerOnSharedPreferenceChangeListener(this);
        }

        @Override
        public void onPause() {
            super.onPause();
            getPreferenceScreen().getSharedPreferences()
                    .unregisterOnSharedPreferenceChangeListener(this);
            stopPreview();
        }

        @Override
        public void onSharedPreferenceChanged(SharedPreferences sharedPreferences, String key) {
            if (key.equals("pref_key_theme")) {
                String themePref = sharedPreferences.getString(key, "system");
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

        private void playAdhanPreview() {
            stopPreview();
            SharedPreferences prefs = getPreferenceScreen().getSharedPreferences();
            String adhanKey = getString(R.string.pref_adhan_sound_key);
            String assetPath = prefs.getString(adhanKey, "azan/azan1.mp3");
            mediaPlayer = new MediaPlayer();
            try (AssetFileDescriptor afd = getActivity().getAssets().openFd(assetPath)) {
                mediaPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
                mediaPlayer.setAudioAttributes(new AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build());
                mediaPlayer.setOnCompletionListener(mp -> stopPreview());
                mediaPlayer.setOnErrorListener((mp, what, extra) -> {
                    stopPreview();
                    return true;
                });
                mediaPlayer.prepare();
                mediaPlayer.start();
            } catch (Exception e) {
                stopPreview();
            }
        }

        private void stopPreview() {
            if (mediaPlayer != null) {
                if (mediaPlayer.isPlaying()) {
                    mediaPlayer.stop();
                }
                mediaPlayer.release();
                mediaPlayer = null;
            }
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item)
    {
        if (item.getItemId() == android.R.id.home) {
            finish();
        }
        return false;
    }
}
