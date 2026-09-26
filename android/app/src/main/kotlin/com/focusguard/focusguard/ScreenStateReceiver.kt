package com.focusguard.focusguard

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Fires on every screen-on event. Only queues a pickup while a focus
 * session is active - screen-on events outside a session aren't
 * meaningful to FocusGuard and would just be noise in history.
 *
 * ACTION_SCREEN_ON is an implicit broadcast Android has restricted from
 * manifest-declared receivers since API 26, so this must be registered
 * dynamically (done in FocusGuardAccessibilityService.onServiceConnected,
 * which is a long-lived context appropriate for holding the registration).
 */
class ScreenStateReceiver(private val prefsStore: PrefsStore) : BroadcastReceiver() {

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != Intent.ACTION_SCREEN_ON) return
        if (!prefsStore.isSessionActive()) return
        if (prefsStore.getSessionEndTimeMillis() <= System.currentTimeMillis()) return

        prefsStore.enqueuePhonePickup(System.currentTimeMillis())
    }
}
