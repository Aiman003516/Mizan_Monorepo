# Mizan AI Agent Edge Function

This function is the server-side gateway for the first Mizan AI Copilot release. It accepts authenticated requests from the Flutter app, derives and validates the active tenant, checks existing Mizan permissions, executes only bounded read-only tools through the user-scoped Supabase client, calls the configured LLM provider, and writes minimal conversation/audit records with the service-role client.

## Required Supabase secrets

Configure these in the target Supabase project’s Edge Function secrets. Never put them in Flutter, Git, or the SQL migration:

```text
# Preferred for the attached OpenRouter workflow:
OPENROUTER_API_KEY=<provider key>
MIZAN_AI_BASE_URL=https://openrouter.ai/api/v1
MIZAN_AI_MODELS=nvidia/nemotron-3.5-lightning:free,nvidia/nemotron-3-ultra-550b-a55b:free,google/gemma-4-26b-a4b-it:free,poolside/laguna-xs-2.1:free,nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free,google/gemma-4-31b-it:free

# Optional single-model override. MIZAN_AI_MODELS takes precedence for the fallback order.
MIZAN_AI_MODEL=<optional model id>

# Backward-compatible OpenAI-compatible provider configuration:
# OPENAI_API_KEY=<provider key>
# MIZAN_AI_BASE_URL=https://api.openai.com/v1
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are expected from the Supabase Edge Function runtime. The service-role key is used only by the function and is never returned to the client.

## Deploy

From a machine authenticated to the correct Supabase project:

```bash
supabase functions deploy mizan-ai-agent --project-ref eawkctancunjpatujzpu
supabase functions deploy mizan-ai-action --project-ref eawkctancunjpatujzpu
# Prefer the Supabase Dashboard secret manager for the provider key.
supabase secrets set --project-ref eawkctancunjpatujzpu OPENROUTER_API_KEY=... MIZAN_AI_BASE_URL=https://openrouter.ai/api/v1 MIZAN_AI_MODELS=...
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

The response contains `conversation_id`, `request_id`, `message`, `model`, `read_only: true`, and, when the user explicitly requests creation, an optional `action_proposal` containing `action_type`, `payload`, and `requires_confirmation: true`. The proposal never writes a record. The Flutter client sends it to `mizan-ai-action`, displays the validated preview, and requires a one-time confirmation token. The action function then calls the protected Phase 3 execution RPC and returns an audited result; guests and users without the required tenant permission remain blocked.

## Reference OpenRouter models

The attached reference agent used these six fallback IDs: `nvidia/nemotron-3.5-lightning:free`, `nvidia/nemotron-3-ultra-550b-a55b:free`, `google/gemma-4-26b-a4b-it:free`, `poolside/laguna-xs-2.1:free`, `nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free`, and `google/gemma-4-31b-it:free`. At runtime, Mizan queries the OpenRouter `/models` endpoint and keeps only configured IDs reported as available; if discovery fails, it uses the bounded configured fallback list. Model availability can change, so verify the endpoint before production rollout.

## Rollout checks

Test with an owner/manager, an ordinary tenant member, a guest, and a user from a second tenant. Confirm that a guest receives a local sign-in requirement, a non-authorized member receives a permission-safe response, a second tenant cannot be selected without membership, and no provider or service-role secret appears in Flutter logs or responses. Review `ai_audit_events` through a privileged operational path rather than granting direct client access.
