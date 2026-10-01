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
 *
 * FIXED: the countdown text used to be manually rebuilt on a 30-second
 * poll (FOREGROUND_UPDATE_INTERVAL_MILLIS), which meant it could show a
 * number up to 30 seconds behind/ahead of the in-app Flutter timer,
 * which ticks every second - this was the actual cause of "the
 * notification's timer doesn't match the app". Now it uses
 * setUsesChronometer/setChronometerCountDown, which hands the countdown
 * to the OS's own notification renderer: it's driven directly off
 * setWhen(endTimeMillis), the same instant Flutter already agreed on, so
 * it can't drift, and it needs no polling loop to look correct at all.
 *
 * ALSO ADDED: Pause / Resume / Stop actions on the notification itself.
 * Each is a PendingIntent that brings MainActivity to the foreground
 * (it's already launchMode="singleTop", so this routes through
 * onNewIntent rather than restarting the app) with an action extra;
 * MainActivity relays that straight to Dart over the existing method
 * channel, where SessionProvider is already wired up to react to it.
 * True headless handling (without ever bringing the app to the
 * foreground) would need a separately cached background FlutterEngine -
 * more moving parts than we have time for right now, and "tapping the
 * button opens the app to show the new state" is normal, expected
 * behavior for this kind of control anyway.
 */
class SessionForegroundService : Service() {

    private val handler = Handler(Looper.getMainLooper())
    private var endTimeMillis: Long = 0L
    private var label: String = "Focus session"
    private var isPaused: Boolean = false

    // Pure safety net now (see Constants.FOREGROUND_SAFETY_CHECK_INTERVAL_MILLIS) -
    // display accuracy no longer depends on this running at all.
    private val safetyCheckRunnable = object : Runnable {
        override fun run() {
            if (!isPaused && endTimeMillis in 1 until System.currentTimeMillis()) {
                stopSelfSafely()
                return
            }
            handler.postDelayed(this, Constants.FOREGROUND_SAFETY_CHECK_INTERVAL_MILLIS)
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
                isPaused = intent.getBooleanExtra(Constants.EXTRA_FOREGROUND_IS_PAUSED, false)

                if (!isPaused) {
                    val remaining = endTimeMillis - System.currentTimeMillis()
                    if (remaining <= 0) {
                        stopSelfSafely()
                        return START_NOT_STICKY
                    }
                }

                startForeground(Constants.NOTIFICATION_ID, buildNotification())
                handler.removeCallbacks(safetyCheckRunnable)
                handler.postDelayed(safetyCheckRunnable, Constants.FOREGROUND_SAFETY_CHECK_INTERVAL_MILLIS)
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

    private fun buildNotification(): Notification {
        val contentIntent = packageManager.getLaunchIntentForPackage(packageName)?.let {
            PendingIntent.getActivity(
                this,
                0,
                it,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }

        val builder = NotificationCompat.Builder(this, Constants.NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(label)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .setContentIntent(contentIntent)

        if (isPaused) {
            builder.setContentText("Paused")
            builder.addAction(
                0,
                "Resume",
                notificationActionIntent(Constants.ACTION_NOTIFICATION_RESUME, requestCode = 2),
            )
        } else {
            // setChronometerCountDown requires API 24+; this app's minSdk
            // is 26, so it's always available here, but the check keeps
            // this safe if minSdk ever changes.
            builder.setUsesChronometer(true)
            builder.setWhen(endTimeMillis)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                builder.setChronometerCountDown(true)
            }
            builder.addAction(
                0,
                "Pause",
                notificationActionIntent(Constants.ACTION_NOTIFICATION_PAUSE, requestCode = 1),
            )
        }

        builder.addAction(
            0,
            "Stop",
            notificationActionIntent(Constants.ACTION_NOTIFICATION_STOP, requestCode = 3),
        )

        return builder.build()
    }

    private fun notificationActionIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, MainActivity::class.java).apply {
            this.action = action
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_NEW_TASK
        }
        return PendingIntent.getActivity(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
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
        handler.removeCallbacks(safetyCheckRunnable)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onDestroy() {
        handler.removeCallbacks(safetyCheckRunnable)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
