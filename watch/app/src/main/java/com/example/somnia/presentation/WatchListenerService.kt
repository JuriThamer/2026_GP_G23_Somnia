package com.example.somnia.presentation

import android.net.Uri
import android.os.Handler
import android.os.Looper
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.PutDataRequest
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import java.io.File

class WatchListenerService : WearableListenerService() {

    override fun onMessageReceived(event: MessageEvent) {
        val parts = String(event.data).split('|')
        val sessionId = parts[0]
        Handler(Looper.getMainLooper()).post {
            when (event.path) {
                "/somnia/start" -> {
                    startRecording(sessionId)
                    scheduleAlarm(parts)
                    FileSender.sendPending(applicationContext, sessionId)
                }
                "/somnia/stop" -> {
                    AlarmScheduler.cancel(applicationContext)
                    stopRecording()
                }
                "/somnia/alarm" -> AlarmScheduler.ringNow(applicationContext)
                "/somnia/ack" -> deleteSession(sessionId)
            }
        }
    }

    private fun scheduleAlarm(parts: List<String>) {
        val context = applicationContext
        val reader = SensorReader.shared(context)
        val wakeAt = parts.getOrNull(1)?.toLongOrNull()
        val window = parts.getOrNull(2)?.toIntOrNull() ?: 0
        val smart = parts.getOrNull(3) == "1"
        val repeats = parts.getOrNull(4)?.toIntOrNull() ?: 0
        if (wakeAt == null) {
            AlarmScheduler.cancel(context)
            reader.clearWindow()
            return
        }
        AlarmScheduler.schedule(context, wakeAt, repeats)
        if (smart && window > 0) {
            reader.setWindow(wakeAt - window * 60 * 1000L, wakeAt)
        } else {
            reader.clearWindow()
        }
    }

    private fun startRecording(sessionId: String) {
        val context = applicationContext
        val reader = SensorReader.shared(context)
        val current = reader.sessionId
        if (!reader.state.recording || current == null || current == sessionId) {
            begin(sessionId)
            return
        }
        reader.stop { folder ->
            if (folder == null) {
                begin(sessionId)
            } else {
                FileSender.send(context, folder) { begin(sessionId) }
            }
        }
    }

    private fun begin(sessionId: String) {
        Handler(Looper.getMainLooper()).post {
            try {
                RecordingService.start(applicationContext, sessionId)
            } catch (e: Exception) {
                SensorReader.shared(applicationContext).startWhenReady(sessionId)
            }
        }
    }

    private fun stopRecording() {
        val context = applicationContext
        SensorReader.shared(context).stop { folder ->
            if (folder == null) {
                RecordingService.stop(context)
            } else {
                FileSender.send(context, folder) {
                    RecordingService.stop(context)
                    FileSender.sendPending(context, folder.name)
                }
            }
        }
    }

    private fun deleteSession(sessionId: String) {
        if (sessionId.isBlank() || sessionId.contains('/') || sessionId.contains("..")) return
        val context = applicationContext
        File(context.filesDir, "sessions/$sessionId").deleteRecursively()
        File(context.cacheDir, "$sessionId.zip").delete()
        val uri = Uri.Builder()
            .scheme(PutDataRequest.WEAR_URI_SCHEME)
            .path("/somnia/session/$sessionId")
            .build()
        Wearable.getDataClient(context).deleteDataItems(uri)
    }
}