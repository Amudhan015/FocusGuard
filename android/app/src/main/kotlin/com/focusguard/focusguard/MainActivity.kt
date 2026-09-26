package com.focusguard.focusguard

import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private lateinit var prefsStore: PrefsStore

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        prefsStore = PrefsStore(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, Constants.METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // --- App state sync (Dart -> native) ---
                    "syncBlockedApps" -> {
                        @Suppress("UNCHECKED_CAST")
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        @Suppress("UNCHECKED_CAST")
                        val notes = call.argument<Map<String, String>>("notes") ?: emptyMap()
                        prefsStore.setBlockedPackages(packages, notes)
                        Log.i("FocusGuard", "syncBlockedApps: wrote ${packages.size} package(s): $packages")
                        result.success(null)
                    }

                    "setNotificationWhitelist" -> {
                        @Suppress("UNCHECKED_CAST")
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        prefsStore.setNotificationWhitelist(packages)
                        result.success(null)
                    }

                    "startSession" -> {
                        val endTimeMillis = call.argument<Long>("endTimeMillis")
                            ?: (call.argument<Int>("endTimeMillis")?.toLong())
                            ?: 0L
                        prefsStore.setSessionActive(true, endTimeMillis)
                        Log.i("FocusGuard", "startSession: active=true, endTimeMillis=$endTimeMillis (in ${(endTimeMillis - System.currentTimeMillis()) / 1000}s)")
                        // Start pickup detection service
                        val pickupIntent = Intent(this, PickupDetectionService::class.java)
                        startService(pickupIntent)
                        result.success(null)
                    }

                    "endSession" -> {
                        prefsStore.setSessionActive(false, 0L)
                        Log.i("FocusGuard", "endSession: active=false")
                        // Stop pickup detection service
                        val pickupIntent = Intent(this, PickupDetectionService::class.java)
                        stopService(pickupIntent)
                        result.success(null)
                    }

                    // --- Event queue drains (native -> Dart, pull-based) ---
                    "drainPendingEscapeAttempts" -> {
                        result.success(prefsStore.drainEscapeAttempts())
                    }

                    "drainPendingPhonePickups" -> {
                        result.success(prefsStore.drainPhonePickups())
                    }

                    // --- Permission checks ---
                    "isAccessibilityServiceEnabled" ->
                        result.success(PermissionUtils.isAccessibilityServiceEnabled(this))

                    "isOverlayPermissionGranted" ->
                        result.success(PermissionUtils.isOverlayPermissionGranted(this))

                    "isNotificationListenerEnabled" ->
                        result.success(PermissionUtils.isNotificationListenerEnabled(this))

                    "isUsageAccessGranted" ->
                        result.success(PermissionUtils.isUsageAccessGranted(this))

                    "isIgnoringBatteryOptimizations" ->
                        result.success(PermissionUtils.isIgnoringBatteryOptimizations(this))

                    // --- Permission requests (open the relevant Settings screen) ---
                    "requestAccessibilityPermission" -> {
                        PermissionUtils.requestAccessibilityPermission(this)
                        result.success(null)
                    }

                    "requestOverlayPermission" -> {
                        PermissionUtils.requestOverlayPermission(this)
                        result.success(null)
                    }

                    "requestNotificationListenerPermission" -> {
                        PermissionUtils.requestNotificationListenerPermission(this)
                        result.success(null)
                    }

                    "requestUsageAccessPermission" -> {
                        PermissionUtils.requestUsageAccessPermission(this)
                        result.success(null)
                    }

                    "requestIgnoreBatteryOptimizations" -> {
                        PermissionUtils.requestIgnoreBatteryOptimizations(this)
                        result.success(null)
                    }

                    // --- Usage stats ---
                    "getTodayUsageStats" -> {
                        result.success(UsageStatsHelper.getTodayUsageMillis(this))
                    }

                    // --- Persistent countdown notification (native foreground service) ---
                    "startForegroundNotification" -> {
                        val endTimeMillis = call.argument<Long>("endTimeMillis")
                            ?: (call.argument<Int>("endTimeMillis")?.toLong())
                            ?: 0L
                        val label = call.argument<String>("label") ?: "Focus session"
                        val serviceIntent = Intent(this, SessionForegroundService::class.java).apply {
                            action = Constants.ACTION_START_FOREGROUND_SESSION
                            putExtra(Constants.EXTRA_FOREGROUND_END_MILLIS, endTimeMillis)
                            putExtra(Constants.EXTRA_FOREGROUND_LABEL, label)
                        }
                        startForegroundService(serviceIntent)
                        result.success(null)
                    }

                    "stopForegroundNotification" -> {
                        val serviceIntent = Intent(this, SessionForegroundService::class.java).apply {
                            action = Constants.ACTION_STOP_FOREGROUND_SESSION
                        }
                        startService(serviceIntent)
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
