package com.example.somnia

import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.Asset
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import java.io.File

class SessionReceiverService : WearableListenerService() {

    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val item = event.dataItem
            val path = item.uri.path ?: continue
            if (!path.startsWith("/somnia/session/")) continue
            val sessionId = path.removePrefix("/somnia/session/")
            val asset = DataMapItem.fromDataItem(item).dataMap.getAsset("data") ?: continue
            val saved = runCatching { save(sessionId, asset) }.isSuccess
            if (saved) acknowledge(item.uri.host, sessionId)
        }
    }

    private fun save(sessionId: String, asset: Asset) {
        val response = Tasks.await(Wearable.getDataClient(this).getFdForAsset(asset))
        val folder = File(filesDir, "sessions").apply { mkdirs() }
        response.inputStream.use { input ->
            File(folder, "$sessionId.zip").outputStream().use { output -> input.copyTo(output) }
        }
    }

    private fun acknowledge(nodeId: String?, sessionId: String) {
        if (nodeId == null) return
        Wearable.getMessageClient(this).sendMessage(nodeId, "/somnia/ack", sessionId.toByteArray())
    }
}