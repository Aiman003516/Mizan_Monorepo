# Mizan Android Local AI Bridge and Model Packaging

## Scope

This document defines the Android integration boundary for a future small on-device model. Step 2 ships the deterministic Dart engine and a fail-closed method-channel scaffold. It does **not** ship a model binary, add a native inference dependency, or enable model inference in production.

> The native runtime may return a typed local proposal only. It must never receive or expose SQL, HTTP, credentials, filesystem commands, arbitrary method names, or direct accounting and CRM mutation authority.

## Bridge contract

The Flutter package owns `LocalAiNativeInferenceBridge` and `NativeTfliteLocalAiEngine`. Android exposes one channel:

```text
com.mizan/local_ai
```

The allowed methods are deliberately finite:

| Method | Input | Output | Safety rule |
|---|---|---|---|
| `load_model` | `manifest_json` | `ready`, `unavailable`, or `failed` | Android validates the manifest and artifact before loading; no cloud fallback |
| `infer` | `text`, `locale` | proposal JSON or failure status | The runtime receives only current user text and locale; output is parsed as the versioned proposal contract and deterministically validated again in Dart |
| `unload_model` | none | null | Releases native resources; it cannot mutate application data |

The Android scaffold currently returns `unavailable` for model operations. This is intentional: adding a channel is not equivalent to enabling a model. A future implementation should keep the actual interpreter behind a private Kotlin class such as `VerifiedLocalAiRuntime`, with no public API other than the three methods above.

The existing cloud AI route remains separate. Local-only mode must not silently call the cloud gateway if the Android model is missing, invalid, incompatible, or out of memory.

## Proposed native implementation sequence

The first native runtime candidate is LiteRT/TensorFlow Lite for Android, subject to the project’s final dependency review and device benchmark. The dependency version must be pinned rather than resolved dynamically. The runtime should be initialized lazily on the first explicitly allowed local inference request and released on lifecycle/background or memory-pressure events.

The native implementation should perform the following checks before inference:

1. Read the model manifest from the application package, not from a URL.
2. Confirm the manifest schema and supported task.
3. Confirm the artifact name cannot escape the `local_ai/` asset directory.
4. Load the packaged bytes and verify SHA-256 against the manifest.
5. Confirm the model version is compatible with the minimum app version and locale.
6. Allocate only bounded input and output tensors.
7. Run inference with a fixed operation allowlist and a bounded timeout.
8. Return UTF-8 proposal JSON only; malformed or unknown output is a failure.
9. Never persist raw prompts or financial records to logs.

The native implementation should not accept arbitrary tensor names, file paths, delegates, operation codes, or runtime options from Dart. Those values belong to the reviewed model adapter and manifest, not to user input.

## Asset layout

No model asset is currently packaged. When a reviewed model is approved, the recommended Android-only layout is:

```text
apps/android/app/src/main/assets/local_ai/
  proposal_extractor_v1/
    model.tflite
    manifest.json
    manifest.sig
```

The Flutter package should not declare the model as a web asset. The model is intentionally Android-specific until equivalent privacy and runtime behavior is implemented on other platforms. A future iOS or desktop implementation must use the same proposal schema and validation boundary rather than sharing an Android binary.

The manifest template is stored at `docs/local-ai-model-manifest.example.json`. It records:

| Field | Requirement |
|---|---|
| `schema_version` | `mizan.local-ai.model/v1` |
| `model_id` and `model_version` | Stable identifiers used in telemetry-free diagnostics and rollback selection |
| `artifact_name` | A plain `.tflite` filename; no path traversal or remote URL |
| `sha256` | Lowercase or uppercase 64-character SHA-256 digest |
| `tokenizer_version` | Must match the native preprocessing adapter |
| `supported_locales` | Explicit subset of `ar` and `en` |
| `minimum_app_version` | Prevents incompatible model/app combinations |
| `task` | Currently only `proposal_extraction` |
| `quantization` | Explicitly recorded as float32, float16, dynamic-range int8, or int8 |

`manifest.sig` is reserved for a release-signing signature. The production runtime should verify the signature against a public key embedded in the app before trusting a manifest. A checksum protects artifact integrity; it does not by itself establish release authenticity.

## Build and release policy

The model is a versioned release input, not a runtime download. The CI pipeline should validate the manifest, calculate the artifact digest, compare it with `sha256`, inspect the expected asset path, and fail if the model is missing or has unexpected files. Model binaries should be reviewed separately from source changes and must be generated only from synthetic or approved de-identified Arabic/English data.

The first package should use the smallest model that satisfies intent classification and narrow extraction. Quantization is a measured decision: evaluate float16 or dynamic-range int8 first, then full int8 if representative Arabic accuracy and structured-output validity remain acceptable. INT4 is not a default and must not be introduced merely to reduce APK size.

## Rollback and kill switch

The engine must be disableable at three levels:

| Level | Mechanism | Result |
|---|---|---|
| Build-time | Do not include the model asset or native runtime | `MissingPluginException`/`unavailable`; ordinary accounting remains usable |
| Local setting | User selects AI disabled or local AI off | The provider resolves to `DisabledLocalAiEngine` |
| Model compatibility | Manifest, checksum, signature, or app-version check fails | Native engine stays unavailable; no cloud fallback in local-only mode |

A future remote configuration may disable a model identifier, but it must not be required for local operation and must not cause user data to leave the device. Disabling or rolling back the model must not delete Drift data, block invoices, or prevent normal CRM/accounting workflows.

## Verification gates before enabling a real model

The native runtime remains disabled until all of the following are measured on the Samsung Note9 target and representative Android API levels: cold and warm latency, peak memory, model size, crash/recovery behavior, battery and thermal impact, Arabic and English structured-output validity, malformed-output rejection, unsafe-request refusal, and network-capture evidence showing no AI data egress in local-only mode.

The final proposal still passes through `LocalAiProposal.decode` and `LocalAiProposalValidator.validate`. Authenticated mutations, if ever enabled, still use the existing server-authoritative confirmation-token flow. Guest/local mode never executes cloud mutations.

## Current application behavior

The Flutter application now composes `LocalAiOrchestrator` by default. It prefers the deterministic Arabic/English rule engine for allowlisted navigation, bounded workflow explanations, missing-information responses, and proposal-only mutation extraction. The assistant UI can use this path in guest/offline mode without sending the prompt to the cloud. Navigation is emitted as a feature-neutral target and mapped by the application shell to the existing `MainPage` state model.

The reviewed model provider remains `DisabledLocalAiEngine` until a native runtime, artifact provenance, manifest signature, memory profile, device benchmark, and no-egress test have been approved. The cloud AI repository remains a separate authenticated path for server-authoritative action drafts and confirmation tokens. Local proposals never execute mutations.

## References

[1]: https://developers.google.com/edge/litert "Google LiteRT: on-device machine learning runtime"
[2]: https://developer.android.com/ai/custom "Android Developers: custom on-device AI on Android"
[3]: https://developer.android.com/topic/performance/memory "Android Developers: manage your app's memory"
