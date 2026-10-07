package com.example.somnia

import com.google.android.gms.wearable.CapabilityClient
import com.google.android.gms.wearable.Node
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "somnia/watch")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "findWatch" -> findWatch { node ->
                        if (node == null) {
                            result.success(null)
                        } else {
                            result.success(mapOf("id" to node.id, "name" to node.displayName))
                        }
                    }
                    "send" -> {
                        val path = call.argument<String>("path") ?: ""
                        val data = call.argument<String>("data") ?: ""
                        findWatch { node ->
                            if (node == null) {
                                result.success(false)
                            } else {
                                Wearable.getMessageClient(this)
                                    .sendMessage(node.id, path, data.toByteArray())
                                    .addOnSuccessListener { result.success(true) }
                                    .addOnFailureListener { result.success(false) }
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun findWatch(onResult: (Node?) -> Unit) {
        Wearable.getCapabilityClient(this)
            .getCapability("somnia_watch", CapabilityClient.FILTER_REACHABLE)
            .addOnSuccessListener { info ->
                val nodes = info.nodes
                onResult(nodes.firstOrNull { it.isNearby } ?: nodes.firstOrNull())
            }
            .addOnFailureListener { onResult(null) }
    }
}