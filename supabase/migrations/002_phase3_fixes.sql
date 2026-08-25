-- =========================================================
-- Mizan Supabase Migration — Phase 3 Fixes
-- Run in: https://supabase.com/dashboard/project/eawkctancunjpatujzpu/sql/new
-- =========================================================


-- ─────────────────────────────────────────────────────────
-- 1. ADD MISSING COLUMNS TO `tenants`
--    The Dart code inserts: tax_id, phone, owner_uid,
--    subscription_status, currency — none of which exist yet.
-- ─────────────────────────────────────────────────────────
ALTER TABLE public.tenants
  ADD COLUMN IF NOT EXISTS tax_id TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS owner_uid UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS subscription_status TEXT NOT NULL DEFAULT 'trial',
  ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'USD';


-- ─────────────────────────────────────────────────────────
-- 2. ADD MISSING COLUMNS TO `user_profiles`
--    The Dart code upserts: role, is_pro — neither exist yet.
-- ─────────────────────────────────────────────────────────
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS role TEXT NOT NULL DEFAULT 'viewer',
  ADD COLUMN IF NOT EXISTS is_pro BOOLEAN NOT NULL DEFAULT false;


-- ─────────────────────────────────────────────────────────
-- 3. FIX: tenants.id should be TEXT (not UUID) to match
--    the Dart code which generates slug-based IDs like
--    "my-business-a3f2". We change the column type to TEXT.
--
--    NOTE: If your tenants table is empty, this is safe.
--    If it has data, back up first.
-- ─────────────────────────────────────────────────────────
-- The tenants.id column is currently UUID. The Dart code
-- sends a slug string. Two options:
--   Option A (recommended): Fix Dart code to use UUID (done in Step 3.2)
--   Option B: Change column to TEXT here
--
-- We are doing Option A (Dart code fix in Step 3.2),
-- so this comment is informational only — no SQL needed here.


-- ─────────────────────────────────────────────────────────
-- 4. CREATE handle_new_user() TRIGGER
--    Automatically creates a user_profiles row whenever
--    a new user signs up via Supabase Auth (email or OAuth).
--    Without this, user_profiles must be inserted manually
--    after every signup — which was causing "Bad state" errors.
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_profiles (
    id,
    email,
    display_name,
    role,
    is_pro
  )
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      NEW.email
    ),
    'owner',   -- first user of any session starts as owner
    false
  )
  ON CONFLICT (id) DO NOTHING;  -- safe for re-runs / upserts
  RETURN NEW;
END;
$$;

-- Drop if exists so we can recreate cleanly
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Fire AFTER INSERT so NEW.id is fully committed
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();


-- ─────────────────────────────────────────────────────────
-- 5. ENABLE ROW LEVEL SECURITY (RLS) ON CORE TABLES
--    (Skip if already enabled — IF NOT EXISTS handles it)
-- ─────────────────────────────────────────────────────────

-- tenants: only the owner can read/write their own tenant
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Owners can manage their tenant" ON public.tenants;
CREATE POLICY "Owners can manage their tenant"
  ON public.tenants
  FOR ALL
  USING (owner_uid = auth.uid())
  WITH CHECK (owner_uid = auth.uid());

-- user_profiles: users can only see/edit their own profile
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own profile" ON public.user_profiles;
CREATE POLICY "Users can read own profile"
  ON public.user_profiles
  FOR SELECT
  USING (id = auth.uid());

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile"
  ON public.user_profiles
  FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Allow the trigger function (SECURITY DEFINER) to insert profiles
DROP POLICY IF EXISTS "Service role can insert profiles" ON public.user_profiles;
CREATE POLICY "Service role can insert profiles"
  ON public.user_profiles
  FOR INSERT
  WITH CHECK (true);  -- SECURITY DEFINER function bypasses RLS anyway


-- ─────────────────────────────────────────────────────────
-- 6. ENABLE RLS ON SYNC TABLES
--    Client-side tenant filters are not an authorization boundary.
--    Restrict reads and writes to users whose profile belongs to the row's
--    tenant, including staff members who are not the tenant owner.
-- ─────────────────────────────────────────────────────────
DO $$
DECLARE
  sync_table TEXT;
BEGIN
  FOREACH sync_table IN ARRAY ARRAY[
    'synced_transactions',
    'synced_products',
    'synced_accounts',
    'synced_transaction_entries',
    'synced_orders',
    'synced_order_items',
    'synced_categories',
    'synced_inventory_cost_layers'
  ] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', sync_table);
    EXECUTE format('DROP POLICY IF EXISTS "Tenant members can manage sync data" ON public.%I', sync_table);
    EXECUTE format(
      'CREATE POLICY "Tenant members can manage sync data" ON public.%I
       FOR ALL
       USING (tenant_id IN (
         SELECT tenant_id FROM public.user_profiles WHERE id = auth.uid()
       ))
       WITH CHECK (tenant_id IN (
         SELECT tenant_id FROM public.user_profiles WHERE id = auth.uid()
       ))',
      sync_table
    );
  END LOOP;
END $$;


-- ─────────────────────────────────────────────────────────
-- 7. VERIFY — run this SELECT to confirm setup
-- ─────────────────────────────────────────────────────────
-- SELECT column_name, data_type
-- FROM information_schema.columns
-- WHERE table_name = 'tenants'
-- ORDER BY ordinal_position;

-- SELECT tgname, tgenabled
-- FROM pg_trigger
-- WHERE tgname = 'on_auth_user_created';
