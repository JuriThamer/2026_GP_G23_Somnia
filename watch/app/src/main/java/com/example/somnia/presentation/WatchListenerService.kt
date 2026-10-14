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
        val sessionId = String(event.data)
        Handler(Looper.getMainLooper()).post {
            when (event.path) {
                "/somnia/start" -> startRecording(sessionId)
                "/somnia/stop" -> stopRecording()
                "/somnia/ack" -> deleteSession(sessionId)
            }
        }
    }

    private fun startRecording(sessionId: String) {
        try {
            RecordingService.start(applicationContext, sessionId)
        } catch (e: Exception) {
            SensorReader.shared(applicationContext).startWhenReady(sessionId)
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