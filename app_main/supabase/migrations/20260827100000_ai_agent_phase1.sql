-- Mizan AI Agent Phase 1.
-- Conversations and audit events are accessed through the server-side Edge Function.
-- Direct client table access remains revoked; service_role is used only inside the function.

create table if not exists public.ai_conversations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  locale text not null default 'en' check (locale in ('en', 'ar')),
  title text check (title is null or length(btrim(title)) between 1 and 160),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, user_id, id)
);

create index if not exists ai_conversations_user_updated_idx
  on public.ai_conversations (tenant_id, user_id, updated_at desc, id);

create table if not exists public.ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.ai_conversations(id) on delete cascade,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('user', 'assistant')),
  content text not null check (length(content) between 1 and 16000),
  model text,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists ai_messages_conversation_created_idx
  on public.ai_messages (conversation_id, created_at asc, id);
create index if not exists ai_messages_tenant_user_created_idx
  on public.ai_messages (tenant_id, user_id, created_at desc, id);

create table if not exists public.ai_audit_events (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null,
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid references public.ai_conversations(id) on delete set null,
  event_type text not null check (event_type in ('request', 'tool_call', 'response', 'error')),
  tool_name text,
  success boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists ai_audit_events_tenant_created_idx
  on public.ai_audit_events (tenant_id, created_at desc, id);
create index if not exists ai_audit_events_request_idx
  on public.ai_audit_events (request_id, created_at, id);

alter table public.ai_conversations enable row level security;
alter table public.ai_messages enable row level security;
alter table public.ai_audit_events enable row level security;

-- The Edge Function is the only application entry point. No Flutter client can
-- directly read, insert, update, or delete AI records with its publishable key.
revoke all on public.ai_conversations from anon, authenticated;
revoke all on public.ai_messages from anon, authenticated;
revoke all on public.ai_audit_events from anon, authenticated;
grant all on public.ai_conversations to service_role;
grant all on public.ai_messages to service_role;
grant all on public.ai_audit_events to service_role;

create or replace function public.touch_ai_conversation()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

revoke all on function public.touch_ai_conversation() from public, anon, authenticated;
drop trigger if exists ai_conversations_touch_updated_at on public.ai_conversations;
create trigger ai_conversations_touch_updated_at
before update on public.ai_conversations
for each row execute function public.touch_ai_conversation();
