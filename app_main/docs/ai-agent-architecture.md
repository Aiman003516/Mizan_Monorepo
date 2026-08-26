# Mizan Agentic AI Integration Plan

## Purpose

Add a security-first AI assistant to Mizan for Arabic and English accounting and CRM support. The assistant must be useful in guest mode without uploading guest data, while authenticated tenant mode may use server-side cloud tools under the existing Supabase authorization model.

## Product boundary

The first production slice is a read-only Mizan Copilot. It answers questions about the current tenant’s ledger, reports, customers, vendors, invoices, bills, budgets, staff roles, and invitations. It may propose an action plan, but it cannot post journals, alter balances, change staff roles, send messages, create invitations, or modify records without a separate confirmation workflow.

Guest mode remains local-first. Guest data stays in Drift and is not sent to a remote model. Guest users receive a local capability explanation and may use deterministic help content; remote tenant tools are unavailable until the user signs in and an active tenant membership is confirmed. The assistant must never infer that a guest record belongs to a cloud tenant.

## Architecture

The Flutter feature presents a localized chat and action-preview experience. It calls one authenticated Supabase Edge Function, `mizan-ai-agent`, through `supabase.functions.invoke`. The Edge Function validates the JWT, derives the active tenant from `staff_members`, checks the user’s role permissions, retrieves only bounded aggregates through tenant-scoped SQL/RPC tools, and calls the configured LLM provider server-side. Provider credentials are never shipped in Flutter.

The gateway uses a bounded tool registry rather than arbitrary SQL. Each tool has a name, JSON input schema, required permission, maximum result size, and audit category. The model can request tools only from this allowlist. The gateway validates tool arguments, applies tenant filters independently of model output, truncates results, and records request/tool/result metadata without storing unnecessary sensitive prompt data.

## Read-only tools for Phase 1

| Tool | Scope | Permission | Output rule |
| --- | --- | --- | --- |
| `get_financial_summary` | Revenue, expenses, receivables, payables, cash summary for a bounded period | `viewReports` | Aggregate values only |
| `get_profit_and_loss` | Existing P&L report for a bounded date range | `viewReports` | Account totals, bounded rows |
| `get_budget_variance` | Persisted budget versus ledger actuals | `viewReports` | Bounded budget lines and variance |
| `search_customers` | Tenant customers by name/email/phone | `viewCustomers` | Maximum 25 masked/bounded records |
| `get_customer_history` | One tenant customer’s interactions and balances | `viewCustomers` | Maximum 50 recent events |
| `search_vendors` | Tenant vendors by name/contact | `viewVendors` | Maximum 25 bounded records |
| `get_invoice_status` | Invoice status and aging summary | `viewInvoices` | Aggregate or bounded records |
| `get_staff_overview` | Staff counts and role/status overview | `manageStaff` | No secrets or auth tokens |

The initial implementation may expose only the financial summary and P&L tools until every package-specific query is available server-side. A missing tool must return a typed unsupported response, not a fabricated answer.

## Action phases

Phase 1 implements the read-only gateway and Flutter chat. Phase 2 adds structured drafts for invoices, bills, contacts, journal entries, and staff invitations. Drafts are stored as pending action requests and shown to the user with all material fields, currency, tax, tenant, and affected records. Phase 3 adds explicit confirmation tokens, server-side revalidation, atomic execution through existing business RPCs, and audit entries. Phase 4 may add scheduled summaries or anomaly checks only after a separate user opt-in and bounded workload policy.

## Security contract

The server is authoritative for authentication, tenant selection, permission checks, validation, accounting balance, tax calculations, and action execution. The model is not trusted for authorization, account identifiers, amounts, currency codes, tax rates, or record ownership. Every tool call is revalidated against the current authenticated tenant. Cross-tenant identifiers must fail closed. SECURITY DEFINER functions use an explicit `search_path` and the smallest possible execute grants.

Conversation history is tenant/user scoped. Prompt injection in customer notes, invoice descriptions, or CRM text is treated as untrusted data. Tool outputs are labeled as data and the model is instructed not to follow embedded instructions. Logs store event type, model/provider, tool name, latency, success/failure, and correlation IDs; prompt and result retention is minimized and configurable.

## Reliability and cost controls

Requests have a maximum number of model/tool turns, input length, output length, and wall-clock timeout. Duplicate requests use an idempotency key. Transient provider/network errors are retryable with bounded backoff; authorization, validation, quota, and configuration failures are not silently retried. The provider model is configurable server-side; the default should favor a fast economical model for routine assistance and a stronger model only for complex analysis.

## Localization and accessibility

All visible strings are localized in English and Arabic. The chat supports RTL layout, Arabic text, LTR email/account/code segments, narrow Samsung Note9 dimensions, keyboard/focus navigation, loading, empty, permission-denied, provider-unavailable, and offline states. Financial amounts use the existing currency formatter and never a hard-coded dollar sign.

## Deployment prerequisites

The Supabase Edge Function requires a provider secret configured in Supabase Functions secrets, for example `OPENAI_API_KEY`, and a provider base URL only if the chosen provider requires one. No provider secret belongs in the Flutter app, repository, migration, or client-side environment. The function deployment and secret setup are separate from SQL migrations and must be verified in the target Supabase project before enabling cloud AI.

## Acceptance criteria

The feature is ready for a controlled pilot only when read-only answers are tenant-isolated, guest data never leaves the device, unsupported questions are explicit, tool arguments are schema-validated, mutation attempts stop at a confirmation preview, all sensitive outcomes are auditable, Arabic/English UI tests pass, and provider failures produce safe localized errors. Physical Android validation must include Samsung Note9 narrow-layout testing, sign-in/session refresh, a tenant owner, a non-manager, and a guest user.
