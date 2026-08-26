# Mizan Blueprint Missing-Feature Register

**Purpose:** Track every capability described in the uploaded AI-first ERP and Composable ERP blueprints that is not yet fully present in Mizan, and sequence implementation by safety, dependency, and business value.

**Status vocabulary:** `Existing foundation` means a usable partial foundation is present; `Implement next` means the capability is appropriate for the next product waves; `Deferred decision` means it requires measured scale, a confirmed business requirement, or infrastructure approval; `Not applicable now` means the blueprint mechanism does not fit the current Flutter product architecture.

## Feature register

| ID | Blueprint capability | Current Mizan state | Planned implementation | Dependencies | Priority |
|---|---|---|---|---|---|
| F-001 | Bounded contexts and anti-corruption layers | Existing package separation, but cross-context boundaries are uneven. | Define public contracts for Ledger, AR/AP, CRM, Inventory/POS, Tax, Workforce, Sync, and AI; add translators for document-to-ledger commands. | Shared contract package, repository inventory. | P0 |
| F-002 | Schema canonicalization and preflight | Partial migrations and legacy/new schema overlap remain. | Add read-only schema/data-quality checks for orphan references, duplicate concepts, invalid currencies, unbalanced legacy entries, and missing RLS. | Supabase metadata access, migration inventory. | P0 |
| F-003 | Central permission and branch matrix | Owner control center and branch foundation exist; full effective-permission behavior is incomplete. | Add permission evaluator, branch-scoped policies, effective-permission preview, negative tests, and audit events. | F-001, platform hardening migration. | P0 |
| F-004 | Immutable financial command boundary | Ledger foundation and report RPCs exist. | Complete draft, validate, post, reverse, period-close, idempotency, and reconciliation commands with no direct financial table writes. | F-001, F-003, ledger migrations. | P0 |
| F-005 | Transactional outbox and event contracts | Local sync queue exists; server outbox delivery is incomplete. | Add event envelope, mutation ID, outbox status, retry/backoff, idempotent consumers, tombstones, and operator diagnostics. | F-001, F-004. | P0 |
| F-006 | Reproducible server reports | Trial balance, P&L, and balance sheet contracts exist; other reports remain mixed/local. | Add period/currency/source parameters, AR/AP aging, cash flow, tax liability, audit, and reconciliation reports. | F-004, F-007, F-008. | P0 |
| F-007 | Dimensional accounting/worktags | Not implemented across journal lines and documents. | Add controlled dimensions such as branch, cost center, project, campaign, region, and optional JSONB worktags with validation and indexes. | F-004, F-001. | P1 |
| F-008 | Multi-currency provenance and FX | Currency support exists, but rate provenance and full FX treatment are incomplete. | Add exchange-rate source/effective date, base/transaction values, rounding policy, realized/unrealized FX adjustments, and report controls. | F-004, money value objects. | P1 |
| F-009 | Multi-book/parallel ledgers | Not implemented. | Add leading/local/extension book model only after multi-entity or GAAP requirements are confirmed. | F-004, F-007, policy decision. | P2 |
| F-010 | Deterministic tax engine | Tax-code foundation exists; jurisdictional decision engine is incomplete. | Add Yemen-focused rules, inclusive/exclusive tax, exemptions, tax snapshots, effective dates, jurisdiction metadata, and explanation DTOs. | F-004, F-008. | P1 |
| F-011 | E-invoicing/compliance metadata | Not implemented. | Add invoice hash/chaining/QR-ready metadata and provider-state contracts only for confirmed jurisdictional requirements; no fabricated government submission. | F-010, provider decision. | P2 |
| F-012 | Revenue recognition | Not implemented. | Add contract, performance-obligation, SSP, schedule, modification, catch-up, and deferred-commission models only for a confirmed use case. | F-004, F-007, accounting policy. | P2 |
| F-013 | AR/AP settlement and aging | Partial existing workflows; not fully reconciled to new ledger. | Add payment allocations, partial settlement, overdue buckets, credit controls, document-to-ledger links, and aging reports. | F-004, F-006. | P1 |
| F-014 | AP document intake and matching | Manual/import foundations exist; OCR and 3-way matching are incomplete. | Add draft-only extraction, confidence/field review, PO/receipt/invoice matching, duplicate detection, and approval queue. | F-005, F-010, provider or local OCR decision. | P2 |
| F-015 | Inventory/warehouse/costing | Existing product/POS work exists; complete accounting bridge is incomplete. | Add warehouse/stock contracts, costing policy, POS session close, variance workflow, and ledger bridge events. | F-004, F-005, F-013. | P1 |
| F-016 | CRM 360 and operational composition | CRM pipeline foundation exists; unified 360 view is incomplete. | Add customer profile, opportunities, activities, invoices, balances, pipeline conversion, and safe read-model/API composition. | F-001, F-006, F-013. | P1 |
| F-017 | CPQ and subscription lifecycle | Not implemented. | Add quotes, bundles, price rules, billing schedules, proration, usage, and contract lifecycle only after a product requirement is confirmed. | F-012, F-016. | P2 |
| F-018 | Customer health scoring | Not implemented. | Start with explainable deterministic score using overdue balances, DSO, activity recency, and pipeline risk. | F-013, F-016. | P2 |
| F-019 | Anomaly detection | Local AI proposal foundation exists; financial anomaly pipeline is incomplete. | Add deterministic journal rules, duplicate detection, unusual amount/time/user signals, risk queue, explanation, and later model evaluation. | F-004, F-005, audit data. | P1/P2 |
| F-020 | GNN fraud detection | Not implemented and no training graph exists. | Research/evaluate only after sufficient labeled transaction graph and explainability dataset exists. | F-019, scale decision, data governance. | P3 |
| F-021 | LLM audit copilot | Governed local AI foundation exists; audit retrieval is incomplete. | Add read-only report explanation, anomaly summarization, source references, redaction, and confirmation-gated proposals. | F-019, AI governance. | P2 |
| F-022 | Tenant-scoped policy RAG | Not implemented. | Add document ingestion, tenant-filtered retrieval, citations, retention rules, and no-write answer mode. | F-005, AI provider/local model decision. | P2 |
| F-023 | Local/TFLite intelligence | Deterministic rule-based local engine and Android bridge scaffold exist. | Expand small local models only for classification/extraction where quality and privacy are demonstrable; preserve proposal-only behavior. | F-021, evaluation data. | P2 |
| F-024 | Extension/plugin framework | No reviewed extension registry exists. | Add versioned internal extension interfaces, reviewed rule registry, capability declarations, input/output schemas, and kill switches. | F-001, F-003. | P2 |
| F-025 | WASM plugin sandbox | Not implemented and operationally high risk. | Evaluate only if external customization demand justifies sandbox runtime, signing, quotas, and support. | F-024, infrastructure decision. | P3 |
| F-026 | Event sourcing/CQRS | Immutable posted entries and audit foundations exist; full event sourcing is absent. | Preserve append-only financial facts and build projections/read models first; evaluate full event sourcing only for a new bounded context. | F-004, F-005, scale decision. | P3 |
| F-027 | Bi-temporal financial data | Not implemented. | Add valid-time and transaction-time fields to selected audit/event records before applying them to the core ledger. | F-005, F-026, policy decision. | P3 |
| F-028 | OLAP/ClickHouse replica | Not implemented. | Measure report load and query plans; add an analytical replica only if PostgreSQL cannot satisfy measured requirements. | F-006, observability. | P3 |
| F-029 | Kafka/Debezium CDC mesh | Not implemented. | Use Supabase outbox and bounded workers first; evaluate CDC only for proven integration/volume needs. | F-005, scale decision. | P3 |
| F-030 | Microservices extraction | Not implemented; current modular monolith is intentional. | Introduce façades, contract tests, shadow traffic, and one bounded extraction only after organizational/scale need. | All P0/P1 contracts, observability. | P3 |
| F-031 | Flutter modular frontend | Package boundaries and shared UI exist; micro-frontends do not fit Flutter. | Enforce package API boundaries, shared design system, route ownership, and feature-level test suites. | F-001, UX audit. | P0/P1 |
| F-032 | Micro-frontend federation | Not applicable to the current Flutter application. | Do not implement unless product changes to a web host/remote-module strategy. | Platform decision. | Deferred |
| F-033 | Enterprise consolidation/intercompany | Not implemented. | Add multi-entity model, intercompany transfers, eliminations, currency translation, and close workflow only after confirmed need. | F-008, F-009, F-012. | P2/P3 |
| F-034 | Import/export jobs | Employee import exists; general import/export center is incomplete. | Add reusable jobs, templates, previews, validation, idempotency, error downloads, exports, retention, and audit. | F-005, F-031. | P1 |
| F-035 | Provider integrations | Google/Drive and invitation provider foundations exist; status/diagnostics are uneven. | Add explicit configured/pending/failed/unavailable states, server-side credentials, provider health, and retry controls. | F-005, F-031. | P1 |
| F-036 | Full UX modernization | Partial audit and recent localized screens exist. | Cover all screens for English/Arabic, RTL, validation, accessibility, responsive layouts, overflow, loading, empty, error, and permission states. | All feature waves. | P1 |

## Dependency map

The implementation order is deliberately dependency-driven:

```text
Schema/data preflight + authorization
              |
              v
Typed domain contracts + immutable ledger commands
              |
      +-------+--------+
      |                |
      v                v
Dimensions/FX/Tax   Outbox/Sync/Reconciliation
      |                |
      +-------+--------+
              v
AR/AP + Inventory/POS bridges
              |
              v
CRM 360 + operational dashboards
              |
              v
Controlled OCR + anomaly signals + policy RAG
              |
              v
Scale evaluation: OLAP, CDC, service extraction, WASM, GNN
```

## Implementation contract

Each feature must ship as a complete vertical slice. A vertical slice includes a domain model, a typed repository/use case, an additive migration or an explicit no-schema decision, server authorization and audit behavior, offline/sync behavior if mutable, localized UI, validation and error states, tests, migration notes, and a release verification record.

No blueprint feature may automatically post financial entries, bypass a locked period, cross a tenant or branch boundary, send unapproved messages, expose secrets, mutate source code, or treat a local cache as final accounting truth. Any feature requiring production SQL, an external provider, a persistent worker, a paid analytical service, autonomous AI execution, or destructive schema cleanup must stop at an approval gate until the user explicitly authorizes it.

## Immediate execution wave

The first implementation wave should be P0 foundation work: schema/data-quality preflight, centralized permission/branch evaluation, completion of immutable ledger commands and reconciliation, durable outbox contracts, and searchable audit review. The next wave should implement dimensions, exchange-rate provenance, deterministic tax, AR/AP settlement/aging, and Inventory/POS accounting bridges. Only after those contracts are stable should controlled OCR, anomaly triage, policy retrieval, and optional revenue schedules begin.
