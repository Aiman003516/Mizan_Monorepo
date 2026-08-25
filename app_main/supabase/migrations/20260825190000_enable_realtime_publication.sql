-- Enable Realtime for tables whose live updates are consumed by the Flutter app.
-- This migration is safe to run when the tables are already present in the
-- canonical schema and when some tables are already publication members.

do $$
declare
  table_name text;
begin
  if exists (
    select 1
    from pg_catalog.pg_publication
    where pubname = 'supabase_realtime'
  ) then
    foreach table_name in array array[
      'user_profiles',
      'staff_members',
      'roles',
      'customers',
      'vendors',
      'invoices',
      'invoice_items',
      'bills',
      'bill_items'
    ] loop
      if to_regclass(format('public.%I', table_name)) is not null then
        begin
          execute format(
            'alter publication supabase_realtime add table public.%I',
            table_name
          );
        exception
          when duplicate_object then
            null;
        end;
      end if;
    end loop;
  end if;
end;
$$;
