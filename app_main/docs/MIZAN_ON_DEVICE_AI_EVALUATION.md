# Mizan On-Device AI Assistant: Plan Evaluation and Corrected Execution Plan

**Date:** 27 August 2026
**Scope:** Evaluation of the attached on-device AI assistant integration plan against the current Mizan repository.

## Executive decision

The attached plan has a strong product direction: a local assistant should help users understand workflows, propose navigation or form changes, and never bypass human confirmation or server authorization. Mizan already has the most important safety foundation: a versioned local proposal contract, deterministic rule-based extraction, a proposal validator, a fail-closed native bridge, and a separate authenticated cloud action-draft path.[1][2]

The plan is **approved as a staged architecture**, not as a direct “add a model and enable every workflow” change. The first implementation will strengthen the local assistant around deterministic navigation, explanations, knowledge retrieval, proposal orchestration, and model-readiness contracts. A real native LLM runtime remains disabled until its binary, license provenance, packaging, memory, latency, Arabic accuracy, crash behavior, and no-egress behavior are measured on representative devices.

## Corrections to the attached plan

| Plan assumption | Evaluation | Corrected decision |
|---|---|---|
| Qwen2.5-0.5B is production-grade Arabic with a guaranteed accuracy range | The official model card confirms multilingual support including Arabic and 0.49B parameters, but it does not establish Mizan-specific accuracy or the claimed 85–98% range.[3] | Treat Arabic quality and task accuracy as hypotheses. Require a fixed Mizan evaluation set and acceptance thresholds before release. |
| Q4_K_M is approximately 390 MB | A public GGUF distribution lists Q4_K_M at approximately 398 MB.[4] | Use manifest-declared size and checksum, not a hard-coded estimate. Reserve storage for download, temporary file, and rollback copy if downloads are ever approved. |
| `llama_cpp_dart ^0.4.0` is the correct dependency | The current upstream repository describes a 0.9.x rewrite, mobile-only focus, changing public API, and prebuilt native artifacts.[5] | Do not add an unpinned or stale runtime dependency in this slice. Keep the current bridge abstraction and add a reviewed runtime adapter only after version pinning and device validation. |
| GBNF guarantees valid and semantically safe JSON | GBNF can constrain syntactic output in llama.cpp, but grammar support has performance and schema limitations, and valid JSON is not valid accounting intent.[6] | Use grammar as a secondary defense. Always decode, validate, authorize, and confirm proposals in the application/server boundary. |
| The app can navigate through GoRouter routes for all screens | Mizan’s shell primarily changes a `MainPage` state and renders a page switch; it is not a 103-route GoRouter table. | Emit a stable, feature-neutral navigation target. Let the application shell map that target to `MainPage` through an explicit callback. |
| First-run model download is the default distribution strategy | The repository’s local-AI design note currently requires reviewed packaged assets and explicitly avoids runtime download assumptions.[1] | Keep local runtime fail-closed and package-neutral now. A signed, resumable download service is a separate release decision requiring hosting, authenticity, storage, cancellation, privacy, and rollback review. |
| All local complex requests should go directly to an LLM | Small on-device models can hallucinate entities, dates, amounts, and unsupported actions. | Route deterministic navigation and extraction to rules first; use a reviewed model only for bounded proposal generation; never let local inference execute mutations. |
| “5-second undo” protects financial actions | An undo window is not a substitute for server authorization, period checks, maker-checker, immutable posting, or reversal workflows. | Local actions remain proposals. Any authenticated mutation continues through the existing confirmation-token/server-authoritative path. |
| Voice input is part of the initial scope | Speech recognition adds a separate platform, privacy, Arabic-dialect, permission, and offline-model surface. | Defer voice until text-only local behavior is measured and approved. |

## Safety invariants for implementation

The local assistant must satisfy these invariants:

1. It can classify, explain, extract bounded fields, and propose navigation. It cannot call Supabase, read credentials, execute SQL, mutate Drift business records, invoke arbitrary methods, edit source files, delete records, or post accounting facts.
2. Every mutation proposal requires explicit confirmation and passes the existing validator. A local proposal never becomes an executed business action merely because a model produced JSON.
3. Guest/offline local assistance must not silently fall back to the cloud AI path. Cloud AI remains a separate authenticated opt-in path.
4. Model manifests must use stable versions, explicit locale/task declarations, safe artifact names, checksums, minimum app versions, and a kill switch. A checksum proves integrity, not publisher authenticity.
5. User prompts, financial records, raw model output, and credentials must not be written to logs or telemetry by the local path.
6. If the runtime, model, manifest, memory budget, or locale is unsupported, the engine returns a localized unavailable state and ordinary accounting/CRM workflows remain usable.
7. Navigation is advisory. The shell validates the target against an allowlist and performs the actual state transition.

## Corrected delivery phases

| Phase | Deliverable | Status after this implementation slice |
|---|---|---|
| 1 | Navigation and explanation proposal types; allowlisted shell adapter; deterministic Arabic/English intent handling | Implement |
| 2 | Local knowledge base with bounded retrieval and no tenant-data leakage | Implement |
| 3 | Orchestrator routing rules with rule-first behavior and explicit engine provenance | Implement |
| 4 | Model manifest/catalog and packaged-runtime readiness contract; no unreviewed runtime or network download | Implement |
| 5 | Local assistant UI for guest/offline guidance, navigation cards, and explanation cards; cloud draft flow unchanged | Implement where the existing screen allows safely |
| 6 | Real GGUF/llama.cpp runtime, signed distribution, device benchmarks, and Android/iOS packaging | Deferred pending runtime review and device evidence |
| 7 | Fine-tuning, synthetic-data expansion, voice, and model-specific optimization | Deferred until the base local path has measured evaluation results |

## Acceptance gates for a future real model

A native runtime may be enabled only after a reviewed model artifact and pinned runtime pass all gates below on the Samsung Note9 target and representative Android API levels:

| Gate | Required evidence |
|---|---|
| Structured output | 100% decodeable proposal samples in the fixed test corpus; invalid, extra-key, unsafe, and out-of-range outputs rejected |
| Accounting safety | No local output can bypass confirmation or server/RPC authorization; no posted fact is mutated by the local engine |
| Arabic/English quality | Per-intent precision/recall and field-extraction accuracy reported separately; no unsupported claims about production accuracy |
| Memory and stability | Peak resident memory, cold/warm latency, OOM behavior, cancellation, unload, and recovery measured on target devices |
| Privacy | Network capture demonstrates no local prompt or financial-data egress in local-only mode; logs contain no sensitive payloads |
| Distribution | Artifact provenance, license review, signature verification, checksum, rollback, storage requirements, and update policy documented |
| UX | Narrow Android viewport, Arabic RTL, keyboard, loading/cancel/error states, and ordinary accounting workflow remain usable |

## References

[1]: local-ai-tflite-bridge.md "Mizan Android Local AI Bridge and Model Packaging"
[2]: ../packages/features/feature_ai/lib/src/local_ai/local_ai_engine.dart "Mizan LocalAiEngine contract"
[3]: https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct "Qwen2.5-0.5B-Instruct model card"
[4]: https://huggingface.co/lmstudio-community/Qwen2.5-0.5B-Instruct-GGUF "Qwen2.5-0.5B-Instruct GGUF distribution"
[5]: https://github.com/netdur/llama_cpp_dart "llama_cpp_dart repository and current mobile API"
[6]: https://github.com/ggml-org/llama.cpp/blob/master/grammars/README.md "llama.cpp GBNF guide and limitations"
