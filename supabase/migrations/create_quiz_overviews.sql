-- Migration: Add Quiz Overviews Table for personalized AI feedback

CREATE TABLE IF NOT EXISTS public.quiz_overviews (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quiz_id uuid REFERENCES public.quizzes(id) ON DELETE CASCADE,
  student_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  student_summary text, -- Encouraging summary of knowledge gaps
  faculty_summary text, -- Clinical, actionable summary of concepts missed
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT quiz_overviews_pkey PRIMARY KEY (id),
  CONSTRAINT unique_student_quiz_overview UNIQUE (quiz_id, student_id)
);

-- Enable RLS
ALTER TABLE public.quiz_overviews ENABLE ROW LEVEL SECURITY;

-- Students can view their own overviews
CREATE POLICY "Students can view their own overviews" ON public.quiz_overviews
  FOR SELECT USING (student_id = auth.uid());

-- Students can insert/update their own overviews via the backend
CREATE POLICY "Students can insert their own overviews" ON public.quiz_overviews
  FOR INSERT WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update their own overviews" ON public.quiz_overviews
  FOR UPDATE USING (student_id = auth.uid());

-- Faculty/Admins can view ALL overviews (or specifically ones for quizzes they created)
-- For simplicity and global monitoring, allowing Faculty/Admins to see all overviews
CREATE POLICY "Faculty and Admins can view all overviews" ON public.quiz_overviews
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND (profiles.role = 'faculty' OR profiles.role = 'admin')
    )
  );
