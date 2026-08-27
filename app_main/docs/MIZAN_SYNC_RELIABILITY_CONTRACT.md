# Mizan Synchronization Reliability Contract

## Purpose

Mizan uses the server as the authoritative source for authenticated tenant business data and financial facts. Drift remains a local cache, offline guest store, and retry queue. A local button press is not equivalent to server persistence.

## State semantics

| State | Meaning | Permitted financial interpretation |
|---|---|---|
| `local_draft` | Created or edited locally and not yet submitted | Not a posted or authoritative fact |
| `queued` | Waiting for an authenticated retry or event worker | Not confirmed by the server |
| `processing` | A server worker has claimed the event | Still not confirmed |
| `server_confirmed` | The authoritative server command or event completed successfully | May be displayed as synchronized; posting rules still apply |
| `rejected` | The server refused the command | Must not be treated as saved |
| `conflict` | Local and server versions require review | Must not overwrite the server silently |
| `failed` | Delivery or processing failed and may be retried | Must remain visible until resolved or successfully retried |

## Server contract

The `get_sync_health_snapshot()` RPC derives tenant scope from the authenticated session and returns aggregate counts only: pending, processing, failed, succeeded, and open conflicts. It does not expose event payloads. It is safe for dashboard summaries but is not a substitute for source-record reconciliation.

Mutation commands should remain idempotent, return the authoritative record or command result, and preserve audit evidence. A retry must either return the prior successful result or perform one controlled operation. Conflict resolution must record the actor, resolution note, and resulting state.

## UI contract

The dashboard displays synchronization status separately from local financial totals. Guest or unauthenticated users see that cloud status requires sign-in rather than a false “up to date” message. Failed events and open conflicts use attention styling and should eventually link to a detailed operator queue.

## Scope limits

This slice adds the aggregate server health RPC, typed core-data model, repository method, dashboard indicator, and unit/structural checks. It does not claim live realtime delivery, physical-device behavior, background worker deployment, or authenticated staging execution. Future work should connect individual mutation commands to the state model and add a conflict-resolution queue.
