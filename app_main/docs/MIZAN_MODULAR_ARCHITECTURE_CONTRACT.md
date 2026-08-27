# Mizan Modular Architecture Contract

**Status:** Governing design standard for all future Mizan feature work.

## Purpose

Mizan must grow into a broad ERP without becoming a tightly coupled collection of screens. Every capability is therefore implemented as an independently understandable vertical slice with a stable public contract. A module may be replaced, disabled, or extended without allowing private UI classes, private database tables, or provider internals to leak across the application.

The current codebase already has useful package boundaries, but the dependency inventory shows several risks that must be reduced before large feature expansion. In particular, some feature packages depend directly on other feature packages, the dashboard aggregates many feature packages, and `shared_ui` depends on `core_data`. These are workable for the current application but are not a sufficient long-term boundary for an ERP with procurement, payments, warehouse operations, portals, service, recurring revenue, and integrations.

## Bounded contexts

| Context | Owns | Public contracts | Must not expose |
|---|---|---|---|
| `core_database` | Drift schema, migrations, local database connection, generated tables | Database provider and persistence primitives | Feature business decisions |
| `core_data` | Shared domain models, server RPC clients, repository interfaces, sync-safe read/write contracts | Typed DTOs, repository/use-case interfaces, error codes | Screen widgets or feature navigation |
| `core_l10n` | English/Arabic catalogs and generated localization API | `AppLocalizations` | Business state |
| `core_ui` | Theme, colors, typography, responsive primitives, validation primitives | Design-system widgets and extensions | Feature-specific data access |
| `shared_services` | File/media/picker and provider-neutral platform services | Service interfaces and adapters | Supabase business-table mutations |
| Ledger | Accounts, journals, periods, posting, reversals, reports | Journal commands, report queries, posting events | CRM profile and inventory UI state |
| AR/AP | Invoices, bills, settlements, aging, payment allocations | Document and settlement contracts | Direct ledger implementation details |
| CRM | Contacts, leads, opportunities, activities, customer health | Contact references, pipeline commands, CRM read models | Financial posting logic |
| Inventory/POS | Products, warehouses, stock movements, sessions, valuation inputs | Stock commands, POS events, availability queries | Direct journal writes |
| Procurement | Requisitions, purchase orders, receipts, three-way match | Procurement and receiving contracts | Private inventory/accounting tables |
| Tax/FX | Tax codes, tax snapshots, exchange-rate provenance | Calculation and explanation DTOs | Document lifecycle ownership |
| Workforce/Security | Users, roles, branches, approvals, audit access | Effective-permission and approval contracts | Business mutation shortcuts |
| Sync/Integration | Outbox, retries, conflicts, provider status, imports/exports | Delivery, reconciliation, provider contracts | Domain ownership of records |
| AI Governance | Proposals, tools, confidence, redaction, model status | Read-only insights and confirmation-gated proposals | Direct SQL or uncontrolled mutation |

## Required module shape

Every new bounded context or feature package must contain the following layers:

```text
feature_<context>/
  lib/
    src/
      domain/          # immutable entities, value objects, policies, error codes
      application/     # use cases, commands, queries, orchestration
      data/            # repository implementations, DTO mapping, adapters
      presentation/    # screens, widgets, controllers, providers
      integration/     # optional provider adapters; never required by domain
    feature_<context>.dart  # deliberate public barrel
  test/
    domain/
    application/
    data/
    presentation/
  README.md            # ownership, contracts, dependencies, workflows
```

Small packages may combine folders initially, but the ownership rules remain mandatory. Generated localization and database files remain in their owning core packages. Private files must not be imported by another package.

## Dependency rules

The allowed dependency direction is:

```text
core_database -> platform primitives
core_l10n     -> Flutter localization
core_ui       -> core_l10n and platform primitives
core_data     -> core_database and server adapters
shared_*      -> core_ui/core_l10n and platform abstractions
feature_*     -> core_data/core_ui/core_l10n/shared_*
app shell     -> feature public barrels
```

Feature-to-feature dependencies are prohibited by default. If two contexts must communicate, the producer exposes a typed contract in `core_data` or a dedicated contract package. The app shell composes feature routes. A temporary dependency requires a documented exception, an owner, a removal issue, and a test proving that private implementation types do not cross the boundary.

`shared_ui` must not become a second application layer. It may render generic data contracts and shared design-system primitives, but it must not own accounting/CRM repositories. If a shared widget needs business data, it receives a view model or callback from its feature package.

No feature may call Supabase table mutations directly from a screen. Server-authoritative mutations belong in a repository/application use case and must have a typed RPC contract, tenant/RLS check, idempotency behavior where needed, audit behavior, and a local-cache strategy.

## Vertical-slice completion contract

A feature is not complete when its screen exists. A vertical slice is complete only when it includes:

1. A domain model with explicit currency, date, status, and validation semantics.
2. A typed application command/query contract.
3. A repository implementation for local and authenticated cloud modes.
4. An additive migration or an explicit no-schema decision.
5. RLS, permissions, audit, and idempotency behavior for mutable cloud data.
6. Offline/cache/outbox behavior and visible reconciliation states.
7. English and Arabic localization, RTL-safe layout, accessibility semantics, and responsive states.
8. Domain, repository, database, and UI regression tests.
9. A feature README and deployment/migration notes.
10. A contract test proving that the feature does not import another feature’s private implementation.

## Current dependency risks to remediate

The first boundary audit measured **21 feature-to-feature dependency edges** and **9 feature source files with direct Supabase imports**. These numbers are a baseline, not an acceptable final state. The audit is currently diagnostic so the existing application can be migrated safely in waves; after the façade and contract migration is complete, CI should fail on new violations.

The baseline inventory identifies these risks:

| Risk | Current observation | Remediation |
|---|---|---|
| Feature cycles | `feature_accounts` references reports/transactions; `feature_reports` references accounts/transactions; transactions references products/reports; the graph is vulnerable to cycles. | Move shared report/account/transaction DTOs and query interfaces into `core_data`; make the app shell compose screens. |
| Dashboard aggregation | `feature_dashboard` directly depends on many feature packages. | Replace feature imports with dashboard query contracts in `core_data` and route registration supplied by the app shell. |
| Shared UI data coupling | `shared_ui` depends on `core_data`. | Keep only generic view models and callbacks in shared UI; move business-specific widgets into owning feature packages. |
| Supabase leakage | Several feature packages list `supabase_flutter` directly. | Centralize business RPC and table access in `core_data`; retain direct provider dependencies only in explicit integration adapters. |
| Broad package exports | Public barrels can accidentally expose private implementation types. | Audit exports and require deliberate public APIs. |
| Schema ownership | New migrations are canonical, but feature ownership is not always explicit. | Add migration ownership headers and a migration registry with dependency/version checks. |

## Future extension policy

A new feature must be addable through a new package or bounded-context folder, a public contract, a migration, and app-shell route registration without editing unrelated feature internals. Replacing a provider must require changing only an adapter and configuration. Disabling a feature must leave the ledger, CRM, and sync packages compilable and usable.

The architecture deliberately prefers a modular monolith over premature microservices. Stable contracts, dependency checks, migration gates, and integration adapters preserve a future path to service extraction without paying distributed-system costs before Mizan’s volume and operational needs justify them.

## Modularity release gates

| Gate | Required condition |
|---|---|
| G1: Contract ownership | Every new domain object has one owning context and one public contract. |
| G2: Dependency direction | No new feature-to-feature edge is added; existing edges must have a migration owner. |
| G3: Data access | Screens and generic UI contain no direct business-table writes. |
| G4: Replaceable adapters | Provider-specific code is behind an interface and can be disabled without changing domain rules. |
| G5: Migration safety | Every migration declares owner, prerequisites, additive behavior, RLS, rollback/forward-fix notes, and verification SQL. |
| G6: Feature removal | Disabling a feature package does not break core ledger, CRM, sync, or app compilation. |
| G7: Test isolation | Domain tests do not require Supabase; repository tests can use fakes; database tests include tenant and permission negatives. |
| G8: Documentation | Each feature ships a README, workflow matrix, API/RPC contract, localization inventory, and deployment note. |
