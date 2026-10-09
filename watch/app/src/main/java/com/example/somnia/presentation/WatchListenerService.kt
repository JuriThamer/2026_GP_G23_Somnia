package com.example.somnia.presentation

import android.os.Handler
import android.os.Looper
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WatchListenerService : WearableListenerService() {

    override fun onMessageReceived(event: MessageEvent) {
        val sessionId = String(event.data)
        Handler(Looper.getMainLooper()).post {
            when (event.path) {
                "/somnia/start" -> startRecording(sessionId)
                "/somnia/stop" -> stopRecording()
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
        RecordingService.stop(applicationContext)
        SensorReader.shared(applicationContext).stop()
    }
}