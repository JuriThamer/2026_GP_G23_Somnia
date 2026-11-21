package com.example.somnia.presentation

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent

object AlarmScheduler {

    private const val PREFS = "somnia_alarm"
    private const val KEY_REPEATS = "repeats"
    private const val KEY_WAKE = "wakeAt"
    private const val REQUEST_RING = 7001
    private const val REQUEST_SHOW = 7002
    private const val SNOOZE_MILLIS = 5 * 60 * 1000L

    fun schedule(context: Context, wakeAt: Long, repeats: Int) {
        if (wakeAt <= System.currentTimeMillis()) return
        prefs(context).edit()
            .putInt(KEY_REPEATS, repeats)
            .putLong(KEY_WAKE, wakeAt)
            .apply()
        set(context, wakeAt)
    }

    fun ringNow(context: Context) {
        set(context, System.currentTimeMillis() + 1000L)
    }

    fun snooze(context: Context): Boolean {
        val now = System.currentTimeMillis()
        val left = prefs(context).getInt(KEY_REPEATS, 0)
        if (left > 0) {
            prefs(context).edit().putInt(KEY_REPEATS, left - 1).apply()
            set(context, now + SNOOZE_MILLIS)
            return true
        }
        val wakeAt = prefs(context).getLong(KEY_WAKE, 0L)
        prefs(context).edit().remove(KEY_WAKE).apply()
        if (wakeAt <= now) return false
        set(context, wakeAt)
        return true
    }

    fun cancel(context: Context) {
        val manager = context.getSystemService(AlarmManager::class.java)
        manager.cancel(ringIntent(context))
        prefs(context).edit().clear().apply()
    }

    private fun set(context: Context, at: Long) {
        val manager = context.getSystemService(AlarmManager::class.java)
        val ring = ringIntent(context)
        try {
            manager.setAlarmClock(AlarmManager.AlarmClockInfo(at, showIntent(context)), ring)
        } catch (e: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, ring)
        }
    }

    private fun ringIntent(context: Context): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java)
        return PendingIntent.getBroadcast(
            context,
            REQUEST_RING,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun showIntent(context: Context): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
        return PendingIntent.getActivity(
            context,
            REQUEST_SHOW,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}