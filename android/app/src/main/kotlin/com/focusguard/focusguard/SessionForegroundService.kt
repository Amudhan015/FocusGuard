package com.focusguard.focusguard

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

/**
 * Owns the persistent, non-dismissible countdown notification shown
 * during an active focus session. Deliberately a real foreground
 * Service rather than a Dart Timer driving flutter_local_notifications -
 * Android throttles background Dart execution once the app isn't
 * foregrounded, so a Dart-driven notification would silently stop
 * updating exactly when the student has put the phone down, which is
 * the whole point of the notification. This runs independent of the
 * Flutter engine, same as FocusGuardAccessibilityService.
 */
class SessionForegroundService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var endTimeMillis: Long = 0L
    private var label: String = "Focus session"

    private val updateRunnable = object : Runnable {
        override fun run() {
            val remaining = endTimeMillis - System.currentTimeMillis()
            if (remaining <= 0) {
                stopSelfSafely()
                return
            }
            notify(buildNotification(remaining))
            handler.postDelayed(this, Constants.FOREGROUND_UPDATE_INTERVAL_MILLIS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        createChannelIfNeeded()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            Constants.ACTION_START_FOREGROUND_SESSION -> {
                endTimeMillis = intent.getLongExtra(Constants.EXTRA_FOREGROUND_END_MILLIS, 0L)
                label = intent.getStringExtra(Constants.EXTRA_FOREGROUND_LABEL) ?: "Focus session"

                val remaining = endTimeMillis - System.currentTimeMillis()
                if (remaining <= 0) {
                    stopSelfSafely()
                    return START_NOT_STICKY
                }

                startForeground(Constants.NOTIFICATION_ID, buildNotification(remaining))
                handler.removeCallbacks(updateRunnable)
                handler.postDelayed(updateRunnable, Constants.FOREGROUND_UPDATE_INTERVAL_MILLIS)
            }

            Constants.ACTION_STOP_FOREGROUND_SESSION -> stopSelfSafely()
        }
        // Not START_STICKY: if the system kills this process, the session
        // state still lives in SharedPreferences/Hive - there is nothing
        // useful to "restart into" without the app's own resume logic
        // re-driving it, so there's no reason to ask Android to restart
        // an orphaned service.
        return START_NOT_STICKY
    }

    private fun buildNotification(remainingMillis: Long): Notification {
        val totalSeconds = remainingMillis / 1000
        val minutes = totalSeconds / 60
        val seconds = totalSeconds % 60
        val remainingText = String.format("%d:%02d remaining", minutes, seconds)

        val contentIntent = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }

        return NotificationCompat.Builder(this, Constants.NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(label)
            .setContentText(remainingText)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setContentIntent(contentIntent)
            .build()
    }

    private fun notify(notification: Notification) {
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(Constants.NOTIFICATION_ID, notification)
    }

    private fun createChannelIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            Constants.NOTIFICATION_CHANNEL_ID,
            "Active focus session",
            NotificationManager.IMPORTANCE_LOW, // low: no sound/heads-up, just persistent status
        ).apply {
            description = "Shows the countdown while a FocusGuard session is running."
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun stopSelfSafely() {
        handler.removeCallbacks(updateRunnable)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(updateRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
