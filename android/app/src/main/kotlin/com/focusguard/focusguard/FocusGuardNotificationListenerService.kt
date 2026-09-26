package com.focusguard.focusguard

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * Cancels (suppresses) notifications from blocked apps while a session
 * is active. Calls and messages always pass through - checked two ways:
 * the notification's own Notification.CATEGORY_CALL / CATEGORY_MESSAGE
 * (works across OEM dialer/SMS apps without hardcoding package names),
 * OR explicit membership in the user-configured whitelist from Settings.
 */
class FocusGuardNotificationListenerService : NotificationListenerService() {

    private lateinit var prefsStore: PrefsStore

    override fun onCreate() {
        super.onCreate()
        prefsStore = PrefsStore(this)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        if (sbn.packageName == packageName) return // never suppress our own notifications

        if (!prefsStore.isSessionActive()) return
        if (prefsStore.getSessionEndTimeMillis() <= System.currentTimeMillis()) return

        val blockedPackages = prefsStore.getBlockedPackages()
        if (sbn.packageName !in blockedPackages) return

        if (isAlwaysAllowed(sbn)) return

        cancelNotification(sbn.key)
    }

    private fun isAlwaysAllowed(sbn: StatusBarNotification): Boolean {
        val category = sbn.notification?.category
        if (category == Notification.CATEGORY_CALL || category == Notification.CATEGORY_MESSAGE) {
            return true
        }
        return sbn.packageName in prefsStore.getNotificationWhitelist()
    }
}
