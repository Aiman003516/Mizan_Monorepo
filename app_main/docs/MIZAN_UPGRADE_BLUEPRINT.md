# Mizan Comprehensive Upgrade Blueprint

## Executive direction

Mizan will evolve as a server-authoritative, tenant-isolated accounting and CRM platform with a local-first Flutter client. Supabase will own identity, authorization, financial mutations, audit records, and cross-device truth. Drift will remain an offline cache and outbox, never an authority for finalized accounting state. Accounting logic, CRM logic, synchronization, employee administration, and presentation remain separate feature boundaries.

The upgrade is intentionally staged. Each stage must be independently testable and reversible. Database migrations are additive by default, include compatibility guards for the current cloud schema, and are never applied to production from the development sandbox without explicit approval and a verified backup or rollback plan.

## Current baseline

The repository is on `main` at the invitation/onboarding repair commit that follows the previous work. The Flutter workspace contains 16 packages and approximately 94 screen files. The deterministic localization/validation audit matched 97 screen, page, dialog, and form surfaces, 1,820 English messages, 1,844 Arabic messages, zero missing Arabic keys, zero placeholder mismatches, 184 hard-coded-text candidates, 57 files containing field widgets, 87 explicit validators, and 19 existing test files. The audit is a prioritization signal, not proof of device, RTL, authenticated-backend, or production-database correctness.

The current Supabase history contains the cloud foundation, realtime, employee invitation phases, owner control center, and AI phases. The existing foundation already covers tenants, profiles, roles, staff, invitations, currencies, custom fields, customers, vendors, invoices, invoice items, bills, bill items, and audit logs. The main structural risks are schema drift from legacy tables, broad client table grants, partial accounting ledger coverage, uneven RLS/policy coverage for newer tables, inconsistent server-side mutation contracts, incomplete synchronization semantics, and UI/validation inconsistency outside the recently repaired invitation flow.

## Target architecture

| Boundary | Target responsibility | Non-negotiable rule |
|---|---|---|
| Flutter presentation | Responsive English/Arabic UI, accessibility, field validation feedback, loading/empty/error/permission states | Never decide authorization, posting, settlement, or tenant membership locally |
| Feature application layer | Use-case orchestration for accounting, CRM, inventory, reports, staff, import, and sync | One typed request/response contract per use case; no SQL or business rules hidden in widgets |
| Core domain | Double-entry invariants, money/currency/tax value objects, CRM transitions, invitation states, sync conflicts | Deterministic and testable without Flutter or Supabase |
| Supabase database | Tenant isolation, authorization, atomic financial mutations, reporting views, audit trails, idempotency | All sensitive writes are server-validated and tenant-scoped |
| Drift cache/outbox | Offline read cache and durable pending mutations | Finalized financial state is never accepted as cloud truth from a stale client |
| Integration boundary | Google continuation, Drive backup, approved email/SMS providers, AI Edge Functions | Credentials stay server-side; unavailable providers produce honest status, never fabricated success |
| Observability | Migration checks, structured client/server errors, sync diagnostics, audit review, performance metrics | Sensitive values are redacted from logs |

## Upgrade order

### Foundation and security

First establish a canonical schema inventory and a migration preflight that detects legacy columns, duplicate identifiers, orphaned tenant references, invalid role references, malformed currency codes, unbalanced journal data, and missing RLS. Then add shared authorization helpers, explicit permission names, immutable audit events, idempotency keys, soft-delete rules, and indexes that match tenant-scoped access paths.

### Accounting integrity

Introduce or normalize journal entries and journal lines as the authoritative posting model. Enforce debit/credit balancing, account and currency consistency, closed-period protection, document-to-journal links, reversal instead of destructive edits, and server-side totals. Add tax codes, tax-inclusive/exclusive calculation rules, exchange-rate provenance, realized/unrealized foreign-exchange handling, and report views for trial balance, balance sheet, profit and loss, cash flow, AR/AP aging, and audit history.

### CRM and operational workflows

Unify customers and vendors around reusable contact identity while retaining accounting-specific AR/AP balances. Add leads, opportunities, pipeline stages, activities, notes, attachments, interaction history, reminders, ownership, and conversion links. Every CRM-to-accounting transition must create a traceable reference and preserve the accounting snapshot used for documents.

### Workforce, import, and sync

Complete employee lifecycle administration, role templates, branch scoping, invitation/onboarding, import previews, durable outbox processing, conflict rules, retry/backoff, tombstones, and export/backup contracts. Provider-dependent email, SMS, Drive, and Google capabilities must expose configured, pending, failed, or unavailable states explicitly.

### Experience and intelligence

Apply shared localization, RTL, validation, responsive layout, and accessibility standards across all 97 audited surfaces. Replace raw backend errors with safe localized messages and retain diagnostic correlation IDs. Keep local AI proposal-only by default, with explicit permission checks and confirmation for any server action; no model may bypass database authorization or edit source code.

## Migration contract

Every migration must be numbered chronologically, additive where possible, and include a preflight section. It must be safe to run after the current history, avoid secrets, include indexes concurrently only when deployment tooling supports it, use `security definer` functions with an explicit `search_path`, revoke public execution, grant only intended roles, and add RLS policies for every exposed table. Destructive changes require a separate expand/migrate/contract sequence and an explicit approval checkpoint.

Every financial mutation function must validate the authenticated user, tenant membership, permission, input shape, referenced tenant ownership, currency and period rules, idempotency key, and audit event in one transaction. Client table grants should be reduced over time in favor of narrowly scoped RPCs and read-only reporting views.

## Initial feature backlog

| Priority | Upgrade | Acceptance signal |
|---|---|---|
| P0 | Canonical ledger, journal posting, period locks, RLS review, migration preflight | No unbalanced posted journal can be created; cross-tenant reads/writes fail in automated tests |
| P0 | Sync/outbox contract and conflict handling | Offline mutations retry safely, remain tenant-scoped, and never duplicate a server mutation |
| P0 | Complete auth, roles, branch scope, audit review, and invitation onboarding | Every membership and permission change is traceable and server-enforced |
| P1 | Multi-currency and tax engine | Stored minor units and rates reconcile with document totals and reports |
| P1 | Financial reporting views and export | Trial balance balances and reports are reproducible for a selected period |
| P1 | CRM pipeline and interaction history | Lead-to-customer conversion preserves ownership and audit references |
| P1 | Inventory, warehouse, costing, and POS reconciliation | Stock and journal movements are atomic and reportable |
| P2 | Import/export center and backup/restore UX | Imports are previewed, validated, idempotent, and reversible where possible |
| P2 | Provider integrations and observability | Provider state is explicit and failures are diagnosable without leaking secrets |
| P2 | Local AI expansion | Proposals are versioned, permission checked, confirmation gated, and auditable |
| P3 | UI modernization and performance pass | Narrow Android and desktop web paths are responsive, localized, and free from critical overflow |

## Definition of done

A feature is not complete when its screen compiles. It is complete only when its domain contract, server migration, authorization, audit behavior, sync behavior, localization, validation, error state, tests, and release notes are present. Static analysis must pass, affected package tests must pass, migration structure must be checked, and any device or live-Supabase behavior not exercised must be labeled as unverified.
