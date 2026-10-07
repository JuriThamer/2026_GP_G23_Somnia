package com.example.somnia.presentation

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.samsung.android.service.health.tracking.ConnectionListener
import com.samsung.android.service.health.tracking.HealthTracker
import com.samsung.android.service.health.tracking.HealthTrackerException
import com.samsung.android.service.health.tracking.HealthTrackingService
import com.samsung.android.service.health.tracking.data.DataPoint
import com.samsung.android.service.health.tracking.data.HealthTrackerType
import com.samsung.android.service.health.tracking.data.ValueKey
import java.util.Collections

data class HeartSample(
    val timestamp: Long,
    val bpm: Int,
    val status: Int,
    val ibi: List<Int>,
)

data class TemperatureSample(
    val timestamp: Long,
    val skin: Float,
    val ambient: Float,
    val status: Int,
)

data class MotionSample(
    val timestamp: Long,
    val x: Int,
    val y: Int,
    val z: Int,
)

data class SensorState(
    val connected: Boolean = false,
    val recording: Boolean = false,
    val heartRate: Int? = null,
    val skinTemperature: Float? = null,
    val heartCount: Int = 0,
    val temperatureCount: Int = 0,
    val motionCount: Int = 0,
    val message: String = "Connecting",
)

class SensorReader private constructor(private val context: Context) {

    companion object {
        @Volatile
        private var instance: SensorReader? = null

        fun shared(context: Context): SensorReader {
            return instance ?: synchronized(this) {
                instance ?: SensorReader(context.applicationContext).also { instance = it }
            }
        }
    }

    var state by mutableStateOf(SensorState())
        private set

    val heartSamples: MutableList<HeartSample> =
        Collections.synchronizedList(mutableListOf())
    val temperatureSamples: MutableList<TemperatureSample> =
        Collections.synchronizedList(mutableListOf())
    val motionSamples: MutableList<MotionSample> =
        Collections.synchronizedList(mutableListOf())

    private val handler = Handler(Looper.getMainLooper())
    private var service: HealthTrackingService? = null
    private var heartTracker: HealthTracker? = null
    private var temperatureTracker: HealthTracker? = null
    private var motionTracker: HealthTracker? = null
    private var pendingStart = false

    private fun update(change: SensorState.() -> SensorState) {
        handler.post { state = state.change() }
    }

    fun showMessage(text: String) {
        update { copy(message = text) }
    }

    private val connectionListener = object : ConnectionListener {
        override fun onConnectionSuccess() {
            update { copy(connected = true, message = "Ready") }
            handler.post {
                if (pendingStart) {
                    pendingStart = false
                    start()
                }
            }
        }

        override fun onConnectionEnded() {
            update { copy(connected = false, recording = false, message = "Disconnected") }
        }

        override fun onConnectionFailed(e: HealthTrackerException) {
            val text = when (e.errorCode) {
                HealthTrackerException.PACKAGE_NOT_INSTALLED -> "Health Platform not installed"
                HealthTrackerException.OLD_PLATFORM_VERSION -> "Update Health Platform"
                else -> "Connection failed"
            }
            update { copy(connected = false, message = text) }
        }
    }

    private fun errorText(error: HealthTracker.TrackerError): String {
        return when (error) {
            HealthTracker.TrackerError.PERMISSION_ERROR -> "Sensor permission needed"
            HealthTracker.TrackerError.SDK_POLICY_ERROR -> "Turn on Health Platform developer mode"
            else -> "Sensor error"
        }
    }

    private val heartListener = object : HealthTracker.TrackerEventListener {
        override fun onDataReceived(list: List<DataPoint>) {
            var latest: Int? = null
            for (point in list) {
                runCatching {
                    val bpm = point.getValue(ValueKey.HeartRateSet.HEART_RATE) ?: 0
                    val status = point.getValue(ValueKey.HeartRateSet.HEART_RATE_STATUS) ?: 0
                    val ibi = point.getValue(ValueKey.HeartRateSet.IBI_LIST) ?: emptyList()
                    heartSamples.add(HeartSample(point.timestamp, bpm, status, ibi.toList()))
                    if (bpm > 0) latest = bpm
                }
            }
            val count = heartSamples.size
            val value = latest
            update { copy(heartRate = value ?: heartRate, heartCount = count) }
        }

        override fun onFlushCompleted() {}

        override fun onError(error: HealthTracker.TrackerError) {
            showMessage(errorText(error))
        }
    }

    private val temperatureListener = object : HealthTracker.TrackerEventListener {
        override fun onDataReceived(list: List<DataPoint>) {
            var latest: Float? = null
            for (point in list) {
                runCatching {
                    val skin = point.getValue(ValueKey.SkinTemperatureSet.OBJECT_TEMPERATURE) ?: 0f
                    val ambient = point.getValue(ValueKey.SkinTemperatureSet.AMBIENT_TEMPERATURE) ?: 0f
                    val status = point.getValue(ValueKey.SkinTemperatureSet.STATUS) ?: 0
                    temperatureSamples.add(TemperatureSample(point.timestamp, skin, ambient, status))
                    if (skin > 0f) latest = skin
                }
            }
            val count = temperatureSamples.size
            val value = latest
            update { copy(skinTemperature = value ?: skinTemperature, temperatureCount = count) }
        }

        override fun onFlushCompleted() {}

        override fun onError(error: HealthTracker.TrackerError) {
            showMessage(errorText(error))
        }
    }

    private val motionListener = object : HealthTracker.TrackerEventListener {
        override fun onDataReceived(list: List<DataPoint>) {
            for (point in list) {
                runCatching {
                    val x = point.getValue(ValueKey.AccelerometerSet.ACCELEROMETER_X) ?: 0
                    val y = point.getValue(ValueKey.AccelerometerSet.ACCELEROMETER_Y) ?: 0
                    val z = point.getValue(ValueKey.AccelerometerSet.ACCELEROMETER_Z) ?: 0
                    motionSamples.add(MotionSample(point.timestamp, x, y, z))
                }
            }
            val count = motionSamples.size
            update { copy(motionCount = count) }
        }

        override fun onFlushCompleted() {}

        override fun onError(error: HealthTracker.TrackerError) {
            showMessage(errorText(error))
        }
    }

    fun connect() {
        if (service != null) return
        val created = HealthTrackingService(connectionListener, context)
        service = created
        created.connectService()
    }

    private fun openTracker(
        source: HealthTrackingService,
        supported: List<HealthTrackerType>,
        type: HealthTrackerType,
        listener: HealthTracker.TrackerEventListener,
    ): HealthTracker? {
        if (!supported.contains(type)) return null
        val tracker = source.getHealthTracker(type)
        handler.post { tracker.setEventListener(listener) }
        return tracker
    }

    fun startWhenReady() {
        if (state.connected) {
            start()
        } else {
            pendingStart = true
            connect()
        }
    }

    fun start() {
        val source = service ?: return
        if (!state.connected || state.recording) return

        heartSamples.clear()
        temperatureSamples.clear()
        motionSamples.clear()

        try {
            val supported = source.trackingCapability.supportHealthTrackerTypes
            heartTracker = openTracker(
                source, supported, HealthTrackerType.HEART_RATE_CONTINUOUS, heartListener,
            )
            temperatureTracker = openTracker(
                source, supported, HealthTrackerType.SKIN_TEMPERATURE_CONTINUOUS, temperatureListener,
            )
            motionTracker = openTracker(
                source, supported, HealthTrackerType.ACCELEROMETER_CONTINUOUS, motionListener,
            )
            update {
                copy(
                    recording = true,
                    heartRate = null,
                    skinTemperature = null,
                    heartCount = 0,
                    temperatureCount = 0,
                    motionCount = 0,
                    message = "Recording",
                )
            }
        } catch (e: Exception) {
            closeTrackers()
            showMessage("Could not start sensors")
        }
    }

    private fun closeTrackers() {
        val trackers = listOf(heartTracker, temperatureTracker, motionTracker)
        heartTracker = null
        temperatureTracker = null
        motionTracker = null
        handler.post {
            for (tracker in trackers) {
                runCatching { tracker?.unsetEventListener() }
            }
        }
    }

    fun stop() {
        pendingStart = false
        if (!state.recording) return
        closeTrackers()
        update { copy(recording = false, message = "Stopped") }
    }

    fun disconnect() {
        closeTrackers()
        val source = service
        service = null
        handler.post { runCatching { source?.disconnectService() } }
    }
}

