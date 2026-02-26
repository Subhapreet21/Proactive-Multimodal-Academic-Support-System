-- Migration: Add department targeting to quizzes + score tracking to overviews
-- Run this in your Supabase SQL editor BEFORE deploying backend changes.

-- 1. Add target_department column to quizzes
ALTER TABLE public.quizzes
ADD COLUMN IF NOT EXISTS target_department text;

-- 2. Add score tracking to quiz_overviews
ALTER TABLE public.quiz_overviews
ADD COLUMN IF NOT EXISTS latest_score integer,
ADD COLUMN IF NOT EXISTS total_questions integer;

-- 3. Update student quiz visibility RLS policy.
--    Students see a quiz only when ALL of the following are true:
--      a) is_active = true
--      b) valid_until is not set, or it's in the future
--      c) target_year matches (or is unconstrained)
--      d) target_department matches (or is unconstrained)
DROP POLICY IF EXISTS "Active quizzes are viewable by students" ON public.quizzes;

CREATE POLICY "Active quizzes are viewable by students" ON public.quizzes
  FOR SELECT USING (
    -- Branch 1: Student visibility (all four conditions must pass)
    (
      is_active = true
      AND (valid_until IS NULL OR valid_until > now())
      AND (
        target_year IS NULL
        OR target_year = 'All'
        OR target_year = (
          SELECT year FROM public.profiles WHERE profiles.id = auth.uid()
        )
      )
      AND (
        target_department IS NULL
        OR target_department = 'All'
        OR target_department = (
          SELECT department FROM public.profiles WHERE profiles.id = auth.uid()
        )
      )
    )
    OR
    -- Branch 2: Faculty and Admins see everything
    (
      EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND (profiles.role = 'faculty' OR profiles.role = 'admin')
      )
    )
  );
