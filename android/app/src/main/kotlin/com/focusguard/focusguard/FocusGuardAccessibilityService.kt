package com.focusguard.focusguard

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.graphics.PixelFormat
import android.os.Build
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.Button
import android.widget.TextView
import android.widget.Toast

/**
 * Watches for foreground-app changes via accessibility events and blocks
 * apps on the blocklist during an active session.
 *
 * IMPORTANT (fixed): blocking is done via a real WindowManager overlay
 * window (TYPE_APPLICATION_OVERLAY), NOT by launching BlockOverlayActivity.
 * A launched Activity is subject to normal windowing-mode placement - in
 * split-screen / multi-window mode, the OS docks it into just ONE of the
 * visible panes, leaving a blocked app fully visible and usable in the
 * other pane. A WindowManager overlay is its own compositor layer above
 * the ENTIRE physical display, so it correctly covers both split-screen
 * panes at once. This is exactly what the SYSTEM_ALERT_WINDOW permission
 * (already declared in the manifest) is for.
 *
 * Detection is also fixed to scan ALL currently visible windows on every
 * event, not just the single window named in the latest
 * TYPE_WINDOW_STATE_CHANGED event. In split-screen, switching focus
 * between two already-visible panes often does not fire a fresh
 * state-changed event for the pane that didn't just receive focus, so a
 * blocked app sitting quietly in the non-focused pane could previously go
 * undetected entirely.
 */
class FocusGuardAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "FocusGuard"
    }

    private lateinit var prefsStore: PrefsStore
    private lateinit var screenStateReceiver: ScreenStateReceiver
    private var receiverRegistered = false

    private var lastBlockedPackage: String? = null
    private var lastOverlayLaunchMillis: Long = 0L
    private var lastBlockedSeenMillis: Long = 0L // Track when we last saw the blocked app

    private var overlayView: View? = null
    private var overlayCountDownTimer: CountDownTimer? = null
    private val windowManager by lazy { getSystemService(WINDOW_SERVICE) as WindowManager }
    private val mainHandler = Handler(Looper.getMainLooper())
    private val dismissalHandler = Handler(Looper.getMainLooper())
    private var dismissalRunnable: Runnable? = null

    override fun onServiceConnected() {
        super.onServiceConnected()
        prefsStore = PrefsStore(this)
        screenStateReceiver = ScreenStateReceiver(prefsStore)
        registerReceiver(screenStateReceiver, IntentFilter(Intent.ACTION_SCREEN_ON))
        receiverRegistered = true

        // Required so `windows` below is actually populated with every
        // visible window - including BOTH panes in split-screen. Without
        // this flag the framework only reliably reports the single active
        // window, which is exactly the gap that let a blocked app hide in
        // the non-focused split pane.
        serviceInfo = serviceInfo.apply {
            flags = flags or AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }

        Log.i(TAG, "AccessibilityService connected and ready.")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return
        // React to TYPE_WINDOWS_CHANGED too (fires whenever the SET of
        // visible windows changes - entering/adjusting split-screen
        // included), not just TYPE_WINDOW_STATE_CHANGED.
        if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED &&
            event.eventType != AccessibilityEvent.TYPE_WINDOWS_CHANGED
        ) {
            return
        }

        if (!prefsStore.isSessionActive()) {
            dismissOverlay()
            return
        }
        if (prefsStore.getSessionEndTimeMillis() <= System.currentTimeMillis()) {
            dismissOverlay()
            return
        }

        // Cancel any pending dismissal when we see a blocked app (prevents premature dismissal during visibility glitches)
        dismissalRunnable?.let { runnable -> dismissalHandler?.removeCallbacks(runnable) }
        dismissalRunnable = null

        val blockedPackages = prefsStore.getBlockedPackages()

        // Scan EVERY currently visible window, not just the event's own
        // package - this is what actually fixes split-screen detection.
        val visiblePackages = getWindows().mapNotNull { it.root?.packageName?.toString() }.toSet()
        Log.d(TAG, "Visible windows=$visiblePackages, blockedPackages=$blockedPackages")

        val blockedVisible: String? = visiblePackages.firstOrNull { it in blockedPackages && it != packageName }

        if (blockedVisible == null) {
            // If overlay is currently shown, check if we should dismiss it
            // Only dismiss if we haven't seen the blocked app for a while
            // to avoid flickering during brief obscurations
            if (overlayView != null) {
                val now = System.currentTimeMillis()
                if (now - lastBlockedSeenMillis > 1000) { // 1 second grace period
                    dismissOverlay()
                }
            }
            return
        }

        // Update when we last saw the blocked app
        lastBlockedSeenMillis = System.currentTimeMillis()

        // If overlay is not shown, show it
        if (overlayView == null) {
            val appName = resolveAppName(blockedVisible)
            Log.i(TAG, "BLOCKING $blockedVisible ($appName) - showing full-screen overlay (split-screen safe).")
            prefsStore.enqueueEscapeAttempt(blockedVisible, appName, System.currentTimeMillis())
            showBlockOverlay(blockedVisible, appName)
        }

        // Update tracking variables
        lastBlockedPackage = blockedVisible
        lastOverlayLaunchMillis = System.currentTimeMillis()
    }

    private fun resolveAppName(pkg: String): String {
        return try {
            val pm = packageManager
            val appInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getApplicationInfo(pkg, PackageManager.ApplicationInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                pm.getApplicationInfo(pkg, 0)
            }
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: PackageManager.NameNotFoundException) {
            pkg
        }
    }

    /**
     * Draws the block screen as a real system overlay window rather than
     * launching an Activity. This is what actually covers BOTH
     * split-screen panes at once - an overlay window is its own
     * compositor layer above the entire display, unlike a launched
     * Activity, which only occupies whatever single windowing-mode slot
     * the OS assigns it.
     */
    private fun showBlockOverlay(packageName: String, appName: String) {
        if (!Settings.canDrawOverlays(this)) {
            Toast.makeText(
                this,
                "Overlay permission missing. Please grant 'Display over other apps' for FocusGuard in Settings.",
                Toast.LENGTH_LONG,
            ).show()
            return
        }

        mainHandler.post {
            removeOverlayView() // replace any existing overlay rather than stacking a second one

            val inflater = LayoutInflater.from(this)
            val view = inflater.inflate(R.layout.activity_block_overlay, null)

            view.findViewById<TextView>(R.id.blockedAppNameText).text =
                getString(R.string.block_overlay_title, appName)

            val note = prefsStore.getBlockNote(packageName) ?: ""
            val noteView = view.findViewById<TextView>(R.id.blockNoteText)
            if (note.isBlank()) {
                noteView.visibility = View.GONE
            } else {
                noteView.text = note
            }

            view.findViewById<Button>(R.id.openFocusGuardButton).setOnClickListener {
                val launchIntent = packageManager.getLaunchIntentForPackage(this.packageName)
                if (launchIntent != null) {
                    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                    startActivity(launchIntent)
                }
                dismissOverlay()
            }

            // Consume the back button so it can't dismiss the overlay and
            // reveal a blocked pane underneath - same intent as the old
            // BlockOverlayActivity's onBackPressedDispatcher override.
            view.isFocusable = true
            view.isFocusableInTouchMode = true
            view.setOnKeyListener { _, keyCode, keyEvent ->
                keyCode == KeyEvent.KEYCODE_BACK && keyEvent.action == KeyEvent.ACTION_UP
            }
            // Consume all touch events to prevent interaction with the blocked app underneath
            view.setOnTouchListener { _, event -> true }

            val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
            }

            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                overlayType,
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                // Deliberately NOT focusable=false / not-touchable: this
                // overlay must intercept every touch and key event across
                // the full display - both split-screen panes underneath
                // included - or it's trivially bypassed exactly like the
                // bug being fixed here.
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.START
            }

            try {
                windowManager.addView(view, params)
                view.requestFocus()
                overlayView = view
                startOverlayCountdown(view, prefsStore.getSessionEndTimeMillis())
                Log.i(TAG, "Block overlay window added.")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add overlay window: ${e.javaClass.simpleName}: ${e.message}", e)
            }
        }
    }

    private fun startOverlayCountdown(view: View, sessionEndMillis: Long) {
        overlayCountDownTimer?.cancel()
        val remaining = sessionEndMillis - System.currentTimeMillis()
        val remainingView = view.findViewById<TextView>(R.id.remainingTimeText)

        if (remaining <= 0) {
            dismissOverlay()
            return
        }

        overlayCountDownTimer = object : CountDownTimer(remaining, 1000L) {
            override fun onTick(millisUntilFinished: Long) {
                val totalSeconds = millisUntilFinished / 1000
                val minutes = totalSeconds / 60
                val seconds = totalSeconds % 60
                remainingView.text = view.context.getString(
                    R.string.block_overlay_remaining,
                    minutes,
                    seconds,
                )
            }

            override fun onFinish() {
                dismissOverlay()
            }
        }.start()
    }

    private fun dismissOverlay() {
        dismissalRunnable?.let { runnable -> dismissalHandler?.removeCallbacks(runnable) }
        dismissalRunnable = null
        mainHandler.post { removeOverlayView() }
    }

    private fun removeOverlayView() {
        overlayCountDownTimer?.cancel()
        overlayCountDownTimer = null
        overlayView?.let { view ->
            try {
                windowManager.removeView(view)
            } catch (e: Exception) {
                // Already detached - safe to ignore.
            }
        }
        overlayView = null
    }

    override fun onInterrupt() {
        dismissOverlay()
    }

    override fun onDestroy() {
        super.onDestroy()
        dismissOverlay()
        if (receiverRegistered) {
            unregisterReceiver(screenStateReceiver)
            receiverRegistered = false
        }
    }
}