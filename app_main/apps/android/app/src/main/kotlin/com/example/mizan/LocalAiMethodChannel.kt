package com.example.mizan

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import org.json.JSONObject

/**
 * Narrow native boundary for proposal-only local inference.
 *
 * Model loading and inference run on a worker so a 484 MB GGUF load does not
 * block Flutter's platform thread. The native library receives only a verified
 * local path and user text; it has no network, database, credential, or
 * mutation interfaces.
 */
class LocalAiMethodChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodCallHandler {
    private val channel = MethodChannel(messenger, CHANNEL_NAME)
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile private var modelReady = false

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "load_model" -> loadModel(call, result)
            "infer" -> infer(call, result)
            "unload_model" -> unloadModel(result)
            else -> result.notImplemented()
        }
    }

    fun close() {
        modelReady = false
        executor.execute {
            runCatching { LocalAiNative.unloadModel() }
            executor.shutdown()
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

        executor.execute {
            try {
                val assetPath = "flutter_assets/assets/local_ai/$artifactName"
                val destination = File(context.noBackupFilesDir, "mizan_local_ai/$artifactName")
                destination.parentFile?.mkdirs()
                val partialDestination = File("${destination.absolutePath}.partial")
                val actualSha = copyAndHashAsset(assetPath, partialDestination)
                if (actualSha != expectedSha) {
                    partialDestination.delete()
                    postResult(result) {
                        result.error("CHECKSUM_MISMATCH", "Local AI asset checksum mismatch", null)
                    }
                    return@execute
                }
                if (destination.exists() && !destination.delete()) {
                    partialDestination.delete()
                    postResult(result) {
                        result.error("ASSET_INSTALL_FAILED", "Could not replace local AI asset", null)
                    }
                    return@execute
                }
                if (!partialDestination.renameTo(destination)) {
                    partialDestination.delete()
                    postResult(result) {
                        result.error("ASSET_INSTALL_FAILED", "Could not install local AI asset", null)
                    }
                    return@execute
                }

                val nativeLoaded = LocalAiNative.ensureLoaded()
                if (!nativeLoaded || !LocalAiNative.loadModel(destination.absolutePath)) {
                    modelReady = false
                    postResult(result) {
                        result.success(
                            mapOf(
                                "status" to "unavailable",
                                "message" to "Pinned local model asset verified, but Android llama.cpp could not load it.",
                                "artifact_path" to destination.absolutePath,
                            ),
                        )
                    }
                    return@execute
                }

                modelReady = true
                postResult(result) {
                    result.success(
                        mapOf(
                            "status" to "ready",
                            "artifact_path" to destination.absolutePath,
                        ),
                    )
                }
            } catch (error: UnsatisfiedLinkError) {
                modelReady = false
                postResult(result) {
                    result.success(
                        mapOf(
                            "status" to "unavailable",
                            "message" to "Android local AI native library is unavailable.",
                        ),
                    )
                }
            } catch (error: Exception) {
                modelReady = false
                postResult(result) {
                    result.error(
                        "ASSET_VERIFICATION_FAILED",
                        error.message ?: "Could not prepare local AI asset",
                        null,
                    )
                }
            }
        }
    }

    private fun infer(call: MethodCall, result: Result) {
        val text = call.argument<String>("text")
        val locale = call.argument<String>("locale")
        if (text.isNullOrBlank() || locale.isNullOrBlank()) {
            result.error("INVALID_ARGUMENT", "text and locale are required", null)
            return
        }
        if (text.length > MAX_PROMPT_CHARS || locale !in SUPPORTED_LOCALES) {
            result.error("INVALID_ARGUMENT", "text or locale is not supported", null)
            return
        }

        executor.execute {
            if (!modelReady) {
                postResult(result) {
                    result.success(
                        mapOf(
                            "status" to "unavailable",
                            "message" to "Android local AI model is not loaded.",
                        ),
                    )
                }
                return@execute
            }
            try {
                val proposal = LocalAiNative.infer(text, locale)
                if (proposal.isNullOrBlank()) {
                    postResult(result) {
                        result.success(
                            mapOf(
                                "status" to "failed",
                                "message" to "Local Android llama.cpp inference returned no proposal.",
                            ),
                        )
                    }
                } else {
                    // Dart performs the authoritative schema and semantic validation.
                    postResult(result) {
                        result.success(
                            mapOf(
                                "status" to "ready",
                                "proposal_json" to proposal,
                            ),
                        )
                    }
                }
            } catch (error: UnsatisfiedLinkError) {
                modelReady = false
                postResult(result) {
                    result.success(
                        mapOf(
                            "status" to "failed",
                            "message" to "Android local AI native library failed during inference.",
                        ),
                    )
                }
            } catch (error: Exception) {
                postResult(result) {
                    result.success(
                        mapOf(
                            "status" to "failed",
                            "message" to (error.message ?: "Local Android llama.cpp inference failed."),
                        ),
                    )
                }
            }
        }
    }

    private fun unloadModel(result: Result) {
        executor.execute {
            modelReady = false
            runCatching { LocalAiNative.unloadModel() }
            postResult(result) { result.success(null) }
        }
    }

    private fun postResult(result: Result, callback: () -> Unit) {
        mainHandler.post(callback)
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
        private const val MAX_PROMPT_CHARS = 7000
        private val SUPPORTED_LOCALES = setOf("ar", "en")
        private val SAFE_ARTIFACT_NAME = Regex("^[a-zA-Z0-9._-]+\\.gguf$")
        private val SHA256 = Regex("^[0-9a-f]{64}$")
    }
}
