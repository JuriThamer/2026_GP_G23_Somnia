package com.example.somnia.presentation

import android.content.Context
import android.os.Handler
import android.os.HandlerThread
import java.io.File

class BatchWriter(context: Context, sessionId: String) {

    companion object {
        private const val BATCH_MILLIS = 10 * 60 * 1000L
    }

    val folder = File(context.filesDir, "sessions/$sessionId").apply { mkdirs() }

    private val lock = Any()
    private val heart = StringBuilder()
    private val motion = StringBuilder()
    private val temperature = StringBuilder()
    private var batch = 0

    private val thread = HandlerThread("somnia-writer").apply { start() }
    private val handler = Handler(thread.looper)

    private val tick = object : Runnable {
        override fun run() {
            flush()
            handler.postDelayed(this, BATCH_MILLIS)
        }
    }

    fun begin() {
        batch = folder.listFiles()?.count { it.name.startsWith("heart_") } ?: 0
        handler.postDelayed(tick, BATCH_MILLIS)
    }

    fun addHeart(timestamp: Long, bpm: Int, status: Int, ibi: List<Int>) {
        synchronized(lock) {
            heart.append(timestamp).append(',')
                .append(bpm).append(',')
                .append(status).append(',')
                .append(ibi.joinToString(";")).append('\n')
        }
    }

    fun addMotion(timestamp: Long, x: Int, y: Int, z: Int) {
        synchronized(lock) {
            motion.append(timestamp).append(',')
                .append(x).append(',')
                .append(y).append(',')
                .append(z).append('\n')
        }
    }

    fun addTemperature(timestamp: Long, skin: Float, ambient: Float, status: Int) {
        synchronized(lock) {
            temperature.append(timestamp).append(',')
                .append(skin).append(',')
                .append(ambient).append(',')
                .append(status).append('\n')
        }
    }

    private fun flush() {
        val heartRows: String
        val motionRows: String
        val temperatureRows: String
        synchronized(lock) {
            heartRows = heart.toString()
            motionRows = motion.toString()
            temperatureRows = temperature.toString()
            heart.setLength(0)
            motion.setLength(0)
            temperature.setLength(0)
        }
        if (heartRows.isEmpty() && motionRows.isEmpty() && temperatureRows.isEmpty()) return

        batch += 1
        val number = batch.toString().padStart(3, '0')
        write("heart_$number.csv", "timestamp,bpm,status,ibi\n", heartRows)
        write("motion_$number.csv", "timestamp,x,y,z\n", motionRows)
        write("temp_$number.csv", "timestamp,skin,ambient,status\n", temperatureRows)
    }

    private fun write(name: String, header: String, rows: String) {
        runCatching { File(folder, name).writeText(header + rows) }
    }

    fun finish() {
        handler.removeCallbacks(tick)
        handler.post {
            flush()
            thread.quitSafely()
        }
    }
}