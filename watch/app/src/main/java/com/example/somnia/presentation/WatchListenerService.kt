package com.example.somnia.presentation

import android.os.Handler
import android.os.Looper
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WatchListenerService : WearableListenerService() {

    override fun onMessageReceived(event: MessageEvent) {
        Handler(Looper.getMainLooper()).post {
            when (event.path) {
                "/somnia/start" -> startRecording()
                "/somnia/stop" -> stopRecording()
            }
        }
    }

    private fun startRecording() {
        try {
            RecordingService.start(applicationContext)
        } catch (e: Exception) {
            SensorReader.shared(applicationContext).startWhenReady()
        }
    }

    private fun stopRecording() {
        RecordingService.stop(applicationContext)
        SensorReader.shared(applicationContext).stop()
    }
}