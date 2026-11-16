-- =============================================================================
-- Study Nova — Stage 7: Mission Mode
-- =============================================================================
-- This migration is ADDITIVE ONLY. It creates one new table and touches nothing
-- that already exists (courses, study_scans, code_projects are left alone).
--
-- Mission Mode works without this table: `MissionService` keeps missions in
-- memory and in a local JSON file, and only uses this table when Supabase is
-- reachable. Run this file when you want missions to follow the student across
-- devices.
--
-- The whole mission (days, tasks, milestones, quiz results) lives in the `data`
-- JSONB column, which is exactly `MissionModel.toJson()`. The scalar columns
-- exist so missions can be listed and sorted without parsing the payload.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.missions (
  -- TEXT, not UUID: a mission is created on the device first (offline capable)
  -- and keeps that id when it syncs.
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  subject TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'active',
  progress INT NOT NULL DEFAULT 0,
  duration_days INT NOT NULL DEFAULT 7,
  target_date TIMESTAMPTZ,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS missions_user_id_idx
  ON public.missions (user_id);

-- Row level security: a student can only ever see their own missions.
ALTER TABLE public.missions ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.handle_missions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_missions_updated_at ON public.missions;
CREATE TRIGGER set_missions_updated_at
BEFORE UPDATE ON public.missions
FOR EACH ROW EXECUTE FUNCTION public.handle_missions_updated_at();

DROP POLICY IF EXISTS "Users can create their own missions" ON public.missions;
CREATE POLICY "Users can create their own missions"
ON public.missions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can read their own missions" ON public.missions;
CREATE POLICY "Users can read their own missions"
ON public.missions
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own missions" ON public.missions;
CREATE POLICY "Users can update their own missions"
ON public.missions
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own missions" ON public.missions;
CREATE POLICY "Users can delete their own missions"
ON public.missions
FOR DELETE
USING (auth.uid() = user_id);
