-- Mizan CRM 360 and governed CPQ foundation.
-- Health is a deterministic advisory score, not an automated credit decision.
-- Quotes never create invoices or ledger entries until a separately approved
-- conversion workflow is added.

create table if not exists public.crm_customer_health_scores (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  customer_id uuid not null references public.customers(id) on delete cascade,
  score integer not null check (score between 0 and 100),
  risk_level text not null check (risk_level in ('healthy', 'watching', 'at_risk')),
  factors jsonb not null default '{}'::jsonb,
  calculated_at timestamptz not null default timezone('utc', now()),
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, customer_id),
  unique (tenant_id, id)
);

create table if not exists public.crm_quotes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  quote_number text not null check (length(btrim(quote_number)) between 1 and 80),
  customer_id uuid not null references public.customers(id) on delete restrict,
  opportunity_id uuid references public.crm_opportunities(id) on delete set null,
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  subtotal_minor bigint not null default 0 check (subtotal_minor >= 0),
  tax_minor bigint not null default 0 check (tax_minor >= 0),
  total_minor bigint not null default 0 check (total_minor = subtotal_minor + tax_minor),
  valid_until date,
  status text not null default 'draft' check (status in ('draft', 'sent', 'accepted', 'rejected', 'expired', 'cancelled')),
  notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  unique (tenant_id, quote_number),
  unique (tenant_id, id)
);

create table if not exists public.crm_quote_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  quote_id uuid not null references public.crm_quotes(id) on delete cascade,
  line_number integer not null check (line_number > 0),
  description text not null check (length(btrim(description)) between 1 and 500),
  quantity numeric(18,6) not null check (quantity > 0),
  unit_price_minor bigint not null check (unit_price_minor >= 0),
  line_total_minor bigint not null check (line_total_minor = round(quantity * unit_price_minor)),
  unique (quote_id, line_number),
  unique (tenant_id, id)
);

create index if not exists crm_health_tenant_risk_idx
  on public.crm_customer_health_scores (tenant_id, risk_level, score desc, updated_at desc);
create index if not exists crm_quotes_customer_status_idx
  on public.crm_quotes (tenant_id, customer_id, status, updated_at desc);
create index if not exists crm_quote_lines_quote_idx
  on public.crm_quote_lines (tenant_id, quote_id, line_number);

create or replace function public.record_crm_interaction(
  p_entity_type text,
  p_entity_id uuid,
  p_channel text,
  p_direction text,
  p_summary text,
  p_occurred_at timestamptz default timezone('utc', now())
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_id uuid;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageCrm','manageCustomers','manageSettings']) then raise exception 'CRM permission required'; end if;
  if p_entity_type not in ('lead', 'customer', 'vendor', 'opportunity')
     or p_channel not in ('phone', 'email', 'sms', 'whatsapp', 'meeting', 'note', 'other')
     or p_direction not in ('inbound', 'outbound', 'internal')
     or p_summary is null or length(btrim(p_summary)) not between 1 and 500 then
    raise exception 'Interaction data is invalid';
  end if;
  if not exists (
    select 1 from (
      select id, tenant_id from public.crm_leads where p_entity_type = 'lead'
      union all select id, tenant_id from public.customers where p_entity_type = 'customer'
      union all select id, tenant_id from public.vendors where p_entity_type = 'vendor'
      union all select id, tenant_id from public.crm_opportunities where p_entity_type = 'opportunity'
    ) entities where entities.id = p_entity_id and entities.tenant_id = v_tenant_id
  ) then raise exception 'CRM entity does not belong to the tenant'; end if;
  insert into public.crm_interactions (tenant_id, entity_type, entity_id, channel, direction, summary, occurred_at, created_by)
  values (v_tenant_id, p_entity_type, p_entity_id, p_channel, p_direction, btrim(p_summary), coalesce(p_occurred_at, timezone('utc', now())), auth.uid())
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'entity_type', p_entity_type, 'entity_id', p_entity_id);
end;
$$;

create or replace function public.calculate_customer_health(p_customer_id uuid)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_customer public.customers;
  v_overdue_count integer;
  v_outstanding bigint;
  v_recent_interactions integer;
  v_open_opportunities integer;
  v_score integer := 70;
  v_risk text;
  v_factors jsonb;
  v_id uuid;
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageCrm','manageCustomers','manageSettings']) then raise exception 'CRM permission required'; end if;
  select * into v_customer from public.customers where id = p_customer_id and tenant_id = v_tenant_id and not is_deleted;
  if not found then raise exception 'Customer was not found'; end if;
  select count(*)::integer, coalesce(sum(i.total_amount - i.amount_paid), 0)::bigint
    into v_overdue_count, v_outstanding
  from public.invoices i
  where i.tenant_id = v_tenant_id and i.customer_id = p_customer_id
    and i.status not in ('draft', 'paid', 'void') and i.total_amount > i.amount_paid
    and i.due_date < current_date;
  select count(*)::integer into v_recent_interactions
  from public.crm_interactions x
  where x.tenant_id = v_tenant_id and x.entity_type = 'customer' and x.entity_id = p_customer_id
    and x.occurred_at >= timezone('utc', now()) - interval '90 days';
  select count(*)::integer into v_open_opportunities
  from public.crm_opportunities o
  where o.tenant_id = v_tenant_id and o.customer_id = p_customer_id and o.status = 'open' and not o.is_deleted;

  v_score := greatest(0, least(100, v_score - least(v_overdue_count * 10, 40)));
  if v_customer.credit_limit > 0 and v_outstanding > v_customer.credit_limit then v_score := greatest(0, v_score - 15); end if;
  if v_recent_interactions > 0 then v_score := least(100, v_score + 10); end if;
  if v_open_opportunities > 0 then v_score := least(100, v_score + 5); end if;
  v_risk := case when v_score >= 70 then 'healthy' when v_score >= 45 then 'watching' else 'at_risk' end;
  v_factors := jsonb_build_object(
    'overdue_invoice_count', v_overdue_count,
    'outstanding_minor', v_outstanding,
    'credit_limit_minor', v_customer.credit_limit,
    'recent_interaction_count_90d', v_recent_interactions,
    'open_opportunity_count', v_open_opportunities,
    'calculation', 'deterministic_advisory_v1'
  );
  insert into public.crm_customer_health_scores (tenant_id, customer_id, score, risk_level, factors, calculated_at)
  values (v_tenant_id, p_customer_id, v_score, v_risk, v_factors, timezone('utc', now()))
  on conflict (tenant_id, customer_id) do update set score = excluded.score, risk_level = excluded.risk_level, factors = excluded.factors, calculated_at = excluded.calculated_at;
  select id into v_id from public.crm_customer_health_scores where tenant_id = v_tenant_id and customer_id = p_customer_id;
  return jsonb_build_object('id', v_id, 'customer_id', p_customer_id, 'score', v_score, 'risk_level', v_risk, 'factors', v_factors);
end;
$$;

create or replace function public.list_customer_360()
returns table(customer_id uuid, customer_name text, email text, phone text, balance bigint, credit_limit bigint, invoice_count bigint, outstanding_minor bigint, overdue_invoice_count bigint, open_opportunity_count bigint, interaction_count bigint, health_score integer, health_risk_level text, health_factors jsonb)
language sql stable security definer set search_path = public
as $$
  select c.id, c.name, c.email, c.phone, c.balance, c.credit_limit,
    (select count(*) from public.invoices i where i.tenant_id = c.tenant_id and i.customer_id = c.id and i.status <> 'void'),
    (select coalesce(sum(i.total_amount - i.amount_paid), 0)::bigint from public.invoices i where i.tenant_id = c.tenant_id and i.customer_id = c.id and i.status not in ('draft', 'paid', 'void') and i.total_amount > i.amount_paid),
    (select count(*) from public.invoices i where i.tenant_id = c.tenant_id and i.customer_id = c.id and i.status not in ('draft', 'paid', 'void') and i.total_amount > i.amount_paid and i.due_date < current_date),
    (select count(*) from public.crm_opportunities o where o.tenant_id = c.tenant_id and o.customer_id = c.id and o.status = 'open' and not o.is_deleted),
    (select count(*) from public.crm_interactions x where x.tenant_id = c.tenant_id and x.entity_type = 'customer' and x.entity_id = c.id),
    h.score, h.risk_level, h.factors
  from public.customers c
  left join public.crm_customer_health_scores h on h.tenant_id = c.tenant_id and h.customer_id = c.id
  where c.tenant_id = public.current_tenant_id() and not c.is_deleted
  order by c.name;
$$;

create or replace function public.create_crm_quote_draft(
  p_quote_number text,
  p_customer_id uuid,
  p_opportunity_id uuid,
  p_currency_code text,
  p_valid_until date,
  p_notes text,
  p_lines jsonb
)
returns jsonb language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_quote_id uuid;
  v_line jsonb;
  v_count integer := 0;
  v_subtotal bigint := 0;
  v_quantity numeric;
  v_unit_price bigint;
  v_line_total bigint;
  v_currency text := upper(btrim(p_currency_code));
begin
  if auth.uid() is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageCrm','manageCustomers','manageInvoices','manageSettings']) then raise exception 'Quote permission required'; end if;
  if p_quote_number is null or length(btrim(p_quote_number)) not between 1 and 80 or v_currency !~ '^[A-Z]{3,5}$' or p_lines is null or jsonb_typeof(p_lines) <> 'array' or jsonb_array_length(p_lines) = 0 then raise exception 'Quote data is invalid'; end if;
  if not exists (select 1 from public.customers c where c.id = p_customer_id and c.tenant_id = v_tenant_id and not c.is_deleted) then raise exception 'Customer does not belong to the tenant'; end if;
  if p_opportunity_id is not null and not exists (select 1 from public.crm_opportunities o where o.id = p_opportunity_id and o.tenant_id = v_tenant_id and not o.is_deleted) then raise exception 'Opportunity does not belong to the tenant'; end if;
  insert into public.crm_quotes (tenant_id, quote_number, customer_id, opportunity_id, currency_code, valid_until, notes, created_by)
  values (v_tenant_id, btrim(p_quote_number), p_customer_id, p_opportunity_id, v_currency, p_valid_until, nullif(btrim(p_notes), ''), auth.uid()) returning id into v_quote_id;
  for v_line in select value from jsonb_array_elements(p_lines) loop
    v_count := v_count + 1;
    if nullif(btrim(v_line->>'description'), '') is null then raise exception 'Quote line description is required'; end if;
    v_quantity := nullif(v_line->>'quantity', '')::numeric;
    v_unit_price := nullif(v_line->>'unit_price_minor', '')::bigint;
    if v_quantity is null or v_quantity <= 0 or v_unit_price is null or v_unit_price < 0 then raise exception 'Quote line quantity or price is invalid'; end if;
    v_line_total := round(v_quantity * v_unit_price)::bigint;
    v_subtotal := v_subtotal + v_line_total;
    insert into public.crm_quote_lines (tenant_id, quote_id, line_number, description, quantity, unit_price_minor, line_total_minor)
    values (v_tenant_id, v_quote_id, v_count, btrim(v_line->>'description'), v_quantity, v_unit_price, v_line_total);
  end loop;
  update public.crm_quotes set subtotal_minor = v_subtotal, total_minor = v_subtotal where id = v_quote_id;
  return jsonb_build_object('id', v_quote_id, 'quote_number', p_quote_number, 'status', 'draft', 'subtotal_minor', v_subtotal, 'total_minor', v_subtotal, 'currency_code', v_currency);
exception when others then
  if v_quote_id is not null then delete from public.crm_quotes where id = v_quote_id; end if;
  raise;
end;
$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['crm_customer_health_scores','crm_quotes','crm_quote_lines'] LOOP
    EXECUTE format('drop trigger if exists %I_updated_at on public.%I', t, t);
    IF t <> 'crm_quote_lines' THEN EXECUTE format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t); END IF;
    EXECUTE format('drop trigger if exists %I_audit on public.%I', t, t);
    EXECUTE format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
    EXECUTE format('alter table public.%I enable row level security', t);
    EXECUTE format('revoke all on table public.%I from anon, authenticated', t);
  END LOOP;
END $$;

create policy crm_health_select on public.crm_customer_health_scores for select to authenticated using (public.is_tenant_member(tenant_id));
create policy crm_quotes_select on public.crm_quotes for select to authenticated using (public.is_tenant_member(tenant_id));
create policy crm_quote_lines_select on public.crm_quote_lines for select to authenticated using (public.is_tenant_member(tenant_id));

revoke all on function public.record_crm_interaction(text, uuid, text, text, text, timestamptz) from public, anon;
revoke all on function public.calculate_customer_health(uuid) from public, anon;
revoke all on function public.list_customer_360() from public, anon;
revoke all on function public.create_crm_quote_draft(text, uuid, uuid, text, date, text, jsonb) from public, anon;
grant execute on function public.record_crm_interaction(text, uuid, text, text, text, timestamptz) to authenticated;
grant execute on function public.calculate_customer_health(uuid) to authenticated;
grant execute on function public.list_customer_360() to authenticated;
grant execute on function public.create_crm_quote_draft(text, uuid, uuid, text, date, text, jsonb) to authenticated;
