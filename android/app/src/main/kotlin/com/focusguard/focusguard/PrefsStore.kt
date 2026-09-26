package com.focusguard.focusguard

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Typed wrapper over the app's SharedPreferences file, used by both the
 * MainActivity Dart bridge and the background services. Keeping every
 * read/write here means the JSON shape is defined in exactly one place.
 */
class PrefsStore(context: Context) {

    private val prefs: SharedPreferences =
        context.applicationContext.getSharedPreferences(Constants.PREFS_NAME, Context.MODE_PRIVATE)

    // ---------------------------------------------------------------
    // Blocked packages + notes
    // ---------------------------------------------------------------

    fun setBlockedPackages(packages: List<String>, notes: Map<String, String>) {
        val packagesJson = JSONArray()
        packages.forEach { packagesJson.put(it) }

        val notesJson = JSONObject()
        notes.forEach { (pkg, note) -> notesJson.put(pkg, note) }

        prefs.edit()
            .putString(Constants.KEY_BLOCKED_PACKAGES, packagesJson.toString())
            .putString(Constants.KEY_BLOCK_NOTES, notesJson.toString())
            .apply()
    }

    fun getBlockedPackages(): Set<String> {
        val raw = prefs.getString(Constants.KEY_BLOCKED_PACKAGES, null) ?: return emptySet()
        val array = JSONArray(raw)
        return (0 until array.length()).map { array.getString(it) }.toSet()
    }

    fun getBlockNote(packageName: String): String? {
        val raw = prefs.getString(Constants.KEY_BLOCK_NOTES, null) ?: return null
        val obj = JSONObject(raw)
        return if (obj.has(packageName)) obj.getString(packageName) else null
    }

    // ---------------------------------------------------------------
    // Notification whitelist (calls/messaging pass through even when blocked)
    // ---------------------------------------------------------------

    fun setNotificationWhitelist(packages: List<String>) {
        val json = JSONArray()
        packages.forEach { json.put(it) }
        prefs.edit().putString(Constants.KEY_NOTIFICATION_WHITELIST, json.toString()).apply()
    }

    fun getNotificationWhitelist(): Set<String> {
        val raw = prefs.getString(Constants.KEY_NOTIFICATION_WHITELIST, null) ?: return emptySet()
        val array = JSONArray(raw)
        return (0 until array.length()).map { array.getString(it) }.toSet()
    }

    // ---------------------------------------------------------------
    // Active session state
    // ---------------------------------------------------------------

    fun setSessionActive(active: Boolean, endTimeMillis: Long) {
        prefs.edit()
            .putBoolean(Constants.KEY_SESSION_ACTIVE, active)
            .putLong(Constants.KEY_SESSION_END_TIME_MILLIS, endTimeMillis)
            .apply()
    }

    fun isSessionActive(): Boolean = prefs.getBoolean(Constants.KEY_SESSION_ACTIVE, false)

    fun getSessionEndTimeMillis(): Long = prefs.getLong(Constants.KEY_SESSION_END_TIME_MILLIS, 0L)

    // ---------------------------------------------------------------
    // Escape attempt queue
    // ---------------------------------------------------------------

    @Synchronized
    fun enqueueEscapeAttempt(packageName: String, appName: String, timestampMillis: Long) {
        val array = JSONArray(prefs.getString(Constants.KEY_PENDING_ESCAPE_ATTEMPTS, "[]"))
        val obj = JSONObject()
        obj.put(Constants.FIELD_PACKAGE_NAME, packageName)
        obj.put(Constants.FIELD_APP_NAME, appName)
        obj.put(Constants.FIELD_TIMESTAMP_MILLIS, timestampMillis)
        array.put(obj)
        prefs.edit().putString(Constants.KEY_PENDING_ESCAPE_ATTEMPTS, array.toString()).apply()
    }

    @Synchronized
    fun drainEscapeAttempts(): List<Map<String, Any>> {
        val raw = prefs.getString(Constants.KEY_PENDING_ESCAPE_ATTEMPTS, "[]") ?: "[]"
        val array = JSONArray(raw)
        val result = mutableListOf<Map<String, Any>>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            result.add(
                mapOf(
                    Constants.FIELD_PACKAGE_NAME to obj.getString(Constants.FIELD_PACKAGE_NAME),
                    Constants.FIELD_APP_NAME to obj.getString(Constants.FIELD_APP_NAME),
                    Constants.FIELD_TIMESTAMP_MILLIS to obj.getLong(Constants.FIELD_TIMESTAMP_MILLIS),
                )
            )
        }
        prefs.edit().putString(Constants.KEY_PENDING_ESCAPE_ATTEMPTS, "[]").apply()
        return result
    }

    // ---------------------------------------------------------------
    // Phone pickup (screen-on) queue
    // ---------------------------------------------------------------

    @Synchronized
    fun enqueuePhonePickup(timestampMillis: Long) {
        val array = JSONArray(prefs.getString(Constants.KEY_PENDING_PHONE_PICKUPS, "[]"))
        val obj = JSONObject()
        obj.put(Constants.FIELD_TIMESTAMP_MILLIS, timestampMillis)
        array.put(obj)
        prefs.edit().putString(Constants.KEY_PENDING_PHONE_PICKUPS, array.toString()).apply()
    }

    @Synchronized
    fun drainPhonePickups(): List<Map<String, Any>> {
        val raw = prefs.getString(Constants.KEY_PENDING_PHONE_PICKUPS, "[]") ?: "[]"
        val array = JSONArray(raw)
        val result = mutableListOf<Map<String, Any>>()
        for (i in 0 until array.length()) {
            val obj = array.getJSONObject(i)
            result.add(mapOf(Constants.FIELD_TIMESTAMP_MILLIS to obj.getLong(Constants.FIELD_TIMESTAMP_MILLIS)))
        }
        prefs.edit().putString(Constants.KEY_PENDING_PHONE_PICKUPS, "[]").apply()
        return result
    }
}
