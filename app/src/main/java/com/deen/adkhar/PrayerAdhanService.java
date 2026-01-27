package com.deen.adkhar;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.AssetFileDescriptor;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.IBinder;
import android.preference.PreferenceManager;
import android.os.SystemClock;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import java.io.IOException;

public class PrayerAdhanService extends Service {

    private static final String CHANNEL_ID = "prayer_adhan_channel_v2";
    private static final String PREF_ADHAN_SOUND = "pref_adhan_sound";
    private static final String PREF_ADHAN_FORCE_LOUD = "pref_adhan_force_loud";

    private MediaPlayer mediaPlayer;
    private AudioManager audioManager;
    private static String lastPrayerName;
    private static long lastStartElapsedMs;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String prayerName = intent.getStringExtra(PrayerTimesScheduler.EXTRA_PRAYER_NAME);
        int notificationId = intent.getIntExtra(PrayerTimesScheduler.EXTRA_NOTIFICATION_ID, 1001);
        long nowElapsed = SystemClock.elapsedRealtime();
        if (prayerName != null
                && prayerName.equals(lastPrayerName)
                && nowElapsed - lastStartElapsedMs < 5000L) {
            return START_NOT_STICKY;
        }
        lastPrayerName = prayerName;
        lastStartElapsedMs = nowElapsed;
        NotificationManager manager =
                (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        if (manager == null) {
            stopSelf();
            return START_NOT_STICKY;
        }

        createChannelIfNeeded(manager);
        startForeground(notificationId, buildNotification(prayerName, notificationId));
        if (shouldPlayAdhan()) {
            playAdhanFromAssets();
        } else {
            stopSelf();
        }
        return START_NOT_STICKY;
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (mediaPlayer != null) {
            mediaPlayer.release();
            mediaPlayer = null;
        }
    }

    private void createChannelIfNeeded(NotificationManager manager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return;
        }
        NotificationChannel channel = new NotificationChannel(
                CHANNEL_ID,
                "Prayer Adhan",
                NotificationManager.IMPORTANCE_HIGH
        );
        channel.setSound(null, null);
        manager.createNotificationChannel(channel);
    }

    private NotificationCompat.Builder buildBaseNotification(String prayerName, int notificationId) {
        Intent openIntent = new Intent(this, PrayerTimesActivity.class);
        int flags = PendingIntent.FLAG_UPDATE_CURRENT;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags |= PendingIntent.FLAG_IMMUTABLE;
        }
        PendingIntent openPendingIntent = PendingIntent.getActivity(this, 0, openIntent, flags);

        Intent cancelIntent = new Intent(this, PrayerCancelReceiver.class);
        cancelIntent.putExtra(PrayerTimesScheduler.EXTRA_NOTIFICATION_ID, notificationId);
        PendingIntent cancelPendingIntent = PendingIntent.getBroadcast(this, notificationId, cancelIntent, flags);

        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_prayer)
                .setContentTitle(getString(R.string.prayer_notification_title, prayerName))
                .setContentText(getString(R.string.prayer_notification_body))
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setAutoCancel(true)
                .setContentIntent(openPendingIntent)
                .addAction(R.drawable.ic_prayer,
                        getString(R.string.prayer_notification_cancel),
                        cancelPendingIntent);
    }

    private android.app.Notification buildNotification(String prayerName, int notificationId) {
        NotificationCompat.Builder builder = buildBaseNotification(prayerName, notificationId);
        builder.setSound(null);
        return builder.build();
    }

    private void playAdhanFromAssets() {
        if (mediaPlayer != null && mediaPlayer.isPlaying()) {
            return;
        }
        stopPlayer();
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
        String assetPath = prefs.getString(PREF_ADHAN_SOUND, "azan/azan1.mp3");
        mediaPlayer = new MediaPlayer();
        try (AssetFileDescriptor afd = getAssets().openFd(assetPath)) {
            mediaPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            mediaPlayer.setAudioAttributes(new AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .build());
            mediaPlayer.setOnCompletionListener(mp -> stopSelf());
            mediaPlayer.setOnErrorListener((mp, what, extra) -> {
                stopSelf();
                return true;
            });
            mediaPlayer.prepare();
            mediaPlayer.start();
        } catch (IOException e) {
            stopSelf();
        }
    }

    private void stopPlayer() {
        if (mediaPlayer != null) {
            mediaPlayer.stop();
            mediaPlayer.release();
            mediaPlayer = null;
        }
    }

    private boolean shouldPlayAdhan() {
        audioManager = (AudioManager) getSystemService(AUDIO_SERVICE);
        if (audioManager == null) {
            return false;
        }
        SharedPreferences prefs = PreferenceManager.getDefaultSharedPreferences(this);
        boolean forceLoud = prefs.getBoolean(PREF_ADHAN_FORCE_LOUD, false);
        if (forceLoud) {
            return true;
        }
        int ringerMode = audioManager.getRingerMode();
        return ringerMode == AudioManager.RINGER_MODE_NORMAL;
    }
    

}
