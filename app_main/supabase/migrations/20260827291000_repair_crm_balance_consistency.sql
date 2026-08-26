-- Keep CRM balance columns synchronized with invoice and bill outstanding
-- amounts without overwriting opening balances or separately posted adjustments.
-- This migration is intentionally not applied automatically; deploy it through
-- the project's approved Supabase migration process.

create or replace function public.refresh_customer_balance_from_invoices()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_contribution bigint := 0;
  v_new_contribution bigint := 0;
begin
  if tg_op in ('UPDATE', 'DELETE')
     and old.status not in ('void', 'paid') then
    v_old_contribution := old.total_amount - old.amount_paid;
  end if;

  if tg_op in ('INSERT', 'UPDATE')
     and new.status not in ('void', 'paid') then
    v_new_contribution := new.total_amount - new.amount_paid;
  end if;

  if tg_op = 'INSERT' then
    update public.customers
       set balance = balance + v_new_contribution,
           updated_at = timezone('utc', now())
     where id = new.customer_id
       and tenant_id = new.tenant_id;
  elsif tg_op = 'DELETE' then
    update public.customers
       set balance = greatest(balance - v_old_contribution, 0),
           updated_at = timezone('utc', now())
     where id = old.customer_id
       and tenant_id = old.tenant_id;
  elsif (old.tenant_id, old.customer_id) is distinct from
        (new.tenant_id, new.customer_id) then
    update public.customers
       set balance = greatest(balance - v_old_contribution, 0),
           updated_at = timezone('utc', now())
     where id = old.customer_id
       and tenant_id = old.tenant_id;
    update public.customers
       set balance = balance + v_new_contribution,
           updated_at = timezone('utc', now())
     where id = new.customer_id
       and tenant_id = new.tenant_id;
  else
    update public.customers
       set balance = greatest(balance - v_old_contribution + v_new_contribution, 0),
           updated_at = timezone('utc', now())
     where id = new.customer_id
       and tenant_id = new.tenant_id;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists refresh_customer_balance_after_invoice
  on public.invoices;
create trigger refresh_customer_balance_after_invoice
after insert or update of tenant_id, customer_id, total_amount, amount_paid, status or delete
on public.invoices
for each row
execute function public.refresh_customer_balance_from_invoices();

create or replace function public.refresh_vendor_balance_from_bills()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_old_contribution bigint := 0;
  v_new_contribution bigint := 0;
begin
  if tg_op in ('UPDATE', 'DELETE')
     and old.status not in ('void', 'paid') then
    v_old_contribution := old.total_amount - old.amount_paid;
  end if;

  if tg_op in ('INSERT', 'UPDATE')
     and new.status not in ('void', 'paid') then
    v_new_contribution := new.total_amount - new.amount_paid;
  end if;

  if tg_op = 'INSERT' then
    update public.vendors
       set balance = balance + v_new_contribution,
           updated_at = timezone('utc', now())
     where id = new.vendor_id
       and tenant_id = new.tenant_id;
  elsif tg_op = 'DELETE' then
    update public.vendors
       set balance = greatest(balance - v_old_contribution, 0),
           updated_at = timezone('utc', now())
     where id = old.vendor_id
       and tenant_id = old.tenant_id;
  elsif (old.tenant_id, old.vendor_id) is distinct from
        (new.tenant_id, new.vendor_id) then
    update public.vendors
       set balance = greatest(balance - v_old_contribution, 0),
           updated_at = timezone('utc', now())
     where id = old.vendor_id
       and tenant_id = old.tenant_id;
    update public.vendors
       set balance = balance + v_new_contribution,
           updated_at = timezone('utc', now())
     where id = new.vendor_id
       and tenant_id = new.tenant_id;
  else
    update public.vendors
       set balance = greatest(balance - v_old_contribution + v_new_contribution, 0),
           updated_at = timezone('utc', now())
     where id = new.vendor_id
       and tenant_id = new.tenant_id;
  end if;

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

drop trigger if exists refresh_vendor_balance_after_bill
  on public.bills;
create trigger refresh_vendor_balance_after_bill
after insert or update of tenant_id, vendor_id, total_amount, amount_paid, status or delete
on public.bills
for each row
execute function public.refresh_vendor_balance_from_bills();

revoke all on function public.refresh_customer_balance_from_invoices() from public, anon, authenticated;
revoke all on function public.refresh_vendor_balance_from_bills() from public, anon, authenticated;
