-- Mizan migration
-- id: 20260828020000_party_statements.sql
-- owner: ar-ap-reporting
-- prerequisites: 20260828010000_approval_balance_adjustment_gate.sql
-- changes: tenant-safe customer/vendor statement read contract with running balances
-- security: authenticated tenant membership, tenant-derived filtering, and restricted execution
-- verification: supabase/tests/20260828020000_party_statements.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

create or replace function public.party_statement(
  p_party_type text,
  p_party_id uuid,
  p_from date default null,
  p_to date default current_date
)
returns table(
  entry_date date,
  source_type text,
  source_id uuid,
  reference text,
  description text,
  currency_code text,
  debit_minor bigint,
  credit_minor bigint,
  balance_delta_minor bigint,
  running_balance_minor bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with events as (
    select
      i.invoice_date as entry_date,
      'invoice'::text as source_type,
      i.id as source_id,
      i.invoice_number as reference,
      coalesce(nullif(btrim(i.notes), ''), 'Invoice') as description,
      i.currency_code,
      i.total_amount::bigint as debit_minor,
      0::bigint as credit_minor,
      i.total_amount::bigint as balance_delta_minor
    from public.invoices i
    where p_party_type = 'customer'
      and i.tenant_id = public.current_tenant_id()
      and i.customer_id = p_party_id
      and i.status <> 'void'

    union all

    select
      b.bill_date,
      'bill'::text,
      b.id,
      b.bill_number,
      coalesce(nullif(btrim(b.notes), ''), 'Bill'),
      b.currency_code,
      0::bigint,
      b.total_amount::bigint,
      b.total_amount::bigint
    from public.bills b
    where p_party_type = 'vendor'
      and b.tenant_id = public.current_tenant_id()
      and b.vendor_id = p_party_id
      and b.status <> 'void'

    union all

    select
      s.settlement_date,
      'settlement'::text,
      s.id,
      coalesce(i.invoice_number, b.bill_number, s.id::text),
      'Posted settlement'::text,
      s.currency_code,
      case when s.direction = 'payable' then s.amount_minor else 0 end,
      case when s.direction = 'receivable' then s.amount_minor else 0 end,
      -s.amount_minor::bigint
    from public.ar_ap_settlements s
    left join public.invoices i on i.id = s.invoice_id and i.tenant_id = s.tenant_id
    left join public.bills b on b.id = s.bill_id and b.tenant_id = s.tenant_id
    where s.tenant_id = public.current_tenant_id()
      and s.status = 'posted'
      and (
        (p_party_type = 'customer' and s.direction = 'receivable' and i.customer_id = p_party_id)
        or
        (p_party_type = 'vendor' and s.direction = 'payable' and b.vendor_id = p_party_id)
      )

    union all

    select
      a.effective_date,
      'balance_adjustment'::text,
      a.id,
      coalesce(nullif(btrim(a.reference), ''), a.id::text),
      a.reason,
      a.currency_code,
      case
        when p_party_type = 'customer' and a.direction = 'increase' then a.amount_minor
        when p_party_type = 'vendor' and a.direction = 'decrease' then a.amount_minor
        else 0
      end,
      case
        when p_party_type = 'customer' and a.direction = 'decrease' then a.amount_minor
        when p_party_type = 'vendor' and a.direction = 'increase' then a.amount_minor
        else 0
      end,
      case when a.direction = 'increase' then a.amount_minor else -a.amount_minor end
    from public.balance_adjustments a
    where a.tenant_id = public.current_tenant_id()
      and a.party_type = p_party_type
      and a.party_id = p_party_id
      and a.status = 'posted'
  ),
  opening as (
    select coalesce(sum(e.balance_delta_minor), 0)::bigint as amount
    from events e
    where p_from is not null and e.entry_date < p_from
  ),
  filtered as (
    select e.*
    from events e
    where (p_from is null or e.entry_date >= p_from)
      and (p_to is null or e.entry_date <= p_to)
  )
  select
    f.entry_date,
    f.source_type,
    f.source_id,
    f.reference,
    f.description,
    f.currency_code,
    f.debit_minor,
    f.credit_minor,
    f.balance_delta_minor,
    (select amount from opening)
      + sum(f.balance_delta_minor) over (
          order by f.entry_date, f.source_type, f.source_id
          rows between unbounded preceding and current row
        )::bigint as running_balance_minor
  from filtered f
  order by f.entry_date, f.source_type, f.source_id;
$$;

revoke all on function public.party_statement(text, uuid, date, date) from public, anon;
grant execute on function public.party_statement(text, uuid, date, date) to authenticated;
