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
import java.util.concurrent.atomic.AtomicInteger

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

    private val heartCount = AtomicInteger()
    private val temperatureCount = AtomicInteger()
    private val motionCount = AtomicInteger()

    @Volatile
    private var writer: BatchWriter? = null

    private val handler = Handler(Looper.getMainLooper())
    private var service: HealthTrackingService? = null
    private var heartTracker: HealthTracker? = null
    private var temperatureTracker: HealthTracker? = null
    private var motionTracker: HealthTracker? = null
    private var pendingStart = false
    private var pendingSession: String? = null

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
                    start(pendingSession)
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
                    writer?.addHeart(point.timestamp, bpm, status, ibi.toList())
                    heartCount.incrementAndGet()
                    if (bpm > 0) latest = bpm
                }
            }
            val count = heartCount.get()
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
                    writer?.addTemperature(point.timestamp, skin, ambient, status)
                    temperatureCount.incrementAndGet()
                    if (skin > 0f) latest = skin
                }
            }
            val count = temperatureCount.get()
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
                    writer?.addMotion(point.timestamp, x, y, z)
                    motionCount.incrementAndGet()
                }
            }
            val count = motionCount.get()
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

    fun startWhenReady(sessionId: String? = null) {
        if (state.connected) {
            start(sessionId)
        } else {
            pendingStart = true
            pendingSession = sessionId
            connect()
        }
    }

    fun start(sessionId: String? = null) {
        val source = service ?: return
        if (!state.connected || state.recording) return

        heartCount.set(0)
        temperatureCount.set(0)
        motionCount.set(0)

        val name = sessionId?.takeIf { it.isNotBlank() } ?: "local-${System.currentTimeMillis()}"
        writer = BatchWriter(context, name).also { it.begin() }

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
            closeWriter()
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

    private fun closeWriter() {
        val current = writer
        writer = null
        current?.finish()
    }

    fun stop() {
        pendingStart = false
        pendingSession = null
        if (!state.recording) return
        closeTrackers()
        closeWriter()
        update { copy(recording = false, message = "Stopped") }
    }

    fun disconnect() {
        closeTrackers()
        val source = service
        service = null
        handler.post { runCatching { source?.disconnectService() } }
    }
}