package com.example.somnia.presentation

import android.content.Context
import android.os.ParcelFileDescriptor
import android.os.PowerManager
import android.util.Log
import com.google.android.gms.wearable.Asset
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import java.io.File
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

object FileSender {

    private const val TAG = "SomniaFile"
    private const val SEND_MILLIS = 10 * 60 * 1000L

    private val sending = mutableSetOf<String>()

    fun send(context: Context, folder: File, onDone: (Boolean) -> Unit) {
        val name = folder.name
        synchronized(sending) {
            if (!sending.add(name)) {
                onDone(false)
                return
            }
        }

        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val lock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "somnia:send")
        lock.acquire(SEND_MILLIS)

        val finish = { ok: Boolean ->
            synchronized(sending) { sending.remove(name) }
            if (lock.isHeld) lock.release()
            onDone(ok)
        }

        val started = System.currentTimeMillis()
        val zip = runCatching { pack(context, folder) }.getOrNull()
        if (zip == null) {
            Log.d(TAG, "pack failed $name")
            finish(false)
            return
        }
        Log.d(TAG, "packed $name bytes=${zip.length()} ms=${System.currentTimeMillis() - started}")

        val descriptor = runCatching {
            ParcelFileDescriptor.open(zip, ParcelFileDescriptor.MODE_READ_ONLY)
        }.getOrNull()
        if (descriptor == null) {
            Log.d(TAG, "open failed $name")
            finish(false)
            return
        }

        try {
            val request = PutDataMapRequest.create("/somnia/session/$name").apply {
                dataMap.putAsset("data", Asset.createFromFd(descriptor))
                dataMap.putLong("sentAt", System.currentTimeMillis())
            }.asPutDataRequest().setUrgent()

            Wearable.getDataClient(context).putDataItem(request).addOnCompleteListener { task ->
                runCatching { descriptor.close() }
                Log.d(TAG, "put $name ok=${task.isSuccessful} ${task.exception?.message ?: ""}")
                finish(task.isSuccessful)
            }
        } catch (e: Exception) {
            runCatching { descriptor.close() }
            Log.d(TAG, "put failed $name ${e.message}")
            finish(false)
        }
    }

    fun sendPending(context: Context, except: String?) {
        val root = File(context.filesDir, "sessions")
        val current = SensorReader.shared(context).sessionId
        val folders = root.listFiles()
            ?.filter { it.isDirectory && it.name != except && it.name != current }
            ?.filter { it.listFiles()?.isNotEmpty() == true }
            ?: emptyList()
        if (folders.isEmpty()) return
        Thread {
            for (folder in folders) {
                Log.d(TAG, "resend ${folder.name}")
                send(context, folder) {}
            }
        }.start()
    }

    private fun pack(context: Context, folder: File): File {
        val zip = File(context.cacheDir, "${folder.name}.zip")
        val files = folder.listFiles()?.filter { it.isFile }?.sortedBy { it.name } ?: emptyList()
        ZipOutputStream(zip.outputStream().buffered()).use { out ->
            for (file in files) {
                out.putNextEntry(ZipEntry(file.name))
                file.inputStream().use { it.copyTo(out) }
                out.closeEntry()
            }
        }
        return zip
    }
}