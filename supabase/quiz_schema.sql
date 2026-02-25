-- Quiz System Schema Migration

-- 1. Create the Quizzes Table
CREATE TABLE public.quizzes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  kb_article_id uuid REFERENCES public.kb_articles(id) ON DELETE SET NULL, -- Optional link to KB
  content jsonb NOT NULL, -- Array of { question, options, correct_answer }
  created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT quizzes_pkey PRIMARY KEY (id)
);

-- 2. Create the Quiz Attempts Table
CREATE TABLE public.quiz_attempts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quiz_id uuid REFERENCES public.quizzes(id) ON DELETE CASCADE,
  student_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  score integer NOT NULL,
  total_questions integer NOT NULL,
  answers jsonb NOT NULL, -- Array of user's selected answers
  feedback text, -- AI generated feedback based on performance
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT quiz_attempts_pkey PRIMARY KEY (id)
);

-- 3. Enable RLS
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for Quizzes
-- Anyone can READ a quiz
CREATE POLICY "Quizzes are viewable by everyone" ON public.quizzes
  FOR SELECT USING (true);

-- Only Faculty and Admins can INSERT/UPDATE/DELETE quizzes
CREATE POLICY "Faculty and Admins can manage quizzes" ON public.quizzes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND (profiles.role = 'faculty' OR profiles.role = 'admin')
    )
  );

-- 5. RLS Policies for Quiz Attempts
-- Faculty/Admins can see ALL attempts. Students can ONLY see their own attempts.
CREATE POLICY "Users can view relevant quiz attempts" ON public.quiz_attempts
  FOR SELECT USING (
    student_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND (profiles.role = 'faculty' OR profiles.role = 'admin')
    )
  );

-- ONLY Students can INSERT an attempt (take a quiz)
CREATE POLICY "Students can submit quiz attempts" ON public.quiz_attempts
  FOR INSERT WITH CHECK (
    student_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'student'
    )
  );

-- No one should be UPDATING or DELETING an attempt once submitted to ensure academic integrity.
-- (Admins could technically bypass RLS if using service_role key).
