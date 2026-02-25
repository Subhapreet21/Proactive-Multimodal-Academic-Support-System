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