package com.example.somnia.presentation

import android.content.Context
import android.util.Log
import com.google.android.gms.wearable.Wearable

object EpochSender {

    fun send(context: Context, sessionId: String, index: Int, startedAt: Long, body: String) {
        val data = "$sessionId|$index|$startedAt\n$body".toByteArray()
        Wearable.getNodeClient(context).connectedNodes
            .addOnSuccessListener { nodes ->
                val nearby = nodes.filter { it.isNearby }
                Log.d("SomniaEpoch", "send index=$index nodes=${nodes.size} nearby=${nearby.size}")
                for (node in nearby) {
                    Wearable.getMessageClient(context).sendMessage(node.id, "/somnia/epoch", data)
                        .addOnSuccessListener { Log.d("SomniaEpoch", "sent index=$index") }
                        .addOnFailureListener { Log.d("SomniaEpoch", "failed index=$index ${it.message}") }
                }
            }
            .addOnFailureListener { Log.d("SomniaEpoch", "nodes failed ${it.message}") }
    }
}