package com.example.somnia.presentation

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_STOP = "com.example.somnia.ALARM_STOP"
        const val ACTION_TIMEOUT = "com.example.somnia.ALARM_TIMEOUT"
    }

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            ACTION_STOP -> Ringer.dismiss(context)
            ACTION_TIMEOUT -> Ringer.timeout(context)
            else -> Ringer.start(context)
        }
    }
}