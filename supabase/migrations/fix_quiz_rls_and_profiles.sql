-- 1. Explicitly drop all possible legacy policy names on quizzes
-- This ensures no "SELECT true" policies remain from early development.
DROP POLICY IF EXISTS "Quizzes are viewable by everyone" ON public.quizzes;
DROP POLICY IF EXISTS "Active quizzes are viewable by students" ON public.quizzes;
DROP POLICY IF EXISTS "Quiz Visibility for Students" ON public.quizzes;

-- 2. Create the consolidated visibility policy for students
--    Ensures that for student users, the quiz MUST match their year and department if those targeting fields are set.
CREATE POLICY "Quiz Visibility for Students" ON public.quizzes
  FOR SELECT USING (
    -- Condition A: Student visibility rules
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
    -- Condition B: Faculty and Admins can see everything (to manage)
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND (profiles.role = 'faculty' OR profiles.role = 'admin')
    )
  );

-- 3. Allow users to read their own basic profile (Required for RLS subqueries to function)
--    If RLS is enabled on profiles but no SELECT policy exists, the subqueries above will return NULL,
--    failing the year/department match for students.
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT USING (id = auth.uid());
