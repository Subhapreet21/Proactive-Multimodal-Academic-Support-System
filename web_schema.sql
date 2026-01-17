-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.conversations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  title text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT conversations_pkey PRIMARY KEY (id)
);
CREATE TABLE public.events_notices (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text,
  description text,
  event_date timestamp with time zone,
  category text,
  source_image_url text,
  created_by text,
  created_at timestamp with time zone DEFAULT now(),
  location text,
  CONSTRAINT events_notices_pkey PRIMARY KEY (id)
);
CREATE TABLE public.kb_articles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  content text,
  category text,
  feedback_up integer DEFAULT 0,
  feedback_down integer DEFAULT 0,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT kb_articles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.kb_embeddings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  article_id uuid,
  chunk_index integer,
  chunk_content text,
  embedding USER-DEFINED,
  metadata jsonb DEFAULT '{}'::jsonb,
  CONSTRAINT kb_embeddings_pkey PRIMARY KEY (id),
  CONSTRAINT kb_embeddings_article_id_fkey FOREIGN KEY (article_id) REFERENCES public.kb_articles(id)
);
CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL,
  sender_type text NOT NULL,
  content text,
  role text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id)
);
CREATE TABLE public.profiles (
  id text NOT NULL,
  email text,
  full_name text,
  department text,
  year text,
  section text,
  preferences jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  role text DEFAULT 'student'::text CHECK (role = ANY (ARRAY['student'::text, 'faculty'::text, 'admin'::text])),
  avatar_url text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.reminders (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  title text NOT NULL,
  description text,
  due_at timestamp with time zone NOT NULL,
  category text,
  email_notification boolean DEFAULT false,
  is_completed boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT reminders_pkey PRIMARY KEY (id)
);
CREATE TABLE public.timetables (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id text NOT NULL,
  day_of_week text NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  course_code text,
  course_name text,
  location text,
  created_at timestamp with time zone DEFAULT now(),
  department text,
  year text,
  section text,
  CONSTRAINT timetables_pkey PRIMARY KEY (id)
);