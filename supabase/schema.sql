-- Enable pgvector extension
create extension if not exists vector;

-- Profiles table (Clerk Integration: id is text)
create table profiles (
  id text not null primary key,
  email text,
  full_name text,
  department text,
  year text,
  section text,
  role text default 'student' check (role in ('student', 'faculty', 'admin')),
  avatar_url text,
  preferences jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- Timetables (Structured data)
create table timetables (
  id uuid default gen_random_uuid() primary key,
  user_id text not null,
  day_of_week text not null, -- 'Monday', 'Tuesday', etc.
  start_time time without time zone not null,
  end_time time without time zone not null,
  course_code text,
  course_name text,
  location text,
  department text, -- 'CSE', 'ECE', etc.
  year text,       -- '1', '2', '3', '4'
  section text,    -- 'A', 'B', 'C'
  created_at timestamptz default now()
);

UPDATE timetables
SET user_id = 'user_373RsZUgBhGc4REOVjt5AqVypH9'
WHERE user_id = 'c26b11d3-c158-409c-979d-ddc11cd7d51f';

-- Reminders
create table reminders (
  id uuid default gen_random_uuid() primary key,
  user_id text not null,
  title text not null,
  description text,
  due_at timestamptz not null,
  category text, -- 'class', 'exam', 'fee', 'event', 'other'
  email_notification boolean default false,
  is_completed boolean default false,
  created_at timestamptz default now()
);

-- Knowledge Base Articles
create table kb_articles (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  slug text unique not null,
  content text,
  category text,
  feedback_up int default 0,
  feedback_down int default 0,
  updated_at timestamptz default now()
);

-- KB Embeddings (for RAG)
create table kb_embeddings (
  id uuid default gen_random_uuid() primary key,
  article_id uuid references kb_articles on delete cascade,
  chunk_index int,
  chunk_content text,
  embedding vector(768), -- Gemini embedding dimension is usually 768
  metadata jsonb default '{}'::jsonb
);

-- Events & Notices (from Vision)
create table events_notices (
  id uuid default gen_random_uuid() primary key,
  title text,
  description text,
  event_date timestamptz,
  category text,
  location text,
  source_image_url text,
  created_by text, -- Clerk ID
  created_at timestamptz default now()
);

-- Conversations (Chat history)
create table conversations (
  id uuid default gen_random_uuid() primary key,
  user_id text not null,
  title text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Messages
create table messages (
  id uuid default gen_random_uuid() primary key,
  conversation_id uuid references conversations on delete cascade not null,
  sender_type text not null, -- 'user' or 'assistant'
  content text,
  role text, -- 'user', 'model' (for Gemini mapping)
  created_at timestamptz default now()
);

-- RLS Policies (Note: These rely on custom auth logic or Supabase Config)
alter table profiles enable row level security;
create policy "Users can view own profile" on profiles for select using (true); 
-- Simplified policy as auth.uid() is uuid. For Clerk, we might need a different check or trusted service role.

alter table timetables enable row level security;
alter table reminders enable row level security;
alter table events_notices enable row level security;
alter table conversations enable row level security;
alter table messages enable row level security;

-- Vector Search Function
create or replace function match_kb_articles (
  query_embedding vector(768),
  match_threshold float,
  match_count int
)
returns table (
  id uuid,
  title text,
  content text,
  similarity float
)
language plpgsql
as $$
begin
  return query
  select
    kb_articles.id,
    kb_articles.title,
    kb_articles.content,
    1 - (kb_embeddings.embedding <=> query_embedding) as similarity
  from kb_embeddings
  join kb_articles on kb_articles.id = kb_embeddings.article_id
  where 1 - (kb_embeddings.embedding <=> query_embedding) > match_threshold
  order by similarity desc
  limit match_count;
end;
$$;