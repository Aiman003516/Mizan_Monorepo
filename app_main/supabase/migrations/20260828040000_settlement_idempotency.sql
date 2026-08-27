-- Mizan migration
-- id: 20260828040000_settlement_idempotency.sql
-- owner: ar-ap-settlements
-- prerequisites: 20260828030000_close_preflight.sql
-- changes: settlement idempotency key and retry-safe draft RPC wrapper
-- security: tenant-derived lookup, transaction advisory lock, authenticated grant
-- verification: supabase/tests/20260828040000_settlement_idempotency.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

alter table public.ar_ap_settlements
  add column if not exists idempotency_key text;

create unique index if not exists ar_ap_settlements_idempotency_idx
  on public.ar_ap_settlements (tenant_id, idempotency_key)
  where idempotency_key is not null;

create or replace function public.create_settlement_draft_idempotent(
  p_idempotency_key text,
  p_direction text,
  p_invoice_id uuid,
  p_bill_id uuid,
  p_amount_minor bigint,
  p_currency_code text,
  p_settlement_date date,
  p_payment_method text,
  p_reference text,
  p_cash_account_id uuid,
  p_counterparty_account_id uuid,
  p_entry_number text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_existing jsonb;
  v_draft jsonb;
  v_settlement_id uuid;
begin
  if auth.uid() is null or v_tenant_id is null then
    raise exception using errcode = '42501', message = 'Authenticated tenant membership required';
  end if;
  if p_idempotency_key is null or length(btrim(p_idempotency_key)) not between 8 and 180 then
    raise exception using errcode = '22023', message = 'A valid settlement idempotency key is required';
  end if;

  perform pg_advisory_xact_lock(
    hashtextextended(v_tenant_id::text || ':' || btrim(p_idempotency_key), 0)
  );

  select jsonb_build_object(
    'settlement_id', s.id,
    'direction', s.direction,
    'invoice_id', s.invoice_id,
    'bill_id', s.bill_id,
    'amount_minor', s.amount_minor,
    'currency_code', s.currency_code,
    'settlement_date', s.settlement_date,
    'payment_method', s.payment_method,
    'reference', s.reference,
    'status', s.status,
    'journal_entry_id', s.journal_entry_id
  )
  into v_existing
  from public.ar_ap_settlements s
  where s.tenant_id = v_tenant_id
    and s.idempotency_key = btrim(p_idempotency_key);
  if v_existing is not null then
    return v_existing || jsonb_build_object('idempotency_key', btrim(p_idempotency_key));
  end if;

  v_draft := public.create_settlement_draft(
    p_direction,
    p_invoice_id,
    p_bill_id,
    p_amount_minor,
    p_currency_code,
    p_settlement_date,
    p_payment_method,
    p_reference,
    p_cash_account_id,
    p_counterparty_account_id,
    p_entry_number
  );
  v_settlement_id := (v_draft->>'settlement_id')::uuid;

  update public.ar_ap_settlements
  set idempotency_key = btrim(p_idempotency_key)
  where id = v_settlement_id
    and tenant_id = v_tenant_id;
  if not found then
    raise exception 'Settlement draft was not found after creation';
  end if;

  return v_draft || jsonb_build_object('idempotency_key', btrim(p_idempotency_key));
end;
$$;

revoke all on function public.create_settlement_draft_idempotent(text,text,uuid,uuid,bigint,text,date,text,text,uuid,uuid,text) from public, anon;
grant execute on function public.create_settlement_draft_idempotent(text,text,uuid,uuid,bigint,text,date,text,text,uuid,uuid,text) to authenticated;
