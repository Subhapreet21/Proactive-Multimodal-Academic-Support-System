-- ============================================================
-- Campus Assistant — Authoritative Supabase Schema
-- WARNING: This file is for reference/documentation only.
-- It reflects the live Supabase database state.
-- Do NOT run this file directly against an existing database.
-- ============================================================

-- ─── Extensions ─────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS vector;

-- ─── Custom Types ───────────────────────────────────────────
CREATE TYPE ai_insight_type AS ENUM ('student_forecast', 'dept_audit');

-- ============================================================
-- CORE TABLES
-- ============================================================

-- Profiles (linked to Supabase Auth)
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  email text,
  full_name text,
  avatar_url text,
  role text CHECK (role = ANY (ARRAY['student'::text, 'faculty'::text, 'admin'::text])),
  department text,
  year text,
  section text,
  preferences jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

-- Timetables
CREATE TABLE public.timetables (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  day_of_week text NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  course_code text,
  course_name text,
  location text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  department text,
  year text,
  section text,
  CONSTRAINT timetables_pkey PRIMARY KEY (id),
  CONSTRAINT timetables_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

-- Timetable Metadata (stores structure JSON keyed by e.g. 'timetable_structure_CSE')
CREATE TABLE public.timetable_metadata (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  key text NOT NULL UNIQUE,
  value jsonb NOT NULL,
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT timetable_metadata_pkey PRIMARY KEY (id)
);

-- Reminders / Personal To-Dos
CREATE TABLE public.reminders (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  due_at timestamp with time zone NOT NULL,
  category text,
  is_completed boolean DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT reminders_pkey PRIMARY KEY (id),
  CONSTRAINT reminders_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

-- Conversations (Chat sessions)
CREATE TABLE public.conversations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT conversations_pkey PRIMARY KEY (id),
  CONSTRAINT conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

-- Messages (individual chat messages within a conversation)
CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL,
  sender_type text NOT NULL,
  content text,
  role text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id)
);

-- Events & Notices board
CREATE TABLE public.events_notices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  event_date timestamp with time zone,
  category text,
  location text,
  source_image_url text,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT events_notices_pkey PRIMARY KEY (id),
  CONSTRAINT events_notices_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);

-- Invitation Codes (for Faculty/Admin role promotion)
CREATE TABLE public.invitation_codes (
  code text NOT NULL,
  role text NOT NULL CHECK (role = ANY (ARRAY['faculty'::text, 'admin'::text])),
  usage_limit integer DEFAULT 1,
  used_count integer DEFAULT 0,
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  expires_at timestamp with time zone,
  CONSTRAINT invitation_codes_pkey PRIMARY KEY (code),
  CONSTRAINT invitation_codes_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id)
);

-- ============================================================
-- KNOWLEDGE BASE
-- ============================================================

-- KB Articles (University wiki content)
CREATE TABLE public.kb_articles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE,
  content text,
  category text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  author_id uuid,
  CONSTRAINT kb_articles_pkey PRIMARY KEY (id),
  CONSTRAINT kb_articles_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);

-- KB Embeddings (pgvector store for RAG)
-- NOTE: The live Supabase foreign key does NOT yet include ON DELETE CASCADE.
-- Recommended migration to apply in Supabase SQL editor:
--   ALTER TABLE public.kb_embeddings
--     DROP CONSTRAINT IF EXISTS kb_embeddings_article_id_fkey,
--     ADD CONSTRAINT kb_embeddings_article_id_fkey
--       FOREIGN KEY (article_id) REFERENCES public.kb_articles(id) ON DELETE CASCADE;
CREATE TABLE public.kb_embeddings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  article_id uuid,
  chunk_content text,
  embedding vector(768),
  metadata jsonb DEFAULT '{}'::jsonb,
  chunk_index integer,
  CONSTRAINT kb_embeddings_pkey PRIMARY KEY (id),
  CONSTRAINT kb_embeddings_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.kb_articles(id)
  -- Recommended: ON DELETE CASCADE (see note above)
);

-- ============================================================
-- ATTENDANCE
-- ============================================================

-- Attendance Sessions (one record per class slot per day)
CREATE TABLE public.attendance_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  timetable_id uuid,
  marked_by uuid,
  date date NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT attendance_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT attendance_sessions_timetable_id_fkey FOREIGN KEY (timetable_id) REFERENCES public.timetables(id),
  CONSTRAINT attendance_sessions_marked_by_fkey FOREIGN KEY (marked_by) REFERENCES public.profiles(id),
  -- Conflict prevention: only one session per class slot per calendar day
  CONSTRAINT unique_attendance_per_day UNIQUE (timetable_id, date)
);

-- Attendance Records (per-student, per-session)
CREATE TABLE public.attendance_records (
  session_id uuid NOT NULL,
  student_id uuid NOT NULL,
  status text CHECK (status = ANY (ARRAY['present'::text, 'absent'::text, 'late'::text])),
  CONSTRAINT attendance_records_pkey PRIMARY KEY (session_id, student_id),
  CONSTRAINT attendance_records_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.attendance_sessions(id),
  CONSTRAINT attendance_records_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id)
);

-- ============================================================
-- AI INSIGHTS (Stale-While-Revalidate forecasting cache)
-- ============================================================

CREATE TABLE public.ai_insights (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  target_id text NOT NULL,               -- Student UUID or '__dept__' for dept-level
  type ai_insight_type NOT NULL,         -- 'student_forecast' | 'dept_audit'
  content jsonb NOT NULL,                -- Raw JSON from Gemini
  last_updated timestamp with time zone NOT NULL DEFAULT now(),
  is_stale boolean NOT NULL DEFAULT false,
  CONSTRAINT ai_insights_pkey PRIMARY KEY (id),
  CONSTRAINT ai_insights_target_type_unique UNIQUE (target_id, type)
);

CREATE INDEX ai_insights_target_type_idx ON public.ai_insights (target_id, type);

-- ============================================================
-- QUIZZES & ASSESSMENTS
-- ============================================================

-- Quizzes (all metadata fields included; incorporates all migrations)
CREATE TABLE public.quizzes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  kb_article_id uuid,                    -- Optional link to a KB article
  content jsonb NOT NULL,                -- Array of { question, options[], correct_answer, explanation }
  created_by uuid,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  -- Scheduling & targeting (added via update_quiz_metadata migration)
  valid_from timestamp with time zone,
  valid_until timestamp with time zone,
  time_limit_mins integer,
  target_year text,
  is_active boolean DEFAULT true,
  max_attempts integer,
  -- Department targeting (added via add_quiz_dept_and_overview_score migration)
  target_department text,
  CONSTRAINT quizzes_pkey PRIMARY KEY (id),
  CONSTRAINT quizzes_kb_article_id_fkey FOREIGN KEY (kb_article_id) REFERENCES public.kb_articles(id),
  CONSTRAINT quizzes_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);

-- Quiz Attempts (individual student submissions)
CREATE TABLE public.quiz_attempts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quiz_id uuid,
  student_id uuid,
  score integer NOT NULL,
  total_questions integer NOT NULL,
  answers jsonb NOT NULL,                -- Array of user's selected answers
  feedback text,                         -- Optional AI-generated feedback
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT quiz_attempts_pkey PRIMARY KEY (id),
  CONSTRAINT quiz_attempts_quiz_id_fkey FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id),
  CONSTRAINT quiz_attempts_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id)
);

-- Quiz Overviews (AI-generated summaries per student per quiz)
-- Incorporates add_quiz_dept_and_overview_score migration (latest_score, total_questions)
CREATE TABLE public.quiz_overviews (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  quiz_id uuid,
  student_id uuid,
  student_summary text,                  -- Encouraging summary of knowledge gaps for student
  faculty_summary text,                  -- Clinical, actionable summary for faculty
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  -- Score tracking (added via add_quiz_dept_and_overview_score migration)
  latest_score integer,
  total_questions integer,
  CONSTRAINT quiz_overviews_pkey PRIMARY KEY (id),
  CONSTRAINT quiz_overviews_quiz_id_fkey FOREIGN KEY (quiz_id) REFERENCES public.quizzes(id),
  CONSTRAINT quiz_overviews_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.profiles(id),
  CONSTRAINT unique_student_quiz_overview UNIQUE (quiz_id, student_id)
);

-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events_notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kb_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kb_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitation_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quiz_overviews ENABLE ROW LEVEL SECURITY;

-- Grant full access to service_role (used exclusively by the Node.js backend)
GRANT ALL ON public.ai_insights TO service_role;

-- Profiles: users can read their own profile (required for RLS subqueries in quizzes)
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (id = auth.uid());

-- Quizzes: consolidated visibility policy (final state after all migrations)
-- Supersedes: "Quizzes are viewable by everyone", "Active quizzes are viewable by students"
DROP POLICY IF EXISTS "Quizzes are viewable by everyone" ON public.quizzes;
DROP POLICY IF EXISTS "Active quizzes are viewable by students" ON public.quizzes;
DROP POLICY IF EXISTS "Quiz Visibility for Students" ON public.quizzes;

CREATE POLICY "Quiz Visibility for Students" ON public.quizzes
  FOR SELECT USING (
    -- Students: must be active, unexpired, matching year and department
    (
      is_active = true
      AND (valid_until IS NULL OR valid_until > now())
      AND (
        target_year IS NULL
        OR target_year = 'All'
        OR target_year = (SELECT year FROM public.profiles WHERE profiles.id = auth.uid())
      )
      AND (
        target_department IS NULL
        OR target_department = 'All'
        OR target_department = (SELECT department FROM public.profiles WHERE profiles.id = auth.uid())
      )
    )
    OR
    -- Faculty and Admins see everything
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND (profiles.role = 'faculty' OR profiles.role = 'admin')
    )
  );

-- Faculty and Admins can manage quizzes (INSERT/UPDATE/DELETE)
DROP POLICY IF EXISTS "Faculty and Admins can manage quizzes" ON public.quizzes;
CREATE POLICY "Faculty and Admins can manage quizzes" ON public.quizzes
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND (profiles.role = 'faculty' OR profiles.role = 'admin')
    )
  );

-- Quiz Attempts: Students see their own; Faculty/Admins see all
CREATE POLICY "Users can view relevant quiz attempts" ON public.quiz_attempts
  FOR SELECT USING (
    student_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND (profiles.role = 'faculty' OR profiles.role = 'admin')
    )
  );

CREATE POLICY "Students can submit quiz attempts" ON public.quiz_attempts
  FOR INSERT WITH CHECK (
    student_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role = 'student'
    )
  );

-- Quiz Overviews: per-student AI feedback
CREATE POLICY "Students can view their own overviews" ON public.quiz_overviews
  FOR SELECT USING (student_id = auth.uid());

CREATE POLICY "Students can insert their own overviews" ON public.quiz_overviews
  FOR INSERT WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update their own overviews" ON public.quiz_overviews
  FOR UPDATE USING (student_id = auth.uid());

CREATE POLICY "Faculty and Admins can view all overviews" ON public.quiz_overviews
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND (profiles.role = 'faculty' OR profiles.role = 'admin')
    )
  );

-- ============================================================
-- RPC FUNCTIONS
-- ============================================================

-- Vector Search: semantic similarity over KB embeddings
CREATE OR REPLACE FUNCTION match_kb_articles (
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  id uuid,
  title text,
  content text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    kb_articles.id,
    kb_articles.title,
    kb_articles.content,
    1 - (kb_embeddings.embedding <=> query_embedding) AS similarity
  FROM kb_embeddings
  JOIN kb_articles ON kb_articles.id = kb_embeddings.article_id
  WHERE 1 - (kb_embeddings.embedding <=> query_embedding) > match_threshold
  ORDER BY similarity DESC
  LIMIT match_count;
END;
$$;

-- Hybrid Search: combines semantic similarity + keyword boost
CREATE OR REPLACE FUNCTION hybrid_search_kb (
  query_text text,
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
RETURNS TABLE (
  id uuid,
  title text,
  content text,
  category text,
  similarity float
)
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT
    kb_articles.id,
    kb_articles.title,
    kb_articles.content,
    kb_articles.category,
    (
      1 - (kb_embeddings.embedding <=> query_embedding) +
      CASE
        WHEN kb_articles.title   ILIKE '%' || query_text || '%' THEN 1.0
        WHEN kb_articles.content ILIKE '%' || query_text || '%' THEN 0.5
        ELSE 0.0
      END
    ) AS similarity
  FROM kb_embeddings
  JOIN kb_articles ON kb_articles.id = kb_embeddings.article_id
  WHERE (1 - (kb_embeddings.embedding <=> query_embedding) > match_threshold)
     OR (kb_articles.title   ILIKE '%' || query_text || '%')
     OR (kb_articles.content ILIKE '%' || query_text || '%')
  ORDER BY similarity DESC
  LIMIT match_count;
END;
$$;

-- Attendance RPC: department-level stats (filtered by date range, used by Admin leaderboard & AI audit)
CREATE OR REPLACE FUNCTION get_admin_department_stats(start_date text, end_date text)
RETURNS TABLE(department text, present_count bigint, total_count bigint)
LANGUAGE sql
AS $$
  SELECT
    t.department,
    COUNT(CASE WHEN ar.status = 'present' THEN 1 END) AS present_count,
    COUNT(*) AS total_count
  FROM attendance_records ar
  JOIN attendance_sessions asess ON ar.session_id = asess.id
  JOIN timetables t ON asess.timetable_id = t.id
  WHERE asess.date >= start_date::date AND asess.date <= end_date::date
  GROUP BY t.department;
$$;

-- Attendance RPC: daily stats (filtered by date range, used by Admin graph)
CREATE OR REPLACE FUNCTION get_admin_daily_stats(start_date text, end_date text)
RETURNS TABLE(session_date date, present_count bigint, total_count bigint)
LANGUAGE sql
AS $$
  SELECT
    asess.date AS session_date,
    COUNT(CASE WHEN ar.status = 'present' THEN 1 END) AS present_count,
    COUNT(*) AS total_count
  FROM attendance_records ar
  JOIN attendance_sessions asess ON ar.session_id = asess.id
  WHERE asess.date >= start_date::date AND asess.date <= end_date::date
  GROUP BY asess.date
  ORDER BY asess.date ASC;
$$;

-- Attendance RPC: per-student stats (avoids 1000-row API limit for manage tab)
CREATE OR REPLACE FUNCTION get_student_attendance_stats(p_student_ids uuid[], p_end_date text)
RETURNS TABLE(student_id uuid, present_count bigint, total_count bigint)
LANGUAGE sql
AS $$
  SELECT
    ar.student_id,
    COUNT(CASE WHEN ar.status = 'present' THEN 1 END) AS present_count,
    COUNT(*) AS total_count
  FROM attendance_records ar
  JOIN attendance_sessions asess ON ar.session_id = asess.id
  WHERE ar.student_id = ANY(p_student_ids)
    AND asess.date <= p_end_date::date
  GROUP BY ar.student_id;
$$;
