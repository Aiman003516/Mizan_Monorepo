-- Mizan AR/AP settlement foundation.
-- A settlement creates an accounting draft only. Invoice/bill balances change
-- only when the linked, balanced journal entry is posted by an authorized user.

create table if not exists public.ar_ap_settlements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  direction text not null check (direction in ('receivable', 'payable')),
  invoice_id uuid references public.invoices(id) on delete restrict,
  bill_id uuid references public.bills(id) on delete restrict,
  amount_minor bigint not null check (amount_minor > 0),
  currency_code text not null check (currency_code = upper(currency_code) and length(currency_code) between 3 and 5),
  settlement_date date not null,
  payment_method text not null check (length(btrim(payment_method)) between 1 and 60),
  reference text check (reference is null or length(btrim(reference)) <= 160),
  status text not null default 'draft_created'
    check (status in ('draft_created', 'posted', 'void')),
  journal_entry_id uuid references public.journal_entries(id) on delete restrict,
  created_by uuid references auth.users(id) on delete set null,
  posted_at timestamptz,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  check ((direction = 'receivable' and invoice_id is not null and bill_id is null)
      or (direction = 'payable' and bill_id is not null and invoice_id is null)),
  check ((status = 'posted' and journal_entry_id is not null and posted_at is not null) or status <> 'posted'),
  unique (tenant_id, id)
);

create index if not exists ar_ap_settlements_tenant_status_date_idx
  on public.ar_ap_settlements (tenant_id, status, settlement_date desc, id);
create index if not exists ar_ap_settlements_invoice_idx
  on public.ar_ap_settlements (tenant_id, invoice_id, status) where invoice_id is not null;
create index if not exists ar_ap_settlements_bill_idx
  on public.ar_ap_settlements (tenant_id, bill_id, status) where bill_id is not null;

create or replace function public.create_settlement_draft(
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
  v_user_id uuid := auth.uid();
  v_currency text := upper(btrim(p_currency_code));
  v_outstanding bigint;
  v_total bigint;
  v_paid bigint;
  v_document_currency text;
  v_document_status text;
  v_party_id uuid;
  v_settlement_id uuid;
  v_draft jsonb;
  v_entry_id uuid;
  v_cash_type text;
  v_counterparty_type text;
  v_permission text[];
begin
  if v_user_id is null or v_tenant_id is null then
    raise exception using errcode = '42501', message = 'Authenticated tenant membership required';
  end if;
  if p_direction not in ('receivable', 'payable') then
    raise exception using errcode = '22023', message = 'Settlement direction is invalid';
  end if;
  v_permission := case when p_direction = 'receivable'
    then array['manageCustomers','manageInvoices','manageAccounting','manageSettings']
    else array['manageVendors','manageBills','manageAccounting','manageSettings'] end;
  if not public.has_tenant_permission(v_tenant_id, v_permission) then
    raise exception using errcode = '42501', message = 'Settlement permission required';
  end if;
  if p_amount_minor is null or p_amount_minor <= 0 or v_currency !~ '^[A-Z]{3,5}$'
     or p_payment_method is null or length(btrim(p_payment_method)) = 0
     or p_entry_number is null or length(btrim(p_entry_number)) not between 1 and 80 then
    raise exception using errcode = '22023', message = 'Settlement data is invalid';
  end if;
  if p_direction = 'receivable' then
    if p_invoice_id is null or p_bill_id is not null then
      raise exception using errcode = '22023', message = 'A receivable settlement requires an invoice';
    end if;
    select i.total_amount, i.amount_paid, i.currency_code, i.status, i.customer_id
      into v_total, v_paid, v_document_currency, v_document_status, v_party_id
    from public.invoices i
    where i.id = p_invoice_id and i.tenant_id = v_tenant_id and i.status <> 'void'
    for update;
    if not found then raise exception using errcode = '22023', message = 'Invoice was not found'; end if;
  else
    if p_bill_id is null or p_invoice_id is not null then
      raise exception using errcode = '22023', message = 'A payable settlement requires a bill';
    end if;
    select b.total_amount, b.amount_paid, b.currency_code, b.status, b.vendor_id
      into v_total, v_paid, v_document_currency, v_document_status, v_party_id
    from public.bills b
    where b.id = p_bill_id and b.tenant_id = v_tenant_id and b.status <> 'void'
    for update;
    if not found then raise exception using errcode = '22023', message = 'Bill was not found'; end if;
  end if;
  if v_document_status in ('draft', 'pending') then
    raise exception using errcode = '22023', message = 'The document is not available for settlement';
  end if;
  if v_document_currency <> v_currency then
    raise exception using errcode = '22023', message = 'Settlement currency must match the document';
  end if;
  v_outstanding := v_total - v_paid;
  if p_amount_minor > v_outstanding then
    raise exception using errcode = '22023', message = 'Settlement exceeds the outstanding balance';
  end if;
  select a.account_type into v_cash_type from public.chart_of_accounts a
    where a.id = p_cash_account_id and a.tenant_id = v_tenant_id and a.is_active;
  select a.account_type into v_counterparty_type from public.chart_of_accounts a
    where a.id = p_counterparty_account_id and a.tenant_id = v_tenant_id and a.is_active;
  if v_cash_type is distinct from 'asset' then
    raise exception using errcode = '42501', message = 'Cash account must be an active asset account';
  end if;
  if (p_direction = 'receivable' and v_counterparty_type is distinct from 'asset')
     or (p_direction = 'payable' and v_counterparty_type is distinct from 'liability') then
    raise exception using errcode = '42501', message = 'Counterparty account type is invalid for the settlement direction';
  end if;

  insert into public.ar_ap_settlements (
    tenant_id, direction, invoice_id, bill_id, amount_minor, currency_code,
    settlement_date, payment_method, reference, created_by
  ) values (
    v_tenant_id, p_direction, p_invoice_id, p_bill_id, p_amount_minor, v_currency,
    p_settlement_date, btrim(p_payment_method), nullif(btrim(p_reference), ''), v_user_id
  ) returning id into v_settlement_id;

  v_draft := public.create_journal_draft(
    btrim(p_entry_number),
    p_settlement_date,
    case when p_direction = 'receivable' then 'Customer payment settlement' else 'Supplier payment settlement' end,
    v_currency,
    1,
    case when p_direction = 'receivable' then
      jsonb_build_array(
        jsonb_build_object('account_id', p_cash_account_id, 'debit_minor', p_amount_minor, 'credit_minor', 0, 'currency_code', v_currency, 'line_number', 1),
        jsonb_build_object('account_id', p_counterparty_account_id, 'debit_minor', 0, 'credit_minor', p_amount_minor, 'currency_code', v_currency, 'line_number', 2)
      )
    else
      jsonb_build_array(
        jsonb_build_object('account_id', p_counterparty_account_id, 'debit_minor', p_amount_minor, 'credit_minor', 0, 'currency_code', v_currency, 'line_number', 1),
        jsonb_build_object('account_id', p_cash_account_id, 'debit_minor', 0, 'credit_minor', p_amount_minor, 'currency_code', v_currency, 'line_number', 2)
      )
    end
  );
  v_entry_id := (v_draft->>'id')::uuid;
  update public.journal_entries
  set source_type = 'settlement', source_id = v_settlement_id
  where id = v_entry_id and tenant_id = v_tenant_id;
  update public.ar_ap_settlements
  set journal_entry_id = v_entry_id
  where id = v_settlement_id and tenant_id = v_tenant_id;

  return v_draft || jsonb_build_object(
    'settlement_id', v_settlement_id,
    'direction', p_direction,
    'party_id', v_party_id,
    'outstanding_before_minor', v_outstanding
  );
end;
$$;

create or replace function public.sync_settlement_after_post()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_settlement public.ar_ap_settlements;
  v_new_paid bigint;
begin
  if new.status = 'posted' and new.source_type = 'settlement' and new.source_id is not null then
    select * into v_settlement from public.ar_ap_settlements
    where id = new.source_id and tenant_id = new.tenant_id and journal_entry_id = new.id for update;
    if found and v_settlement.status = 'draft_created' then
      if v_settlement.direction = 'receivable' then
        update public.invoices
        set amount_paid = amount_paid + v_settlement.amount_minor,
            status = case when amount_paid + v_settlement.amount_minor = total_amount then 'paid' else 'partial' end
        where id = v_settlement.invoice_id and tenant_id = new.tenant_id
          and amount_paid + v_settlement.amount_minor <= total_amount;
        if not found then raise exception 'Invoice balance changed before settlement posting'; end if;
      else
        update public.bills
        set amount_paid = amount_paid + v_settlement.amount_minor,
            status = case when amount_paid + v_settlement.amount_minor = total_amount then 'paid' else 'partial' end
        where id = v_settlement.bill_id and tenant_id = new.tenant_id
          and amount_paid + v_settlement.amount_minor <= total_amount;
        if not found then raise exception 'Bill balance changed before settlement posting'; end if;
      end if;
      update public.ar_ap_settlements
      set status = 'posted', posted_at = timezone('utc', now())
      where id = v_settlement.id and tenant_id = new.tenant_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists settlement_posted_sync on public.journal_entries;
create trigger settlement_posted_sync
after update of status on public.journal_entries
for each row execute function public.sync_settlement_after_post();

create or replace function public.receivables_aging(p_as_of date default current_date)
returns table(invoice_id uuid, customer_id uuid, invoice_number text, due_date date, currency_code text, total_amount bigint, amount_paid bigint, outstanding_minor bigint, days_overdue integer, aging_bucket text)
language sql stable security definer set search_path = public
as $$
  select i.id, i.customer_id, i.invoice_number, i.due_date, i.currency_code,
         i.total_amount, i.amount_paid, (i.total_amount - i.amount_paid)::bigint,
         greatest((p_as_of - i.due_date), 0)::integer,
         case when p_as_of <= i.due_date then 'current'
              when p_as_of - i.due_date <= 30 then '1_30'
              when p_as_of - i.due_date <= 60 then '31_60'
              when p_as_of - i.due_date <= 90 then '61_90'
              else 'over_90' end
  from public.invoices i
  where i.tenant_id = public.current_tenant_id()
    and i.status not in ('draft', 'paid', 'void')
    and i.total_amount > i.amount_paid
  order by i.due_date, i.invoice_number;
$$;

create or replace function public.payables_aging(p_as_of date default current_date)
returns table(bill_id uuid, vendor_id uuid, bill_number text, due_date date, currency_code text, total_amount bigint, amount_paid bigint, outstanding_minor bigint, days_overdue integer, aging_bucket text)
language sql stable security definer set search_path = public
as $$
  select b.id, b.vendor_id, b.bill_number, b.due_date, b.currency_code,
         b.total_amount, b.amount_paid, (b.total_amount - b.amount_paid)::bigint,
         greatest((p_as_of - b.due_date), 0)::integer,
         case when p_as_of <= b.due_date then 'current'
              when p_as_of - b.due_date <= 30 then '1_30'
              when p_as_of - b.due_date <= 60 then '31_60'
              when p_as_of - b.due_date <= 90 then '61_90'
              else 'over_90' end
  from public.bills b
  where b.tenant_id = public.current_tenant_id()
    and b.status not in ('paid', 'void')
    and b.total_amount > b.amount_paid
  order by b.due_date, b.bill_number;
$$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['ar_ap_settlements'] LOOP
    EXECUTE format('drop trigger if exists %I_updated_at on public.%I', t, t);
    EXECUTE format('create trigger %I_updated_at before update on public.%I for each row execute function public.set_updated_at()', t, t);
    EXECUTE format('drop trigger if exists %I_audit on public.%I', t, t);
    EXECUTE format('create trigger %I_audit after insert or update or delete on public.%I for each row execute function public.audit_row_change()', t, t);
    EXECUTE format('alter table public.%I enable row level security', t);
    EXECUTE format('revoke all on table public.%I from anon, authenticated', t);
  END LOOP;
END $$;

create policy ar_ap_settlements_select on public.ar_ap_settlements for select to authenticated
using (public.is_tenant_member(tenant_id));

revoke all on function public.create_settlement_draft(text, uuid, uuid, bigint, text, date, text, text, uuid, uuid, text) from public, anon;
revoke all on function public.receivables_aging(date) from public, anon;
revoke all on function public.payables_aging(date) from public, anon;
grant execute on function public.create_settlement_draft(text, uuid, uuid, bigint, text, date, text, text, uuid, uuid, text) to authenticated;
grant execute on function public.receivables_aging(date) to authenticated;
grant execute on function public.payables_aging(date) to authenticated;
