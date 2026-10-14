package com.example.somnia.presentation

import android.content.Context
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.WindowManager
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text
import java.time.LocalTime
import java.time.format.DateTimeFormatter

class AlarmActivity : ComponentActivity() {

    companion object {
        private const val RING_MILLIS = 60 * 1000L
    }

    private val handler = Handler(Looper.getMainLooper())
    private var handled = false
    private lateinit var vibrator: Vibrator

    private val timeout = Runnable {
        if (!handled) {
            handled = true
            AlarmScheduler.snooze(this)
            finish()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setShowWhenLocked(true)
        setTurnScreenOn(true)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        vibrator = findVibrator()
        vibrator.vibrate(VibrationEffect.createWaveform(longArrayOf(0, 800, 600), 0))
        handler.postDelayed(timeout, RING_MILLIS)

        val now = LocalTime.now().format(DateTimeFormatter.ofPattern("h:mm"))
        setContent {
            MaterialTheme {
                AlarmScreen(time = now, onStop = ::dismiss)
            }
        }
    }

    private fun findVibrator(): Vibrator {
        return if (Build.VERSION.SDK_INT >= 31) {
            getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }
    }

    private fun dismiss() {
        if (handled) return
        handled = true
        AlarmScheduler.cancel(this)
        finish()
    }

    override fun onDestroy() {
        handler.removeCallbacks(timeout)
        vibrator.cancel()
        super.onDestroy()
    }
}

@Composable
fun AlarmScreen(time: String, onStop: () -> Unit) {
    val text = Color(0xFFEFE6D6)
    val muted = Color(0xFFB3A7C6)
    val primary = Color(0xFFD9C9A8)
    val dark = Color(0xFF20152F)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0E0A16))
            .padding(horizontal = 24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(text = "Good morning", color = muted, fontSize = 13.sp)
        Spacer(Modifier.height(4.dp))
        Text(text = time, color = text, fontSize = 44.sp)
        Spacer(Modifier.height(16.dp))
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(50))
                .background(primary)
                .clickable(onClick = onStop)
                .padding(horizontal = 32.dp, vertical = 12.dp),
            contentAlignment = Alignment.Center,
        ) {
            Text(text = "Stop", color = dark, fontSize = 16.sp)
        }
    }
}