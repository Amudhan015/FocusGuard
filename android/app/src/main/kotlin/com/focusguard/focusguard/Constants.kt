package com.focusguard.focusguard

/**
 * Single source of truth for channel names and SharedPreferences keys.
 * Both MainActivity (Dart bridge) and the background services read from
 * here so a name typo can't cause a silent mismatch between Kotlin
 * files.
 */
object Constants {
    const val METHOD_CHANNEL = "com.focusguard/native_bridge"

    const val PREFS_NAME = "focusguard_native_prefs"

    // --- Persisted state, written by Dart, read by services ---
    const val KEY_BLOCKED_PACKAGES = "blocked_packages" // JSON array<String>
    const val KEY_BLOCK_NOTES = "block_notes" // JSON object {package: note}
    const val KEY_NOTIFICATION_WHITELIST = "notification_whitelist_packages" // JSON array<String>
    const val KEY_SESSION_ACTIVE = "session_active" // boolean
    const val KEY_SESSION_END_TIME_MILLIS = "session_end_time_millis" // long

    // --- Event queues, appended by services, drained by Dart ---
    const val KEY_PENDING_ESCAPE_ATTEMPTS = "pending_escape_attempts" // JSON array of objects
    const val KEY_PENDING_PHONE_PICKUPS = "pending_phone_pickups" // JSON array of objects

    // --- Escape attempt / pickup JSON object field names ---
    const val FIELD_PACKAGE_NAME = "packageName"
    const val FIELD_APP_NAME = "appName"
    const val FIELD_TIMESTAMP_MILLIS = "timestampMillis"

    // --- BlockOverlayActivity intent extras ---
    const val EXTRA_PACKAGE_NAME = "extra_package_name"
    const val EXTRA_APP_NAME = "extra_app_name"
    const val EXTRA_BLOCK_NOTE = "extra_block_note"
    const val EXTRA_SESSION_END_MILLIS = "extra_session_end_millis"

    // Debounce window so rapid duplicate TYPE_WINDOW_STATE_CHANGED events
    // for the same package don't stack multiple overlay launches.
    const val OVERLAY_RELAUNCH_DEBOUNCE_MILLIS = 1500L

    // --- SessionForegroundService (persistent countdown notification) ---
    const val ACTION_START_FOREGROUND_SESSION = "com.focusguard.action.START_FOREGROUND_SESSION"
    const val ACTION_STOP_FOREGROUND_SESSION = "com.focusguard.action.STOP_FOREGROUND_SESSION"
    const val EXTRA_FOREGROUND_END_MILLIS = "extra_foreground_end_millis"
    const val EXTRA_FOREGROUND_LABEL = "extra_foreground_label"
    const val NOTIFICATION_CHANNEL_ID = "focusguard_session_channel"
    const val NOTIFICATION_ID = 4201
    // How often the notification text refreshes. Not every second - that
    // would be a battery/notification-spam concern for no real benefit
    // during a 25-90 minute session.
    const val FOREGROUND_UPDATE_INTERVAL_MILLIS = 30_000L
}
