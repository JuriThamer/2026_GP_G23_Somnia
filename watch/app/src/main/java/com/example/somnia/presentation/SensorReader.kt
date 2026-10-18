package com.example.somnia.presentation

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.util.Log
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
import java.io.File

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
        private const val FLUSH_MILLIS = 60 * 1000L
        private const val WINDOW_FLUSH_MILLIS = 10 * 1000L
        private const val EPOCH_MILLIS = 30 * 1000L
        private const val LATE_MILLIS = 10 * 1000L
        private const val TICK_MILLIS = 5 * 1000L
        private const val STOP_DELAY_MILLIS = 3 * 1000L

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
    val sessionId: String? get() = writer?.folder?.name

    private val handler = Handler(Looper.getMainLooper())
    private var service: HealthTrackingService? = null
    private var heartTracker: HealthTracker? = null
    private var temperatureTracker: HealthTracker? = null
    private var motionTracker: HealthTracker? = null
    private var pendingStart = false
    private var pendingSession: String? = null
    private var stopping = false

    @Volatile
    private var lastFlush = 0L

    private class Epoch {
        val heart = StringBuilder()
        val motion = StringBuilder()
        val temperature = StringBuilder()
    }

    private val epochLock = Any()
    private val epochs = java.util.TreeMap<Int, Epoch>()
    private var nextEpoch = 0

    @Volatile
    private var windowStart = 0L

    @Volatile
    private var windowEnd = 0L

    private val wakeLock by lazy {
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "somnia:stop")
    }

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
                    addEpoch(point.timestamp) { it.heart.append("${point.timestamp},$bpm,$status,${ibi.joinToString(";")}\n") }
                    heartCount.incrementAndGet()
                    if (bpm > 0) latest = bpm
                }
            }
            val count = heartCount.get()
            val value = latest
            update { copy(heartRate = value ?: heartRate, heartCount = count) }
            flushIfDue()
            sendDueEpochs()
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
                    addEpoch(point.timestamp) { it.temperature.append("${point.timestamp},$skin,$ambient,$status\n") }
                    temperatureCount.incrementAndGet()
                    if (skin > 0f) latest = skin
                }
            }
            val count = temperatureCount.get()
            val value = latest
            update { copy(skinTemperature = value ?: skinTemperature, temperatureCount = count) }
            flushIfDue()
            sendDueEpochs()
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
                    addEpoch(point.timestamp) { it.motion.append("${point.timestamp},$x,$y,$z\n") }
                    motionCount.incrementAndGet()
                }
            }
            val count = motionCount.get()
            update { copy(motionCount = count) }
            flushIfDue()
            sendDueEpochs()
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

        lastFlush = System.currentTimeMillis()
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

    private val tick = object : Runnable {
        override fun run() {
            val now = System.currentTimeMillis()
            if (windowEnd == 0L || now >= windowEnd + LATE_MILLIS + EPOCH_MILLIS) return
            if (now < windowStart) {
                handler.postDelayed(this, minOf(windowStart - now, FLUSH_MILLIS))
                return
            }
            flushIfDue()
            sendDueEpochs()
            handler.postDelayed(this, TICK_MILLIS)
        }
    }

    fun setWindow(start: Long, end: Long) {
        synchronized(epochLock) {
            windowStart = start
            windowEnd = end
            epochs.clear()
            nextEpoch = 0
        }
        Log.d("SomniaEpoch", "window start=$start end=$end")
        handler.removeCallbacks(tick)
        if (end > 0L) handler.post(tick)
    }

    fun clearWindow() {
        setWindow(0L, 0L)
    }

    private fun fastFlush(now: Long): Boolean {
        return windowEnd > 0L && now >= windowStart && now < windowEnd + LATE_MILLIS
    }

    private fun addEpoch(timestamp: Long, write: (Epoch) -> Unit) {
        synchronized(epochLock) {
            if (windowEnd == 0L || timestamp < windowStart || timestamp >= windowEnd) return
            val index = ((timestamp - windowStart) / EPOCH_MILLIS).toInt()
            if (index < nextEpoch) return
            write(epochs.getOrPut(index) { Epoch() })
        }
    }

    private fun sendDueEpochs() {
        val id = sessionId ?: return
        val now = System.currentTimeMillis()
        val ready = mutableListOf<Triple<Int, Long, String>>()
        synchronized(epochLock) {
            if (windowEnd == 0L) return
            while (true) {
                val startedAt = windowStart + nextEpoch * EPOCH_MILLIS
                val endsAt = startedAt + EPOCH_MILLIS
                if (endsAt > windowEnd || now < endsAt + LATE_MILLIS) break
                val epoch = epochs.remove(nextEpoch)
                if (epoch != null) {
                    val body = "#heart\n${epoch.heart}#motion\n${epoch.motion}#temp\n${epoch.temperature}"
                    ready.add(Triple(nextEpoch, startedAt, body))
                }
                nextEpoch += 1
            }
        }
        for ((index, startedAt, body) in ready) {
            Log.d("SomniaEpoch", "ready index=$index bytes=${body.length}")
            EpochSender.send(context, id, index, startedAt, body)
        }
    }

    private fun flushIfDue() {
        val now = System.currentTimeMillis()
        val interval = if (fastFlush(now)) WINDOW_FLUSH_MILLIS else FLUSH_MILLIS
        if (now - lastFlush < interval) return
        lastFlush = now
        flushTrackers()
    }

    private fun flushTrackers() {
        val trackers = listOf(heartTracker, temperatureTracker, motionTracker)
        handler.post {
            for (tracker in trackers) {
                runCatching { tracker?.flush() }
            }
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

    private fun closeWriter(onDone: (File?) -> Unit = {}) {
        val current = writer
        writer = null
        if (current == null) {
            onDone(null)
        } else {
            current.finish { folder -> onDone(folder) }
        }
    }

    fun stop(onFinished: (File?) -> Unit = {}) {
        clearWindow()
        pendingStart = false
        pendingSession = null
        if (!state.recording || stopping) {
            onFinished(null)
            return
        }
        stopping = true
        wakeLock.acquire(STOP_DELAY_MILLIS * 3)
        flushTrackers()
        handler.postDelayed({
            closeTrackers()
            closeWriter(onFinished)
            stopping = false
            update { copy(recording = false, message = "Stopped") }
        }, STOP_DELAY_MILLIS)
    }

    fun disconnect() {
        closeTrackers()
        val source = service
        service = null
        handler.post { runCatching { source?.disconnectService() } }
    }
}