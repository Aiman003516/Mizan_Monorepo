# Mizan Global ERP Expansion Master Plan

**Author:** Manus AI
**Status:** Planning and architecture baseline; implementation proceeds in dependency-ordered vertical slices.
**Product direction:** Globally capable, Yemen-ready, offline-aware, Arabic-first modular ERP for small and midsize businesses.

## Executive strategy

Mizan should become broad without becoming fragile. The expansion therefore follows a **modular monolith** strategy: bounded contexts are separated by public typed contracts, server-authoritative financial commands, tenant-safe migrations, replaceable provider adapters, and app-shell composition. Feature breadth is delivered only after the underlying contracts can be tested and reconciled.

The main rule is:

> **No feature is complete when only its screen exists. A feature is complete when its domain contract, migration, authorization, repository, offline behavior, localization, tests, documentation, and release gate exist together.**

Supabase remains authoritative for authenticated business data, permissions, posted accounting, period locks, approvals, and audit facts. Drift remains the offline cache and durable outbox for local-first work. Local AI may classify, extract, summarize, or prepare proposals, but it does not become accounting authority.

## Capability inventory

| Context | Global capabilities to implement | Current Mizan position | Modular target |
|---|---|---|---|
| Ledger and finance | Double-entry journals, drafts, posting, reversals, periods, multi-currency, FX, tax, budgets, cash flow, close, fixed assets, revenue schedules | Strong server foundation with several reporting and contract components | `ledger_contracts` in `core_data`; ledger repositories own mutations; reports consume read contracts only |
| AR/AP | Invoices, bills, settlements, allocations, aging, statements, credit limits, collections, manual adjustments | Foundation exists; recent adjustment workflow is now auditable and double-entry | AR/AP owns document and settlement contracts; ledger receives typed posting commands |
| Banking and cash | Statement import, reconciliation rules, transfers, fees, cash accounts, proof and settlement | Partial reconciliation foundation | `banking` context with statement adapters, matching engine, review queue, and audit events |
| CRM and sales | Contacts, leads, opportunities, activities, scoring, forecasts, quotes, CPQ, customer health, interaction timeline | CRM pipeline and 360 foundations exist; UI composition remains incomplete | CRM owns relationship data and publishes typed customer/opportunity references |
| Procurement | Requisitions, purchase orders, receipts, returns, three-way match, vendor performance | Vendor/bill foundations exist; purchase-to-pay loop incomplete | Procurement owns procurement state; inventory and AP consume events/contracts |
| Inventory and POS | Warehouses, locations, transfers, reservations, lots, serials, expiry, cycle count, replenishment, valuation, POS sessions and close | Server bridge and POS foundations exist; operational workflow incomplete | Inventory owns stock movements and availability; accounting bridge is an adapter/use case |
| Tax and FX | Tax codes, jurisdiction rules, snapshots, inclusive/exclusive calculations, exchange-rate source/provenance, realized/unrealized FX | Deterministic tax and FX foundations exist | Tax/FX owns calculation contracts and immutable snapshots; documents consume decisions |
| Workforce and governance | Users, roles, branches, effective permissions, approvals, audit review, sessions | Invitation, roles, owner controls, and audit foundations exist | Security context owns permission evaluation and approval state; feature actions request decisions |
| Documents and intelligence | Import/export jobs, document inbox, OCR/extraction drafts, duplicate detection, confidence review | Import and protected intake foundations exist; OCR provider not enabled | Document context owns files/jobs/extraction evidence; no direct posting |
| Portals and communications | Customer/vendor portal, email/SMS/provider adapters, notifications, e-signature, delivery status | Provider foundations are uneven | Provider-neutral interfaces and outbox delivery; secrets stay server-side |
| Service and recurring revenue | Tickets, SLAs, warranties, field jobs, contracts, subscriptions, renewals, proration | Not enabled | Separate contexts with typed links to CRM, products, AR/AP, and ledger |
| Analytics | Drill-down dashboards, KPIs, forecast, actual-vs-budget, profitability, operational health | Several reports and dashboard foundations exist | Read-model/query contracts with period/currency/source metadata |
| AI governance | Proposal schema, local classification, report explanation, anomaly triage, policy retrieval, controlled execution | Governed local-AI and proposal foundations exist | Replaceable local/cloud model adapters; no direct authority |

## Implementation phases and exit gates

### Phase 1 — Architecture, contracts, and data-quality baseline

Create a migration registry, schema preflight, public contract inventory, dependency checks, and module READMEs. Record ownership for every domain table, RPC, provider, and route. Establish the rule that new feature-to-feature dependencies are blocked unless explicitly approved and time-bounded.

**Exit gate:** all current packages are inventoried, all known coupling is measured, and every subsequent feature has an owner, contract, migration plan, and test plan.

### Phase 2 — Security, approvals, branches, and audit

Complete effective permissions, branch scope, approval policies, maker-checker controls, delegation, approval history, audit search, session controls, and negative tenant/branch tests. Approval decisions must be server-enforced, not merely local settings.

**Exit gate:** unauthorized cross-tenant, cross-branch, and unauthorized approval actions fail at the database boundary.

### Phase 3 — Reconciliation, outbox, and month-end close

Build the sync center around mutation IDs, pending/failed/conflict/resolved states, retry/backoff, tombstones, idempotency, and repair actions. Add a close cockpit that checks bank reconciliation, open approvals, missing documents, AR/AP exceptions, tax checks, inventory variance, and period status.

**Exit gate:** every mutable workflow reports whether it is local, queued, cloud-confirmed, conflicted, or failed, and a repeated retry cannot duplicate financial effects.

### Phase 4 — Finance operations

Complete payment allocation, customer/vendor statements, collections, credit policy, cash-flow forecasting, scenario budgets, bank statement import/reconciliation, tax liability reporting, FX adjustment, fixed-asset scheduling, revenue schedules, and reproducible report filters.

**Exit gate:** document totals, open items, payments, tax, journals, and reports reconcile for the same tenant, period, and currency parameters.

### Phase 5 — Procurement and document intake

Implement requisitions, purchase orders, receipts, returns, vendor performance, three-way matching, document inbox, controlled extraction drafts, confidence/anomaly review, duplicate detection, and approval queues. Extracted documents remain drafts until a human posts them through the ledger command boundary.

**Exit gate:** a vendor bill can be traced from source document to purchase order/receipt, approved variance, posted journal, payment allocation, and audit record.

### Phase 6 — Inventory, warehouse, POS, and pricing

Implement warehouse/location hierarchy, stock transfers, reservations, lots/serials, expiry, cycle counts, replenishment rules, stock adjustment approval, POS opening/closing, cash variance, returns, pricing lists, discounts, bundles, and margin checks. Keep stock valuation and ledger posting behind dedicated accounting bridges.

**Exit gate:** stock, cash, POS session, inventory valuation, and accounting effects reconcile after sale, purchase, return, transfer, and close.

### Phase 7 — CRM, CPQ, portals, service, and subscriptions

Complete CRM 360, activity plans, lead assignment/scoring, forecasts, quote templates, CPQ, customer/vendor portal, service tickets, SLAs, warranties, field jobs, subscriptions, renewals, proration, failed-payment states, and recurring revenue schedules.

**Exit gate:** a lead can become an opportunity, quote, order/invoice or service contract without direct cross-feature table access, and all external-party views obey tenant and role boundaries.

### Phase 8 — Local payments and integrations

Implement merchant-owned local payment methods for cash, bank transfer, and approved wallet workflows. Store immutable payment instruction snapshots, transaction references, proof claims, reviewer decisions, settlement links, and explicit states. Add provider-neutral email/SMS/e-signature interfaces, delivery status, retries, and audit history. Enable a provider only after credentials, callbacks, eligibility, and test evidence are approved.

**Exit gate:** payment proof never implies settlement; provider failure is visible; merchant payment details remain isolated; every delivery is traceable.

### Phase 9 — Analytics and forecasting

Add role-specific dashboards, drill-down from KPI to source records, profitability by dimensions, budget variance, cash forecast, inventory risk, CRM health, vendor performance, and close progress. Use indexed PostgreSQL/report functions first; add an analytical replica only if measured load requires it.

**Exit gate:** reports are reproducible with explicit tenant, period, currency, source, and filter metadata, and every KPI can explain its source.

### Phase 10 — Governed AI and document intelligence

Add read-only report explanations, anomaly triage, import mapping assistance, policy retrieval with citations, extraction confidence review, and confirmation-gated proposals. Local models remain small and privacy-preserving where practical; cloud adapters are replaceable and disabled by default until approved.

**Exit gate:** no model can bypass permissions, post without confirmation, cross a tenant, expose secrets, or claim an unavailable provider succeeded.

### Phase 11 — UX and localization hardening

Audit every screen for English/Arabic completeness, RTL-safe layouts, validation, keyboard behavior, accessibility, responsive narrow layouts, loading/empty/error/permission states, currency display, date/number formats, and honest offline/cloud labels. Add golden and device-oriented smoke coverage where possible.

**Exit gate:** static checks are clean, all localization references are defined in both catalogs, and physical-device verification records explicitly distinguish tested and untested behavior.

### Phase 12 — Scale, extensibility, and selective expansion

Add reviewed declarative extensions, custom fields, saved views, report templates, webhooks, integration registry, and feature kill switches. Consider multi-entity consolidation, projects, manufacturing, rental, sustainability, OLAP, CDC, or service extraction only after measured demand and operational readiness.

**Exit gate:** a new bounded context can be added or removed without editing private internals in unrelated contexts.

## Non-negotiable modular design rules

| Rule | Enforcement |
|---|---|
| One owner per domain concept | Ownership registry and code review checklist |
| No new feature-to-feature dependencies | Boundary audit script and CI gate |
| Public barrels only | Private implementation imports rejected in review |
| No screen-level business mutations | Repository/application layer and static search |
| Provider adapters are replaceable | Interfaces, fakes, disabled-state tests |
| Migrations are additive and owned | Migration header, registry, preflight, SQL regression |
| Financial facts are immutable | Reversal/adjustment commands, database constraints |
| Offline state is explicit | Sync status model and reconciliation UI |
| Localization is part of the feature | EN/AR catalogs, placeholder parity, RTL review |
| Feature removal is tested | Build/package contract tests and route isolation |

## Implementation order decision

The system will not attempt to add every business module at the same time. The safe sequence is **security and contracts → reconciliation → finance operations → procurement → inventory/POS → CRM/portals/service → integrations → analytics → controlled AI → scale options**. This still implements the full product direction, but prevents disconnected screens, duplicate tables, untestable provider assumptions, and irreversible accounting mistakes.

No production Supabase migration, external provider activation, automatic customer communication, or autonomous financial execution is implied by this plan. Those remain explicit deployment and approval gates.
