package com.example.mizan

import android.content.Context
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.BinaryMessenger
import org.json.JSONObject

/**
 * Narrow native boundary for future on-device proposal inference.
 *
 * This boundary verifies the pinned model asset but intentionally does not
 * execute GGUF inference yet. Until the runtime, signed artifact, manifest,
 * and Note9 benchmark are approved, inference fails closed as unavailable.
 * The channel never exposes SQL, HTTP, credentials, or arbitrary methods.
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

        val manifest = try {
            JSONObject(manifestJson)
        } catch (_: Exception) {
            result.error("INVALID_MANIFEST", "Model manifest JSON is invalid", null)
            return
        }

        try {
            val schemaVersion = manifest.optString("schema_version")
            val runtime = manifest.optString("runtime")
            val artifactName = manifest.optString("artifact_name")
            val expectedSha = manifest.optString("sha256").lowercase()
            if (schemaVersion != "mizan.local-ai.model/v2" ||
                runtime != "llama_cpp" ||
                !SAFE_ARTIFACT_NAME.matches(artifactName) ||
                !SHA256.matches(expectedSha)) {
                result.error("INVALID_MANIFEST", "GGUF manifest is invalid", null)
                return
            }

            val assetPath = "flutter_assets/assets/local_ai/$artifactName"
            val destination = File(context.noBackupFilesDir, "mizan_local_ai/$artifactName")
            destination.parentFile?.mkdirs()
            val actualSha = copyAndHashAsset(assetPath, destination)
            if (actualSha != expectedSha) {
                destination.delete()
                result.error("CHECKSUM_MISMATCH", "Local AI asset checksum mismatch", null)
                return
            }

            // Asset verification is live; inference remains disabled until a
            // reviewed llama.cpp native library is packaged for this app.
            result.success(
                mapOf(
                    "status" to "unavailable",
                    "message" to "GGUF asset verified, but no approved Android inference runtime is packaged.",
                    "artifact_path" to destination.absolutePath,
                ),
            )
        } catch (error: Exception) {
            result.error("ASSET_VERIFICATION_FAILED", error.message ?: "Could not verify local AI asset", null)
        }
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

    private fun copyAndHashAsset(assetPath: String, destination: File): String {
        val digest = MessageDigest.getInstance("SHA-256")
        context.assets.open(assetPath).use { input ->
            FileOutputStream(destination).use { output ->
                val buffer = ByteArray(64 * 1024)
                while (true) {
                    val count = input.read(buffer)
                    if (count <= 0) break
                    digest.update(buffer, 0, count)
                    output.write(buffer, 0, count)
                }
                output.fd.sync()
            }
        }
        return digest.digest().joinToString("") { byte -> "%02x".format(byte) }
    }

    companion object {
        const val CHANNEL_NAME = "com.mizan/local_ai"
        private val SAFE_ARTIFACT_NAME = Regex("^[a-zA-Z0-9._-]+\\.gguf$")
        private val SHA256 = Regex("^[0-9a-f]{64}$")
    }
}
