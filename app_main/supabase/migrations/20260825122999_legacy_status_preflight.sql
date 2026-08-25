-- Mizan legacy-schema preflight repair
-- Run this once if an older migration copy still fails with:
-- ERROR: 42703: column "status" does not exist
-- It is safe to run repeatedly.

begin;

DO $$
BEGIN
  IF to_regclass('public.staff_members') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.staff_members ADD COLUMN IF NOT EXISTS status text';
    EXECUTE 'UPDATE public.staff_members SET status = ''active'' WHERE status IS NULL';
    EXECUTE 'ALTER TABLE public.staff_members ALTER COLUMN status SET DEFAULT ''active''';
    EXECUTE 'ALTER TABLE public.staff_members ALTER COLUMN status SET NOT NULL';
  END IF;

  IF to_regclass('public.invites') IS NOT NULL THEN
    EXECUTE 'ALTER TABLE public.invites ADD COLUMN IF NOT EXISTS is_used boolean';
    EXECUTE 'UPDATE public.invites SET is_used = false WHERE is_used IS NULL';
    EXECUTE 'ALTER TABLE public.invites ALTER COLUMN is_used SET DEFAULT false';
    EXECUTE 'ALTER TABLE public.invites ALTER COLUMN is_used SET NOT NULL';
    EXECUTE 'ALTER TABLE public.invites ADD COLUMN IF NOT EXISTS used_by uuid';
    EXECUTE 'ALTER TABLE public.invites ADD COLUMN IF NOT EXISTS used_at timestamptz';
    EXECUTE 'ALTER TABLE public.invites ADD COLUMN IF NOT EXISTS created_by uuid';
  END IF;
END;
$$;

COMMIT;
