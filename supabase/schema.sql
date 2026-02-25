-- Enable pgvector extension
create extension if not exists vector;

-- Profiles table (Supabase Auth Integration: id is uuid)
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

-- Timetable Metadata
CREATE TABLE public.timetable_metadata (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  key text NOT NULL UNIQUE,
  value jsonb NOT NULL,
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT timetable_metadata_pkey PRIMARY KEY (id)
);

-- Reminders
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

-- Conversations (Chat history)
CREATE TABLE public.conversations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  title text,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT conversations_pkey PRIMARY KEY (id),
  CONSTRAINT conversations_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);

-- Messages
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

-- Events & Notices
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

-- Knowledge Base Articles
CREATE TABLE public.kb_articles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text UNIQUE,
  content text,
  category text,
  author_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT kb_articles_pkey PRIMARY KEY (id),
  CONSTRAINT kb_articles_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id)
);

-- KB Embeddings (for RAG)
CREATE TABLE public.kb_embeddings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  article_id uuid,
  chunk_content text,
  embedding vector(768), -- Adjusted to vector(768) as per existing implementation
  metadata jsonb DEFAULT '{}'::jsonb,
  chunk_index integer,
  CONSTRAINT kb_embeddings_pkey PRIMARY KEY (id),
  CONSTRAINT kb_embeddings_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.kb_articles(id)
);

-- Invitation Codes
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

-- Vector Search Function
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

-- RLS Policies
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events_notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kb_articles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.kb_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invitation_codes ENABLE ROW LEVEL SECURITY;

-- 1. Create the Attendance Session (The 'Event' of marking class)
CREATE TABLE public.attendance_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  timetable_id uuid REFERENCES public.timetables(id) ON DELETE CASCADE,
  marked_by uuid REFERENCES public.profiles(id),
  date date NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT attendance_sessions_pkey PRIMARY KEY (id),
  -- Conflict Prevention: One record per class slot per day
  CONSTRAINT unique_attendance_per_day UNIQUE (timetable_id, date)
);

-- 2. Create individual Student Attendance Records
CREATE TABLE public.attendance_records (
  session_id uuid REFERENCES public.attendance_sessions(id) ON DELETE CASCADE,
  student_id uuid REFERENCES public.profiles(id),
  status text CHECK (status IN ('present', 'absent', 'late')),
  CONSTRAINT attendance_records_pkey PRIMARY KEY (session_id, student_id)
);

-- 3. Enable Security
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;

-- Note: You should add policies that allow Students to SELECT their own records 
-- and Faculty/Admins to manage records for their department.

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
