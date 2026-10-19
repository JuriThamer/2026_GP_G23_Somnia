package com.example.somnia

import android.util.Log
import com.google.android.gms.tasks.Tasks
import com.google.android.gms.wearable.Asset
import com.google.android.gms.wearable.DataEvent
import com.google.android.gms.wearable.DataEventBuffer
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.Wearable
import com.google.android.gms.wearable.WearableListenerService
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.functions.FirebaseFunctions
import java.io.File
import java.util.Date
import java.util.concurrent.TimeUnit

class SessionReceiverService : WearableListenerService() {

    override fun onDataChanged(events: DataEventBuffer) {
        for (event in events) {
            if (event.type != DataEvent.TYPE_CHANGED) continue
            val item = event.dataItem
            val path = item.uri.path ?: continue
            if (!path.startsWith("/somnia/session/")) continue
            val sessionId = path.removePrefix("/somnia/session/")
            val asset = DataMapItem.fromDataItem(item).dataMap.getAsset("data") ?: continue
            Log.d("SomniaFile", "received $sessionId")
            val result = runCatching { save(sessionId, asset) }
            Log.d("SomniaFile", "saved $sessionId ok=${result.isSuccess} ${result.exceptionOrNull()?.message ?: ""}")
            if (result.isSuccess) acknowledge(item.uri.host, sessionId)
        }
    }

    override fun onMessageReceived(event: MessageEvent) {
        if (event.path != "/somnia/epoch") return
        runCatching { saveEpoch(event) }
            .onFailure { Log.d("SomniaEpoch", "error ${it.message}") }
    }

    private fun save(sessionId: String, asset: Asset) {
        val response = Tasks.await(Wearable.getDataClient(this).getFdForAsset(asset))
        val folder = File(filesDir, "sessions").apply { mkdirs() }
        val file = File(folder, "$sessionId.zip")
        response.inputStream.use { input ->
            file.outputStream().use { output -> input.copyTo(output) }
        }
        Log.d("SomniaFile", "wrote $sessionId bytes=${file.length()}")
    }

    private fun acknowledge(nodeId: String?, sessionId: String) {
        if (nodeId == null) return
        Wearable.getMessageClient(this).sendMessage(nodeId, "/somnia/ack", sessionId.toByteArray())
    }

    private fun saveEpoch(event: MessageEvent) {
        val uid = FirebaseAuth.getInstance().currentUser?.uid
        Log.d("SomniaEpoch", "received bytes=${event.data.size} uid=$uid")
        if (uid == null) return
        val text = String(event.data)
        val header = text.substringBefore('\n').split('|')
        val sessionId = header.getOrNull(0) ?: return
        if (sessionId.isBlank() || sessionId.contains('/')) return
        val index = header.getOrNull(1)?.toIntOrNull() ?: return
        val startedAt = header.getOrNull(2)?.toLongOrNull() ?: return
        val body = text.substringAfter('\n')

        val session = FirebaseFirestore.getInstance()
            .collection("users")
            .document(uid)
            .collection("sleepSessions")
            .document(sessionId)

        val saved = runCatching {
            Tasks.await(
                session.collection("epochs")
                    .document(index.toString().padStart(4, '0'))
                    .set(
                        mapOf(
                            "index" to index,
                            "startedAt" to Timestamp(Date(startedAt)),
                            "receivedAt" to FieldValue.serverTimestamp(),
                            "heart" to section(body, "heart"),
                            "motion" to section(body, "motion"),
                            "temp" to section(body, "temp"),
                        ),
                    ),
                10,
                TimeUnit.SECONDS,
            )
        }
        Log.d("SomniaEpoch", "saved $sessionId index=$index ok=${saved.isSuccess} ${saved.exceptionOrNull()?.message ?: ""}")

        if (saved.isSuccess) {
            val checked = runCatching {
                Tasks.await(
                    FirebaseFunctions.getInstance("me-central1")
                        .getHttpsCallable("check_epoch")
                        .call(mapOf("sessionId" to sessionId, "index" to index)),
                    30,
                    TimeUnit.SECONDS,
                ).getData()
            }
            Log.d("SomniaEpoch", "checked index=$index ok=${checked.isSuccess} result=${checked.getOrNull()} ${checked.exceptionOrNull()?.message ?: ""}")
        }

        val snapshot = Tasks.await(session.get(), 10, TimeUnit.SECONDS)
        Log.d("SomniaEpoch", "session exists=${snapshot.exists()} wakeNow=${snapshot.getBoolean("wakeNow")} trigger=${snapshot.getString("alarmTrigger")}")
        if (snapshot.getBoolean("wakeNow") != true) return
        if (snapshot.getString("alarmTrigger") != null) return
        Wearable.getMessageClient(this).sendMessage(event.sourceNodeId, "/somnia/alarm", ByteArray(0))
        session.update(
            mapOf(
                "alarmTrigger" to "smart",
                "alarmAt" to FieldValue.serverTimestamp(),
            ),
        )
    }

    private fun section(body: String, name: String): String {
        return body.substringAfter("#$name\n", "").substringBefore('#')
    }
}