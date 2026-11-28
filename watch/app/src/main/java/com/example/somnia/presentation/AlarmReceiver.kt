package com.example.somnia.presentation

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.wearable.Wearable

class AlarmReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_STOP = "com.example.somnia.ALARM_STOP"
        const val ACTION_TIMEOUT = "com.example.somnia.ALARM_TIMEOUT"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_STOP -> Ringer.dismiss(context)
            ACTION_TIMEOUT -> Ringer.timeout(context)
            else -> {
                reportTrigger(context.applicationContext)
                Ringer.start(context)
            }
        }
    }

    private fun reportTrigger(context: Context) {
        val sessionId = SensorReader.shared(context).sessionId ?: return
        val data = "$sessionId|${AlarmScheduler.triggerType(context)}".toByteArray()
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                for (node in nodes.filter { it.isNearby }) {
                    Wearable.getMessageClient(context)
                        .sendMessage(node.id, "/somnia/trigger", data)
                }
            }
    }
}