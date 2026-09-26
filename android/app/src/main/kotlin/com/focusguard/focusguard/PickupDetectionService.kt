package com.focusguard.focusguard

import android.app.Service
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.IBinder
import android.util.Log

/**
 * Detects phone pickups using the proximity sensor.
 * A pickup is detected when the proximity sensor transitions from far to near
 * (or vice versa) with a debounce to avoid multiple detections for the same movement.
 */
class PickupDetectionService : Service(), SensorEventListener {

    private lateinit var sensorManager: SensorManager
    private var proximitySensor: Sensor? = null
    private lateinit var prefsStore: PrefsStore

    // Debounce settings to avoid multiple detections for the same pickup motion
    private val PICKUP_DEBOUNCE_MILLIS = 1500L
    private var lastPickupTimestamp: Long = 0

    // Track previous proximity state to detect transitions
    private var wasNear = false

    private var isSessionActive = false

    override fun onCreate() {
        super.onCreate()
        prefsStore = PrefsStore(this)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        proximitySensor = sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY)
        // Initialize wasNear based on initial sensor reading
        proximitySensor?.let {
            wasNear = it.maximumRange / 2 > 0 // Default to false (far) if no valid reading
        }
        Log.i("FocusGuard", "PickupDetectionService created")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        updateSessionState()
        if (!isSessionActive) {
            // No active session, stop the service.
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        super.onDestroy()
        unregisterListeners()
        Log.i("FocusGuard", "PickupDetectionService destroyed")
    }

    private fun updateSessionState() {
        val wasActive = isSessionActive
        isSessionActive = prefsStore.isSessionActive() && prefsStore.getSessionEndTimeMillis() > System.currentTimeMillis()
        if (isSessionActive && !wasActive) {
            registerListeners()
        } else if (!isSessionActive && wasActive) {
            unregisterListeners()
        }
    }

    private fun registerListeners() {
        proximitySensor?.let {
            sensorManager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            Log.i("FocusGuard", "Proximity sensor listener registered")
        }
    }

    private fun unregisterListeners() {
        sensorManager.unregisterListener(this)
        Log.i("FocusGuard", "Proximity sensor listener unregistered")
    }

    // SensorEventListener callbacks
    override fun onSensorChanged(event: SensorEvent?) {
        if (!isSessionActive) return
        if (event == null || event.sensor.type != Sensor.TYPE_PROXIMITY) return

        val distance = event.values[0]
        val maxRange = event.sensor.maximumRange
        val isNear = distance < maxRange / 2

        // Check for state transition (far to near or near to far)
        val transitionDetected = isNear != wasNear

        // Apply debounce only when there's an actual transition
        if (transitionDetected) {
            val now = System.currentTimeMillis()
            if (now - lastPickupTimestamp > PICKUP_DEBOUNCE_MILLIS) {
                lastPickupTimestamp = now
                // Update state for next comparison
                wasNear = isNear
                val transitionLabel = if (isNear) "near" else "far"
                Log.i("FocusGuard", "Pickup detected via proximity sensor: transition to $transitionLabel, distance=$distance, maxRange=$maxRange")
                prefsStore.enqueuePhonePickup(now)
            }
        } else {
            // No transition, just update the current state for next comparison
            wasNear = isNear
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not used
    }
}