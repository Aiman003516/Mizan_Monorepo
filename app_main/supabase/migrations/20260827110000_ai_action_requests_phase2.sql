-- Mizan AI action requests Phase 2.
-- This stores previews only. No action is executed by this migration.

create table if not exists public.ai_action_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  conversation_id uuid references public.ai_conversations(id) on delete set null,
  action_type text not null check (action_type in (
    'invoice_draft',
    'bill_draft',
    'customer_draft',
    'vendor_draft',
    'journal_entry_draft',
    'staff_invitation_batch_draft'
  )),
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  preview jsonb not null check (jsonb_typeof(preview) = 'object'),
  status text not null default 'pending' check (status in (
    'pending', 'cancelled', 'expired', 'confirmed', 'executed', 'failed'
  )),
  idempotency_key uuid not null,
  created_at timestamptz not null default timezone('utc', now()),
  expires_at timestamptz not null default timezone('utc', now()) + interval '15 minutes',
  confirmed_at timestamptz,
  executed_at timestamptz,
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, user_id, idempotency_key)
);

create index if not exists ai_action_requests_user_status_idx
  on public.ai_action_requests (tenant_id, user_id, status, created_at desc, id);
create index if not exists ai_action_requests_expiry_idx
  on public.ai_action_requests (status, expires_at);

alter table public.ai_action_requests enable row level security;
revoke all on public.ai_action_requests from anon, authenticated;
grant all on public.ai_action_requests to service_role;

create or replace function public.touch_ai_action_request()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

revoke all on function public.touch_ai_action_request() from public, anon, authenticated;
drop trigger if exists ai_action_requests_touch_updated_at on public.ai_action_requests;
create trigger ai_action_requests_touch_updated_at
before update on public.ai_action_requests
for each row execute function public.touch_ai_action_request();
