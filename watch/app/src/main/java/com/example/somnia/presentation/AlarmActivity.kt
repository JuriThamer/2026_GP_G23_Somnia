package com.example.somnia.presentation

import android.os.Bundle
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setShowWhenLocked(true)
        setTurnScreenOn(true)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        val now = LocalTime.now().format(DateTimeFormatter.ofPattern("h:mm"))
        setContent {
            MaterialTheme {
                AlarmScreen(time = now, onStop = ::dismiss)
            }
        }
    }

    private fun dismiss() {
        Ringer.dismiss(this)
        finish()
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