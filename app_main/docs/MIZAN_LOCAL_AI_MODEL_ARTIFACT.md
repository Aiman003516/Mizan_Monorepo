# Mizan Local AI Model Artifact

## Selected artifact

Mizan’s first local-model pilot is pinned to the following artifact:

| Field | Value |
|---|---|
| Base model | `Qwen/Qwen3-0.6B` |
| Quantized artifact | `Qwen_Qwen3-0.6B-Q4_K_M.gguf` |
| Artifact repository | `bartowski/Qwen_Qwen3-0.6B-GGUF` |
| Immutable revision | `60b85c0e3d8fe0f6474f406922a26d12aca4550d` |
| Runtime target | llama.cpp-compatible Android and Windows runners; Android device test pending |
| Quantization | Q4_K_M |
| Downloaded size | 484,220,320 bytes |
| SHA-256 | `9acfc1e001311f34b4252001b626f2e466d592a42065f66571bff3790d4e1b14` |
| Local languages | Arabic and English |
| Task | Proposal extraction only |

The original Qwen3 model is published under Apache 2.0. The GGUF file is a community conversion and must be retained with its source and checksum metadata. The app must not silently replace it with a floating `main` revision.

## Preparation

From the repository root, run:

```bash
./scripts/prepare_qwen3_local_model.sh
```

On Windows PowerShell, run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\prepare_qwen3_local_model.ps1
```

The script downloads the artifact into the ignored `.local_ai_model_cache/` directory, verifies the exact SHA-256 checksum, and copies it to:

```text
app_main/apps/assets/local_ai/Qwen_Qwen3-0.6B-Q4_K_M.gguf
```

The model binary is intentionally not committed to GitHub. The Flutter application now declares `assets/local_ai/`, so a prepared local build can package the file. On Windows, prepare the pinned llama.cpp source separately with:

```powershell
.\scripts\prepare_llama_cpp_windows.ps1
```

That script downloads the 37,514,504-byte archive for revision `47c786924ad1ab7e91da2cdc72fcdb563780c2bd`, verifies SHA-256 `9416d95607230f8a4e4379e1b86604e127c7c0eafa5e5c8c76605e43805b8c88`, and extracts it into the ignored `.local_llama_cpp_cache/` directory. Windows CMake consumes that prepared local source and does not clone llama.cpp during Flutter configuration. Android now builds the pinned CPU-only llama.cpp JNI runtime and packages the GGUF; physical-device inference and performance verification remain pending.

## Safety boundary

The pinned artifact is enabled in the default provider on Android and Windows, where the runners include the prepared pinned llama.cpp source and the Dart provider selects `NativeGgufLocalAiEngine`. A build fails clearly at CMake configuration if the preparation script has not been run, rather than silently attempting a network clone. Web and other unsupported platforms continue using the deterministic local engine and rule-based fallback. If the native model tier is unavailable or fails, the orchestrator preserves the deterministic result and the UI displays a localized warning that no record was changed. The native adapter returns only proposal JSON, and the Dart validator rejects malformed, unknown, unsafe, or semantically invalid proposals.

The local model must not receive Supabase credentials, direct database handles, tenant records, journal data, authentication tokens, or arbitrary tool definitions. Local inference cannot post journals, edit records, delete records, send messages, or modify application files. Authenticated accounting actions remain server-authoritative and confirmation-gated.

## Release gates

Before enabling this artifact in a release build, verify the native runtime on a Samsung Note9 and representative Android API levels. Record cold and warm load time, generation latency, peak memory, storage usage, CPU temperature, battery impact, crash recovery, Arabic and English proposal validity, malformed-output rejection, unsafe-request refusal, and network-capture evidence showing that local-only prompts do not leave the device.

## Sources

1. [Qwen/Qwen3-0.6B model card](https://huggingface.co/Qwen/Qwen3-0.6B)
2. [bartowski Qwen3-0.6B GGUF repository](https://huggingface.co/bartowski/Qwen_Qwen3-0.6B-GGUF)
3. [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)
