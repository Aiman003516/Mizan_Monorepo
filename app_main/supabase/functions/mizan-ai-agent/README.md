# Mizan AI Agent Edge Function

This function is the server-side gateway for the first Mizan AI Copilot release. It accepts authenticated requests from the Flutter app, derives and validates the active tenant, checks existing Mizan permissions, executes only bounded read-only tools through the user-scoped Supabase client, calls the configured LLM provider, and writes minimal conversation/audit records with the service-role client.

## Required Supabase secrets

Configure these in the target Supabase project’s Edge Function secrets. Never put them in Flutter, Git, or the SQL migration:

```text
OPENAI_API_KEY=<provider key>
MIZAN_AI_MODEL=gpt-5-mini
MIZAN_AI_BASE_URL=https://api.openai.com/v1
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are expected from the Supabase Edge Function runtime. The service-role key is used only by the function and is never returned to the client.

## Deploy

From a machine authenticated to the correct Supabase project:

```bash
supabase functions deploy mizan-ai-agent --project-ref eawkctancunjpatujzpu
supabase secrets set --project-ref eawkctancunjpatujzpu OPENAI_API_KEY=... MIZAN_AI_MODEL=gpt-5-mini MIZAN_AI_BASE_URL=https://api.openai.com/v1
```

Prefer setting the provider key through the Supabase Dashboard secret manager so it is not placed in shell history. The function is not usable until migration `20260827100000_ai_agent_phase1.sql` is applied and the provider secret is configured.

## Request contract

Use an authenticated Supabase session:

```json
{
  "message": "Why did expenses increase this month?",
  "locale": "en",
  "tenant_id": "active-tenant-uuid",
  "conversation_id": "optional-existing-conversation-uuid"
}
```

The response contains `conversation_id`, `request_id`, `message`, `model`, and `read_only: true`. The function never performs mutations. Requests to create, post, delete, invite, suspend, send, or change records must be handled as unsupported until a later confirmation-gated action phase is deployed.

## Rollout checks

Test with an owner/manager, an ordinary tenant member, a guest, and a user from a second tenant. Confirm that a guest receives a local sign-in requirement, a non-authorized member receives a permission-safe response, a second tenant cannot be selected without membership, and no provider or service-role secret appears in Flutter logs or responses. Review `ai_audit_events` through a privileged operational path rather than granting direct client access.
