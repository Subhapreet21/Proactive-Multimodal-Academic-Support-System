-- Migration: Create ai_insights table for persistent AI trend caching
-- Run this in the Supabase SQL editor.

-- Enum for types of insights
CREATE TYPE ai_insight_type AS ENUM ('student_forecast', 'dept_audit');

-- Persistent AI insights table
CREATE TABLE public.ai_insights (
  id          uuid NOT NULL DEFAULT gen_random_uuid(),
  target_id   text NOT NULL,               -- Student UUID or dept name
  type        ai_insight_type NOT NULL,
  content     jsonb NOT NULL,              -- Raw JSON from Gemini
  last_updated timestamptz NOT NULL DEFAULT now(),
  is_stale    boolean NOT NULL DEFAULT false,
  CONSTRAINT ai_insights_pkey PRIMARY KEY (id),
  CONSTRAINT ai_insights_target_type_unique UNIQUE (target_id, type)
);

-- Index for fast lookups
CREATE INDEX ai_insights_target_type_idx ON public.ai_insights (target_id, type);

-- Enable Row Level Security (no public access; only service role from backend)
ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;

-- Grant full access to service role (used by the backend)
GRANT ALL ON public.ai_insights TO service_role;
