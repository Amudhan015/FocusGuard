package com.focusguard.focusguard

import android.content.Intent
import android.os.Bundle
import android.os.CountDownTimer
import android.widget.Button
import android.widget.TextView
import androidx.activity.ComponentActivity
import androidx.activity.OnBackPressedCallback

/**
 * Full-screen block shown when the user opens a blocked app during an
 * active session. Deliberately has no bypass button - ending a session
 * early is still possible, but only through FocusGuard's own mandatory
 * photo+rating flow (see FocusSession.endedEarly), never as a one-tap
 * dismiss from here. Back-press is consumed so it can't be swiped away
 * into the blocked app underneath.
 *
 * Extends ComponentActivity (not AppCompatActivity) deliberately - it's
 * enough for onBackPressedDispatcher and setContentView, and it's
 * already a transitive dependency of Flutter's own embedding, so this
 * doesn't require adding androidx.appcompat to build.gradle.kts.
 */
class BlockOverlayActivity : ComponentActivity() {

    private var countDownTimer: CountDownTimer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_block_overlay)

        val appName = intent.getStringExtra(Constants.EXTRA_APP_NAME) ?: "this app"
        val blockNote = intent.getStringExtra(Constants.EXTRA_BLOCK_NOTE) ?: ""
        val sessionEndMillis = intent.getLongExtra(Constants.EXTRA_SESSION_END_MILLIS, 0L)

        findViewById<TextView>(R.id.blockedAppNameText).text =
            getString(R.string.block_overlay_title, appName)

        val noteView = findViewById<TextView>(R.id.blockNoteText)
        if (blockNote.isBlank()) {
            noteView.visibility = android.view.View.GONE
        } else {
            noteView.text = blockNote
        }

        findViewById<Button>(R.id.openFocusGuardButton).setOnClickListener {
            openFocusGuard()
        }

        startCountdown(sessionEndMillis)

        onBackPressedDispatcher.addCallback(
            this,
            object : OnBackPressedCallback(true) {
                override fun handleOnBackPressed() {
                    // Consume back-press: stay on the overlay rather
                    // than revealing the blocked app underneath.
                }
            },
        )
    }

    private fun startCountdown(sessionEndMillis: Long) {
        val remaining = sessionEndMillis - System.currentTimeMillis()
        val remainingView = findViewById<TextView>(R.id.remainingTimeText)

        if (remaining <= 0) {
            // Session already ended (edge case: overlay launched right
            // at the boundary) - nothing left to block, return home.
            finish()
            return
        }

        countDownTimer = object : CountDownTimer(remaining, 1000L) {
            override fun onTick(millisUntilFinished: Long) {
                val totalSeconds = millisUntilFinished / 1000
                val minutes = totalSeconds / 60
                val seconds = totalSeconds % 60
                remainingView.text = getString(
                    R.string.block_overlay_remaining,
                    minutes,
                    seconds,
                )
            }

            override fun onFinish() {
                finish()
            }
        }.start()
    }

    private fun openFocusGuard() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        if (launchIntent != null) {
            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            startActivity(launchIntent)
        }
        finish()
    }

    override fun onDestroy() {
        super.onDestroy()
        countDownTimer?.cancel()
    }
}
