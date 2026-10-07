package com.example.somnia.presentation

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import androidx.wear.compose.material3.Button
import androidx.wear.compose.material3.MaterialTheme
import androidx.wear.compose.material3.Text

class MainActivity : ComponentActivity() {

    private lateinit var reader: SensorReader

    private val permissionRequest = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions(),
    ) { result ->
        if (result.values.all { it }) {
            reader.connect()
        } else {
            reader.showMessage("Sensor permission needed")
        }
    }

    private fun requiredPermissions(): Array<String> {
        return if (Build.VERSION.SDK_INT >= 36) {
            arrayOf(
                "android.permission.health.READ_HEART_RATE",
                "android.permission.health.READ_SKIN_TEMPERATURE",
                Manifest.permission.ACTIVITY_RECOGNITION,
            )
        } else {
            arrayOf(
                Manifest.permission.BODY_SENSORS,
                Manifest.permission.ACTIVITY_RECOGNITION,
            )
        }
    }

    private fun hasPermissions(): Boolean {
        return requiredPermissions().all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        super.onCreate(savedInstanceState)
        setTheme(android.R.style.Theme_DeviceDefault)

        reader = SensorReader.shared(this)

        setContent {
            MaterialTheme {
                WatchScreen(
                    state = reader.state,
                    onToggle = {
                        if (reader.state.recording) reader.stop() else reader.start()
                    },
                )
            }
        }

        if (hasPermissions()) {
            reader.connect()
        } else {
            permissionRequest.launch(requiredPermissions())
        }
    }
}

@Composable
fun WatchScreen(state: SensorState, onToggle: () -> Unit) {
    val text = Color(0xFFEFE6D6)
    val muted = Color(0xFFB3A7C6)
    val heart = state.heartRate?.toString() ?: "--"
    val temperature = state.skinTemperature?.let { String.format("%.1f", it) } ?: "--"

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF0E0A16))
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 24.dp, vertical = 28.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(
            text = state.message,
            color = muted,
            fontSize = 12.sp,
            textAlign = TextAlign.Center,
        )
        Spacer(Modifier.height(4.dp))
        Text(text = heart, color = text, fontSize = 44.sp)
        Text(text = "bpm", color = muted, fontSize = 12.sp)
        Spacer(Modifier.height(4.dp))
        Text(text = "Skin $temperature C", color = text, fontSize = 14.sp)
        Text(
            text = "HR ${state.heartCount}  T ${state.temperatureCount}  M ${state.motionCount}",
            color = muted,
            fontSize = 11.sp,
        )
        Spacer(Modifier.height(8.dp))
        Button(onClick = onToggle, enabled = state.connected) {
            Text(text = if (state.recording) "Stop" else "Start")
        }
    }
}

