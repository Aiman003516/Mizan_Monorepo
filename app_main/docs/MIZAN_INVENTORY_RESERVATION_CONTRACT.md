# Mizan Inventory Reservation Contract

## Purpose

Reservations protect available inventory for an approved operational reference such as a POS sale or order without changing authoritative on-hand quantity. `inventory_balances` remains the stock owner; reservations are commitments layered over that balance.

## Rules

| Rule | Contract |
|---|---|
| Scope | Every reservation is tenant-scoped and uses the authenticated tenant session. |
| Availability | Available quantity is on-hand quantity less active, non-expired reservations for the same warehouse, product, and currency. |
| Concurrency | The authoritative inventory balance is locked before availability is calculated. |
| Idempotency | A tenant-scoped idempotency key returns the existing reservation instead of creating a duplicate. |
| Release | Only an active reservation can be released; the release actor and timestamp are recorded. |
| Expiry | An expiry must be in the future. Expired reservations no longer reduce available quantity, but a cleanup policy should later mark them explicitly as expired. |
| Posting | Reservation does not post inventory, journal entries, cash, or revenue. Posting remains governed by the inventory/POS accounting commands. |
| Security | Direct table writes are revoked. RPCs enforce authenticated membership and operational permissions; RLS protects reads. |

## Current slice

The additive migration provides reserve and release RPCs, audit triggers, an available-reservation index, typed `core_data` repository methods, and structural/unit coverage. The existing POS draft command still performs its own posting-time stock guard; future work should consume reservations atomically when an approved POS sale is posted and release them on cancellation or expiry.

Live staging execution, realtime behavior, background expiry cleanup, and physical-device UX are not claimed by static checks.
