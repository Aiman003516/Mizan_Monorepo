# Mizan Local AI and TinyML Deployment Plan

## Purpose

This document defines the final phase for deploying privacy-preserving AI on the Mizan end device. It is intentionally sequenced after the cloud action expansion, accounting validation, audit testing, Supabase rollout, and physical-device regression testing. No local model may bypass Mizan’s deterministic accounting validators, tenant isolation, permissions, confirmation tokens, or audit logging.

## Non-negotiable boundary

> A local model may interpret language and prepare a typed proposal. It may never be the authority that calculates, authorizes, posts, edits, deletes, or reverses an accounting record.

The local model runs without access to raw network APIs, arbitrary SQL, filesystem commands, production credentials, or unrestricted database mutation methods. The Flutter application remains the policy enforcement layer for local drafts, while Supabase remains the source of truth for authenticated cloud data and all cloud mutations.

## Recommended model split

| Component | Responsibility | Data access | Output |
|---|---|---|---|
| Small intent classifier | Identify request class and whether the user is asking for analysis or a mutation | Current user text only | Intent and confidence |
| Structured extractor | Extract dates, amounts, currencies, record names, and requested fields | Current user text and explicitly selected local record | Strict JSON candidate |
| Optional small local language model | Explain simple accounting concepts and request missing information offline | Redacted local context | Natural-language response plus optional candidate JSON |
| Deterministic validator | Validate schema, date, amount, currency, tax, account ownership, and accounting invariants | Current Drift row or server response | Valid or rejected typed proposal |
| Server action RPC | Re-read authoritative data, recheck permission and tenant, and execute after confirmation | Authenticated Supabase tenant | Atomic committed result and audit events |

TinyML is appropriate for the classifier, redaction filter, and narrow extraction tasks. A small quantized language model can improve Arabic/English conversational drafting, but it should remain optional and non-authoritative.

## Privacy modes

| Mode | Model location | Data leaving device | Allowed operation |
|---|---|---:|---|
| Guest/offline | Local only | None | Local help and local draft preparation; no cloud execution |
| Authenticated local-first | Local first | None by default | Read local cache and prepare proposals; cloud sync follows existing rules |
| Authenticated cloud AI | Supabase Edge Function and opted-in provider | Minimized, disclosed request data | Read tenant-scoped data and prepare proposals; execution remains confirmation-gated |
| Developer mode | Separate local developer assistant | None by default | Produce a patch/diff only; never access production accounting RPCs |

The user must be able to disable cloud AI. A cloud fallback must never happen silently when a local-only privacy mode is selected. Before any opted-in cloud request, Mizan should minimize identifiers and avoid sending full ledgers, attachments, secrets, authentication tokens, or unnecessary customer notes.

## Training and model-production pipeline

Training is the final implementation phase, not a prerequisite for the accounting action rollout. Do not train from scratch initially. Begin with a schema-first dataset containing synthetic and anonymized Arabic/English requests mapped to the supported action contracts. Production records must not enter the dataset unless they have been explicitly de-identified, approved for training, and stripped of customer, vendor, employee, account, and tenant identifiers.

Every training example must pass the same deterministic validators used by the application. Examples with invalid dates, unknown IDs, unbalanced journal lines, unsupported fields, unsafe deletion requests, cross-tenant references, or missing confirmation requirements must be rejected automatically. A stronger teacher model may generate candidate examples, but a programmatic validator must decide whether they are usable.

The first model should be a small classifier or extractor. Only after it reaches the required structured-output accuracy should Mizan evaluate adapter tuning or distillation for a small language model. Export INT8 first; evaluate INT4 only if it does not materially reduce Arabic accuracy or structured-output validity. Sign the model artifact and ship a manifest containing model version, checksum, tokenizer version, supported locales, training-data version, and minimum application version.

## Samsung Note9 evaluation gates

The target device must be tested directly rather than estimated from desktop hardware. The benchmark must measure cold-start time, warm inference latency, peak memory, battery consumption, thermal behavior, crash rate, model size, offline persistence, Arabic and English accuracy, malformed-JSON rate, and refusal behavior for unsafe requests.

| Gate | Minimum requirement before the next gate |
|---|---|
| Functional | Model loads, unloads, and recovers after interruption without corrupting Drift data |
| Privacy | Network capture shows no model-request data leaves the device in local-only mode |
| Schema | Structured output is valid and unknown fields are rejected |
| Accounting | Amount, date, currency, tax, and journal-balance test suite passes without model arithmetic authority |
| Security | Model cannot access arbitrary SQL, HTTP, filesystem, credentials, or unrestricted RPCs |
| UX | Arabic RTL, English LTR, keyboard input, narrow layout, loading, timeout, and offline states work correctly |
| Performance | Measured latency, memory, battery, and thermal values meet an agreed device-specific budget |
| Rollback | The model can be disabled remotely or locally without blocking ordinary accounting workflows |

The device test must include guest mode, an authenticated tenant owner, a restricted staff member, a second tenant, malformed requests, prompt-injection text inside CRM notes, and a request for an unsupported destructive action.

## Rollout order

1. Keep the current cloud action implementation behind the existing authenticated confirmation workflow.
2. Complete Supabase SQL and Edge Function deployment and run the customer, invoice, journal, balance, archive, void, tenant-isolation, and idempotency test matrix.
3. Add local intent classification in shadow mode; record only aggregate evaluation metrics, not raw financial prompts.
4. Add local structured extraction for non-mutating drafts and compare its output with the existing cloud proposal path.
5. Enable local-only proposal previews for a small internal cohort; keep execution disabled for local proposals until server revalidation is proven.
6. Add an explicit user setting for local-only AI, cloud-opt-in AI, and AI disabled.
7. Benchmark the quantized model on the Samsung Note9 and run the privacy and rollback gates.
8. Enable confirmed execution only through the same server-side action endpoint and confirmation token, regardless of whether the proposal originated locally or in the cloud.
9. Retain OpenRouter as an opt-in fallback for complex requests only; do not use it as a silent local-model failure path.
10. Reassess TinyML and full local language-model deployment after real device measurements, not before.

## Acceptance criteria

The local AI phase is complete only when the local-only mode has zero network egress for AI data, the model cannot bypass typed validators, all supported action proposals remain confirmation-gated, failed or stale proposals cannot mutate records, tenant isolation tests pass, Arabic/English tests pass, the model artifact is signed and versioned, the Samsung Note9 benchmark passes, and users can disable or roll back the local model without losing accounting functionality.

## References

[1]: https://developers.google.com/edge/litert "Google LiteRT: On-device machine learning runtime"
[2]: https://developer.android.com/ai/custom "Android Developers: Custom on-device AI on Android"
[3]: https://drift.simonbinder.eu/web/ "Drift web database and WASM deployment documentation"
