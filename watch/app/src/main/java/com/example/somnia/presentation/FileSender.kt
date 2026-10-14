package com.example.somnia.presentation

import android.content.Context
import android.os.ParcelFileDescriptor
import com.google.android.gms.wearable.Asset
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import java.io.File
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

object FileSender {

    fun send(context: Context, folder: File, onDone: (Boolean) -> Unit) {
        val zip = runCatching { pack(context, folder) }.getOrNull()
        if (zip == null) {
            onDone(false)
            return
        }

        val descriptor = ParcelFileDescriptor.open(zip, ParcelFileDescriptor.MODE_READ_ONLY)
        val request = PutDataMapRequest.create("/somnia/session/${folder.name}").apply {
            dataMap.putAsset("data", Asset.createFromFd(descriptor))
            dataMap.putLong("sentAt", System.currentTimeMillis())
        }.asPutDataRequest().setUrgent()

        Wearable.getDataClient(context).putDataItem(request).addOnCompleteListener { task ->
            runCatching { descriptor.close() }
            onDone(task.isSuccessful)
        }
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