package com.example.mizan

/**
 * Minimal JNI surface for the local Qwen3 GGUF runtime.
 *
 * The native library receives only a verified local model path and user text.
 * It has no network, database, credential, or mutation interfaces.
 */
object LocalAiNative {
    private var loaded = false

    fun ensureLoaded(): Boolean {
        if (!loaded) {
            System.loadLibrary("mizan_local_ai")
            loaded = true
        }
        return loaded
    }

    @JvmStatic
    external fun loadModel(path: String): Boolean

    @JvmStatic
    external fun infer(text: String, locale: String): String?

    @JvmStatic
    external fun unloadModel()
}
