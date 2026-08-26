# Mizan Scale and Infrastructure Gates

## Decision summary

Mizan remains a **modular monolith with Supabase as the server authority**. The current workload does not justify introducing Kafka, Debezium, ClickHouse, graph neural networks, WebAssembly plug-ins, or a microservice split. These technologies can be useful at larger scale, but introducing them before the corresponding bottleneck is measured would increase operational risk without improving accounting correctness for the current product.

> Scale infrastructure is an approval-gated response to measured constraints, not a feature checkbox.

## Current baseline

The current architecture uses Flutter feature packages, Supabase/Postgres row-level security, server-side RPCs for financial mutations, Drift for local cache and outbox behavior, typed contracts, additive migrations, and a transactional ERP event outbox. It includes tenant-scoped indexes, idempotency keys, retryable event claims, conflict records, and read-oriented reporting RPCs. This is sufficient for the present modular-monolith boundary while preserving a single authoritative ledger.

## Measured gates

| Capability | Prerequisite measurement | Trigger threshold | Required approval and rollout |
|---|---|---:|---|
| Read replicas or report read models | p95 report latency, query plans, row counts, concurrent report users | p95 over 2 seconds for three consecutive business days, or repeated sequential scans over 1 million tenant-scoped rows | Owner and engineering approval; add indexes/read model first; retain Postgres ledger authority |
| Partitioning or archival | journal and event row growth, retention requirements, vacuum time | More than 50 million journal/event rows or vacuum/retention maintenance breaches the agreed window | Approved data-retention policy and rollback plan; never partition by removing audit history |
| Analytical warehouse/ClickHouse | report workload share, Postgres CPU/IO, freshness target | Analytical queries consume over 30% of database resources for seven days and cannot be solved by indexes/read models | Architecture approval; replicate immutable facts only; no write path to the ledger |
| Kafka or another durable broker | outbox backlog, delivery latency, retry rate, event fan-out count | Sustained outbox backlog above 10,000 events, p95 delivery latency above 60 seconds, or more than 5 independent consumers | Security and operations approval; preserve the Postgres outbox as the recovery source until verified |
| Debezium/CDC | proven need for multi-consumer change capture and measured outbox limits | Same event-volume gate as the broker, plus a documented consumer requiring row-level CDC | Data-governance approval; exclude sensitive columns by policy; never treat CDC as the accounting authority |
| Service extraction | deployment contention, independent scaling need, bounded context ownership | A bounded context requires independent release/scaling for four consecutive release cycles and has a stable contract | Architecture review and migration plan; extract read paths before financial write paths |
| Graph/GNN features | labelled relationship dataset, precision/recall baseline, explainability review | At least 100,000 labelled relationships and a deterministic baseline that is materially insufficient | Privacy, model-risk, and owner approval; advisory-only output with human review |
| WebAssembly extensions | measured CPU-bound tenant-safe extension workload | A reviewed extension cannot meet latency/resource targets in the bounded host runtime | Security review, sandbox proof, capability allowlist, and kill switch; no file/source modification or financial authority |
| Local model expansion | on-device accuracy, memory, latency, battery, and privacy tests | The assistant has a stable bounded intent set and the model beats deterministic rules without sensitive-data leakage | Model-risk approval; proposal-only output, signed version, rollback asset, and no automatic posting |

## Non-negotiable controls

Every option must preserve tenant isolation, audit logging, idempotent mutation semantics, explicit permission checks, immutable posted journals, period locks, and the distinction between a proposal and an executed financial mutation. No scale component may write around the server accounting RPCs. AI and extensions cannot post journal entries, delete records, change source code, bypass approval, or weaken RLS.

## Review cadence

The owner should review the measurements monthly during pilot operation and before any infrastructure change. A gate is considered open only when the threshold, evidence window, data classification, rollback path, and named approver are recorded. Until then, the simpler Postgres/Supabase and outbox architecture remains the selected implementation.
