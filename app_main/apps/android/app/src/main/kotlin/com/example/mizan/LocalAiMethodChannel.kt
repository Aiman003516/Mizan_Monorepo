package com.example.mizan

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.BinaryMessenger
import org.json.JSONObject

/**
 * Narrow native boundary for future on-device proposal inference.
 *
 * This scaffold intentionally does not load a TFLite/LiteRT interpreter yet.
 * Until the runtime, signed asset, manifest, and Note9 benchmark are approved,
 * every model operation fails closed as unavailable. The channel never exposes
 * SQL, HTTP, filesystem commands, credentials, or arbitrary native methods.
 */
class LocalAiMethodChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL_NAME)

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "load_model" -> loadModel(call, result)
            "infer" -> infer(call, result)
            "unload_model" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    private fun loadModel(call: MethodCall, result: Result) {
        val manifestJson = call.argument<String>("manifest_json")
        if (manifestJson.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "manifest_json is required", null)
            return
        }

        // Parse only to reject malformed channel input. Runtime and asset
        // verification are deliberately not activated by this scaffold.
        try {
            JSONObject(manifestJson)
        } catch (_: Exception) {
            result.error("INVALID_MANIFEST", "Model manifest JSON is invalid", null)
            return
        }

        result.success(
            mapOf(
                "status" to "unavailable",
                "message" to "No verified Android local AI runtime is packaged.",
            ),
        )
    }

    private fun infer(call: MethodCall, result: Result) {
        val text = call.argument<String>("text")
        val locale = call.argument<String>("locale")
        if (text.isNullOrBlank() || locale.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "text and locale are required", null)
            return
        }

        // Do not fall back to cloud inference here. Local-only mode must have
        // zero AI-data egress when the model is unavailable.
        result.success(
            mapOf(
                "status" to "unavailable",
                "message" to "No verified Android local AI runtime is packaged.",
            ),
        )
    }

    companion object {
        const val CHANNEL_NAME = "com.mizan/local_ai"
    }
}
