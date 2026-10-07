package com.example.somnia.presentation

import android.os.Handler
import android.os.Looper
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService

class WatchListenerService : WearableListenerService() {

    override fun onMessageReceived(event: MessageEvent) {
        val reader = SensorReader.shared(applicationContext)
        Handler(Looper.getMainLooper()).post {
            when (event.path) {
                "/somnia/start" -> reader.startWhenReady()
                "/somnia/stop" -> reader.stop()
            }
        }
    }
}