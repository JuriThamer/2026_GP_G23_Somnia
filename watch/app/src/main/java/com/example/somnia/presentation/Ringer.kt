package com.example.somnia.presentation

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationAttributes
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.core.app.NotificationCompat

object Ringer {

    private const val CHANNEL_ID = "somnia_alarm_ring"
    private const val NOTIFICATION_ID = 2
    private const val REQUEST_OPEN = 7003
    private const val REQUEST_STOP = 7004
    private const val REQUEST_TIMEOUT = 7005
    private const val RING_MILLIS = 60 * 1000L

    fun start(context: Context) {
        val app = context.applicationContext
        vibrate(app)
        notify(app)
        scheduleTimeout(app)
    }

    fun dismiss(context: Context) {
        val app = context.applicationContext
        silence(app)
        AlarmScheduler.cancel(app)
        SensorReader.shared(app).clearWindow()
    }

    fun timeout(context: Context) {
        val app = context.applicationContext
        silence(app)
        AlarmScheduler.snooze(app)
    }

    private fun silence(context: Context) {
        vibrator(context).cancel()
        context.getSystemService(NotificationManager::class.java).cancel(NOTIFICATION_ID)
        context.getSystemService(AlarmManager::class.java).cancel(timeoutIntent(context))
    }

    private fun vibrate(context: Context) {
        val effect = VibrationEffect.createWaveform(longArrayOf(0, 800, 600), 0)
        val vibrator = vibrator(context)
        if (Build.VERSION.SDK_INT >= 33) {
            vibrator.vibrate(
                effect,
                VibrationAttributes.createForUsage(VibrationAttributes.USAGE_ALARM),
            )
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(
                effect,
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ALARM).build(),
            )
        }
    }

    private fun vibrator(context: Context): Vibrator {
        return if (Build.VERSION.SDK_INT >= 31) {
            context.getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private fun notify(context: Context) {
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                "Alarm",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                enableVibration(false)
                setSound(null, null)
            },
        )

        val open = PendingIntent.getActivity(
            context,
            REQUEST_OPEN,
            Intent(context, AlarmActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val stop = PendingIntent.getBroadcast(
            context,
            REQUEST_STOP,
            Intent(context, AlarmReceiver::class.java).setAction(AlarmReceiver.ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle("Somnia")
            .setContentText("Good morning")
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setContentIntent(open)
            .addAction(0, "Stop", stop)
            .setDeleteIntent(stop)
            .build()

        manager.notify(NOTIFICATION_ID, notification)
    }

    private fun scheduleTimeout(context: Context) {
        val manager = context.getSystemService(AlarmManager::class.java)
        val at = System.currentTimeMillis() + RING_MILLIS
        val intent = timeoutIntent(context)
        try {
            manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        } catch (e: SecurityException) {
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, intent)
        }
    }

    private fun timeoutIntent(context: Context): PendingIntent {
        return PendingIntent.getBroadcast(
            context,
            REQUEST_TIMEOUT,
            Intent(context, AlarmReceiver::class.java).setAction(AlarmReceiver.ACTION_TIMEOUT),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}