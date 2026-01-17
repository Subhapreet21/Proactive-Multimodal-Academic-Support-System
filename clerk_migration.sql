-- 1. DROP ALL RLS POLICIES causing the conflict
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can CRUD own timetable" ON timetables;
DROP POLICY IF EXISTS "Users can CRUD own reminders" ON reminders;
DROP POLICY IF EXISTS "Users can own conversations" ON conversations;
DROP POLICY IF EXISTS "Users can own messages" ON messages;

-- 2. Drop Foreign Key Constraints
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE timetables DROP CONSTRAINT IF EXISTS timetables_user_id_fkey;
ALTER TABLE reminders DROP CONSTRAINT IF EXISTS reminders_user_id_fkey;
ALTER TABLE events_notices DROP CONSTRAINT IF EXISTS events_notices_created_by_fkey;
ALTER TABLE conversations DROP CONSTRAINT IF EXISTS conversations_user_id_fkey;

-- 3. Change ID columns from UUID to TEXT
ALTER TABLE profiles ALTER COLUMN id TYPE text;
ALTER TABLE timetables ALTER COLUMN user_id TYPE text;
ALTER TABLE reminders ALTER COLUMN user_id TYPE text;
ALTER TABLE events_notices ALTER COLUMN created_by TYPE text;
ALTER TABLE conversations ALTER COLUMN user_id TYPE text;

-- 4. Cleanup Triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
