-- Mizan migration
-- id: 20260828120000_governed_purchase_bill_posting.sql
-- owner: accounting-and-procurement
-- prerequisites: 20260828080000_purchase_bill_exception_workflow.sql
-- changes: governed purchase-bill posting with match and approved-exception enforcement
-- security: tenant/branch/permission scope, period controls, idempotency, audit, immutable posted journal
-- verification: supabase/tests/20260828120000_governed_purchase_bill_posting.sql
-- rollback: forward-fix only unless an approved backup/rollback plan exists

alter table public.bills add column if not exists journal_entry_id uuid references public.journal_entries(id) on delete restrict;
create unique index if not exists bills_journal_entry_unique_idx on public.bills (tenant_id, journal_entry_id) where journal_entry_id is not null;

create or replace function public.post_purchase_bill(
  p_bill_id uuid,
  p_debit_account_id uuid,
  p_payable_account_id uuid,
  p_entry_number text,
  p_posting_date date default current_date
)
returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_tenant_id uuid := public.current_tenant_id();
  v_user_id uuid := auth.uid();
  v_bill public.bills;
  v_branch_id uuid;
  v_eligibility jsonb;
  v_debit_type text;
  v_payable_type text;
  v_draft jsonb;
  v_entry_id uuid;
  v_date date := coalesce(p_posting_date, current_date);
begin
  if v_user_id is null or v_tenant_id is null then raise exception 'Authenticated tenant membership required'; end if;
  if not public.has_tenant_permission(v_tenant_id, array['manageBills','manageAccounting','postJournals','manageSettings']) then raise exception 'Purchase bill posting permission required'; end if;
  if p_entry_number is null or length(btrim(p_entry_number)) not between 1 and 80 or p_debit_account_id is null or p_payable_account_id is null then raise exception 'Purchase bill posting data is invalid'; end if;
  select * into v_bill from public.bills where id = p_bill_id and tenant_id = v_tenant_id for update;
  if not found or v_bill.status = 'void' then raise exception 'Purchase bill was not found'; end if;
  if v_bill.journal_entry_id is not null then
    return jsonb_build_object('bill_id', v_bill.id, 'journal_entry_id', v_bill.journal_entry_id, 'status', 'posted', 'idempotent', true);
  end if;
  if v_bill.status not in ('pending', 'partial', 'overdue') then raise exception 'Purchase bill is not postable'; end if;
  if v_date < v_bill.bill_date then raise exception 'Posting date cannot precede bill date'; end if;
  if v_bill.purchase_order_id is null then raise exception 'Purchase bill must be linked to a purchase order'; end if;
  select po.branch_id into v_branch_id from public.purchase_orders po where po.id = v_bill.purchase_order_id and po.tenant_id = v_tenant_id;
  if not public.approval_branch_access(v_tenant_id, v_branch_id) then raise exception 'Branch access required'; end if;
  v_eligibility := public.assert_purchase_bill_posting_eligibility(v_bill.id);
  select account_type into v_debit_type from public.chart_of_accounts where id = p_debit_account_id and tenant_id = v_tenant_id and is_active;
  select account_type into v_payable_type from public.chart_of_accounts where id = p_payable_account_id and tenant_id = v_tenant_id and is_active;
  if v_debit_type is null or v_debit_type not in ('asset', 'expense') or v_payable_type is distinct from 'liability' then raise exception 'Purchase bill accounts are invalid'; end if;
  v_draft := public.create_journal_draft(
    btrim(p_entry_number), v_date, 'Purchase bill ' || btrim(v_bill.bill_number), v_bill.currency_code, 1,
    jsonb_build_array(
      jsonb_build_object('account_id', p_debit_account_id, 'debit_minor', v_bill.total_amount, 'credit_minor', 0, 'currency_code', v_bill.currency_code, 'line_number', 1, 'description', 'Purchase bill expense or inventory'),
      jsonb_build_object('account_id', p_payable_account_id, 'debit_minor', 0, 'credit_minor', v_bill.total_amount, 'currency_code', v_bill.currency_code, 'line_number', 2, 'description', 'Vendor payable')
    )
  );
  v_entry_id := (v_draft->>'id')::uuid;
  update public.journal_entries set source_type = 'purchase_bill', source_id = v_bill.id where id = v_entry_id and tenant_id = v_tenant_id;
  update public.bills set journal_entry_id = v_entry_id where id = v_bill.id and tenant_id = v_tenant_id and journal_entry_id is null;
  if not found then raise exception 'Purchase bill was posted concurrently'; end if;
  perform public.post_journal_entry(v_entry_id);
  return jsonb_build_object('bill_id', v_bill.id, 'journal_entry_id', v_entry_id, 'status', 'posted', 'eligibility', v_eligibility, 'total_minor', v_bill.total_amount, 'currency_code', v_bill.currency_code);
end;
$$;

revoke all on function public.post_purchase_bill(uuid, uuid, uuid, text, date) from public, anon, authenticated;
grant execute on function public.post_purchase_bill(uuid, uuid, uuid, text, date) to authenticated;
