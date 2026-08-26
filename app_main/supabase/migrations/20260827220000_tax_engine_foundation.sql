-- Mizan deterministic tax engine foundation.
-- Additive only. Tax results are calculated and snapshotted server-side.

alter table public.tax_codes
  add column if not exists jurisdiction_code text,
  add column if not exists exemption_code text,
  add column if not exists effective_from date,
  add column if not exists effective_to date;

create table if not exists public.tax_calculation_snapshots (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  source_type text not null check (source_type in ('invoice', 'bill', 'journal', 'estimate', 'manual')),
  source_id uuid,
  tax_code_id uuid references public.tax_codes(id) on delete restrict,
  jurisdiction_code text,
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  taxable_minor bigint not null check (taxable_minor >= 0),
  net_minor bigint not null check (net_minor >= 0),
  tax_minor bigint not null check (tax_minor >= 0),
  total_minor bigint not null check (total_minor = net_minor + tax_minor),
  rate_percent numeric(7,4) not null check (rate_percent >= 0 and rate_percent <= 100),
  is_inclusive boolean not null default false,
  is_exempt boolean not null default false,
  formula text not null,
  calculated_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  created_by uuid references auth.users(id) on delete set null,
  unique (tenant_id, source_type, source_id)
);

create index if not exists tax_snapshots_tenant_date_idx
  on public.tax_calculation_snapshots (tenant_id, calculated_at desc, id);
create index if not exists tax_snapshots_source_idx
  on public.tax_calculation_snapshots (tenant_id, source_type, source_id);

create or replace function public.calculate_tax(
  p_taxable_minor bigint,
  p_tax_code_id uuid,
  p_currency_code text,
  p_jurisdiction_code text default null,
  p_as_of date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_tax_code public.tax_codes;
  v_rate numeric;
  v_taxable bigint;
  v_tax bigint;
  v_is_exempt boolean;
  v_currency text := upper(btrim(p_currency_code));
  v_jurisdiction text;
  v_inclusive boolean;
begin
  if auth.uid() is null or v_tenant_id is null then
    raise exception using errcode = '42501', message = 'Authenticated tenant membership required';
  end if;
  if p_taxable_minor is null or p_taxable_minor < 0 then
    raise exception using errcode = '22003', message = 'Taxable amount cannot be negative';
  end if;
  if v_currency !~ '^[A-Z]{3,5}$' then
    raise exception using errcode = '22023', message = 'Currency code is invalid';
  end if;

  select * into v_tax_code
  from public.tax_codes
  where id = p_tax_code_id
    and tenant_id = v_tenant_id
    and is_active
    and (effective_from is null or effective_from <= p_as_of)
    and (effective_to is null or effective_to >= p_as_of)
    and (p_jurisdiction_code is null or jurisdiction_code is null or jurisdiction_code = p_jurisdiction_code)
  limit 1;

  if not found then
    raise exception using errcode = '22023', message = 'Tax code is unavailable for the tenant and date';
  end if;

  v_taxable := p_taxable_minor;
  v_rate := v_tax_code.rate_percent;
  v_inclusive := v_tax_code.is_inclusive;
  v_jurisdiction := coalesce(p_jurisdiction_code, v_tax_code.jurisdiction_code);
  v_is_exempt := v_tax_code.exemption_code is not null or v_rate = 0;

  if v_is_exempt then
    v_tax := 0;
  elsif v_inclusive then
    v_tax := round(v_taxable * v_rate / (100 + v_rate))::bigint;
  else
    v_tax := round(v_taxable * v_rate / 100)::bigint;
  end if;

  return jsonb_build_object(
    'taxable_minor', v_taxable,
    'net_minor', case when v_inclusive then v_taxable - v_tax else v_taxable end,
    'tax_minor', v_tax,
    'total_minor', case when v_inclusive then v_taxable else v_taxable + v_tax end,
    'currency_code', v_currency,
    'tax_code_id', v_tax_code.id,
    'tax_code', v_tax_code.code,
    'jurisdiction_code', v_jurisdiction,
    'rate_percent', v_rate,
    'is_inclusive', v_inclusive,
    'is_exempt', v_is_exempt,
    'formula', case
      when v_is_exempt then 'exempt'
      when v_inclusive then 'gross * rate / (100 + rate)'
      else 'net * rate / 100'
    end,
    'as_of', p_as_of
  );
end;
$$;

create or replace function public.record_tax_snapshot(
  p_source_type text,
  p_source_id uuid,
  p_tax_code_id uuid,
  p_currency_code text,
  p_taxable_minor bigint,
  p_jurisdiction_code text default null,
  p_as_of date default current_date
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := auth.uid();
  v_result jsonb;
  v_snapshot public.tax_calculation_snapshots;
begin
  if v_user_id is null or v_tenant_id is null then
    raise exception using errcode = '42501', message = 'Authenticated tenant membership required';
  end if;
  if p_source_type not in ('invoice', 'bill', 'journal', 'estimate', 'manual') then
    raise exception using errcode = '22023', message = 'Unsupported tax snapshot source type';
  end if;
  if p_source_id is null then
    raise exception using errcode = '22023', message = 'A source id is required for an idempotent tax snapshot';
  end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageAccounting','manageSales','managePurchasing','manageSettings']) then
    raise exception using errcode = '42501', message = 'Tax calculation permission required';
  end if;

  v_result := public.calculate_tax(
    p_taxable_minor,
    p_tax_code_id,
    p_currency_code,
    p_jurisdiction_code,
    p_as_of
  );

  insert into public.tax_calculation_snapshots (
    tenant_id, source_type, source_id, tax_code_id, jurisdiction_code,
    currency_code, taxable_minor, net_minor, tax_minor, total_minor,
    rate_percent, is_inclusive, is_exempt, formula, created_by
  ) values (
    v_tenant_id,
    p_source_type,
    p_source_id,
    p_tax_code_id,
    v_result->>'jurisdiction_code',
    v_result->>'currency_code',
    (v_result->>'taxable_minor')::bigint,
    (v_result->>'net_minor')::bigint,
    (v_result->>'tax_minor')::bigint,
    (v_result->>'total_minor')::bigint,
    (v_result->>'rate_percent')::numeric,
    (v_result->>'is_inclusive')::boolean,
    (v_result->>'is_exempt')::boolean,
    v_result->>'formula',
    v_user_id
  )
  on conflict (tenant_id, source_type, source_id)
  do update set
    tax_code_id = excluded.tax_code_id,
    jurisdiction_code = excluded.jurisdiction_code,
    currency_code = excluded.currency_code,
    taxable_minor = excluded.taxable_minor,
    net_minor = excluded.net_minor,
    tax_minor = excluded.tax_minor,
    total_minor = excluded.total_minor,
    rate_percent = excluded.rate_percent,
    is_inclusive = excluded.is_inclusive,
    is_exempt = excluded.is_exempt,
    formula = excluded.formula,
    calculated_at = timezone('utc', now()),
    created_by = excluded.created_by
  returning * into v_snapshot;

  return jsonb_build_object(
    'id', v_snapshot.id,
    'source_type', v_snapshot.source_type,
    'source_id', v_snapshot.source_id,
    'taxable_minor', v_snapshot.taxable_minor,
    'net_minor', v_snapshot.net_minor,
    'tax_minor', v_snapshot.tax_minor,
    'total_minor', v_snapshot.total_minor,
    'currency_code', v_snapshot.currency_code,
    'formula', v_snapshot.formula
  );
end;
$$;

DO $$
BEGIN
  execute 'drop trigger if exists tax_calculation_snapshots_updated_at on public.tax_calculation_snapshots';
  execute 'create trigger tax_calculation_snapshots_updated_at before update on public.tax_calculation_snapshots for each row execute function public.set_updated_at()';
  execute 'drop trigger if exists tax_calculation_snapshots_audit on public.tax_calculation_snapshots';
  execute 'create trigger tax_calculation_snapshots_audit after insert or update or delete on public.tax_calculation_snapshots for each row execute function public.audit_row_change()';
END $$;

alter table public.tax_calculation_snapshots enable row level security;
revoke all on table public.tax_calculation_snapshots from anon, authenticated;
create policy tax_snapshots_select on public.tax_calculation_snapshots for select to authenticated
using (public.is_tenant_member(tenant_id));

revoke all on function public.calculate_tax(bigint, uuid, text, text, date) from public, anon;
revoke all on function public.record_tax_snapshot(text, uuid, uuid, text, bigint, text, date) from public, anon;
grant execute on function public.calculate_tax(bigint, uuid, text, text, date) to authenticated;
grant execute on function public.record_tax_snapshot(text, uuid, uuid, text, bigint, text, date) to authenticated;
