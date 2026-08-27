begin;
select plan(16);

select has_table('public', 'balance_adjustments', 'manual adjustment register exists');
select has_function(
  'public',
  'post_manual_balance_adjustment',
  array['text','uuid','bigint','text','text','text','text','date','uuid','uuid','text'],
  'manual adjustment posting RPC exists'
);
select is(
  (select relrowsecurity from pg_class where oid = 'public.balance_adjustments'::regclass),
  true,
  'adjustment register has RLS enabled'
);
select is(
  has_function_privilege('anon', 'public.post_manual_balance_adjustment(text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)', 'EXECUTE'),
  false,
  'anonymous adjustment posting is blocked'
);
select is(
  has_function_privilege('authenticated', 'public.post_manual_balance_adjustment(text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)', 'EXECUTE'),
  true,
  'authenticated adjustment posting is available'
);
select is(
  has_table_privilege('authenticated', 'public.balance_adjustments', 'INSERT'),
  false,
  'direct adjustment inserts are blocked'
);
select is(
  has_table_privilege('authenticated', 'public.balance_adjustments', 'SELECT'),
  true,
  'authenticated adjustment history reads are available'
);
select ok(
  to_regclass('public.balance_adjustments_party_date_idx') is not null,
  'party/date adjustment index exists'
);
select ok(
  to_regclass('public.balance_adjustments_journal_idx') is not null,
  'journal adjustment index exists'
);
select ok(
  exists (select 1 from pg_trigger where tgrelid = 'public.balance_adjustments'::regclass and tgname = 'balance_adjustments_audit'),
  'adjustment audit trigger exists'
);
select ok(
  exists (select 1 from pg_trigger where tgrelid = 'public.balance_adjustments'::regclass and tgname = 'balance_adjustments_updated_at'),
  'adjustment timestamp trigger exists'
);
select ok(
  pg_get_functiondef('public.post_manual_balance_adjustment(text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)'::regprocedure) like '%journal_entries%'
  and pg_get_functiondef('public.post_manual_balance_adjustment(text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)'::regprocedure) like '%journal_lines%',
  'posting RPC writes canonical journal tables'
);
select ok(
  pg_get_functiondef('public.post_manual_balance_adjustment(text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)'::regprocedure) like '%v_new_balance < 0%',
  'posting RPC rejects negative resulting balances'
);
select ok(
  pg_get_functiondef('public.post_manual_balance_adjustment(text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)'::regprocedure) like '%base currency%',
  'posting RPC enforces base currency'
);
select ok(
  pg_get_functiondef('public.post_manual_balance_adjustment(text,uuid,bigint,text,text,text,text,date,uuid,uuid,text)'::regprocedure) like '%p_idempotency_key%',
  'posting RPC supports idempotent retries'
);
select ok(
  exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'balance_adjustments'
  ),
  'adjustment history is in the realtime publication'
);

select * from finish();
rollback;
