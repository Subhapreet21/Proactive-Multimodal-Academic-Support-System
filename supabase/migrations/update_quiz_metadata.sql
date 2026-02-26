-- Migration: Add Quiz Metadata Fields

ALTER TABLE public.quizzes
ADD COLUMN valid_from timestamp with time zone,
ADD COLUMN valid_until timestamp with time zone,
ADD COLUMN time_limit_mins integer,
ADD COLUMN target_year text,
ADD COLUMN is_active boolean DEFAULT true;

-- Update RLS if necessary to handle is_active flag.
-- Students should only see active quizzes.
DROP POLICY IF EXISTS "Quizzes are viewable by everyone" ON public.quizzes;

CREATE POLICY "Active quizzes are viewable by students" ON public.quizzes
  FOR SELECT USING (
    (
      -- Students see quizzes that are active and match their year (or have no target year constraint like 'All')
      is_active = true 
      AND (target_year IS NULL OR target_year = 'All' OR target_year = (
        SELECT year FROM public.profiles WHERE profiles.id = auth.uid()
      ))
    )
    OR 
    (
      -- Faculty and Admins can see everything
      EXISTS (
        SELECT 1 FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND (profiles.role = 'faculty' OR profiles.role = 'admin')
      )
    )
  );
