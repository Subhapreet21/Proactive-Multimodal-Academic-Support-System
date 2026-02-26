-- Run this script in your Supabase SQL Editor to populate artificial attendance data for Mar–Aug 2026 (excluding Sundays)

DO $$
DECLARE
    cur_date date;
    end_date date := '2026-12-31';
    tt RECORD;
    student RECORD;
    sess_id uuid;
    random_status text;
    day_name text;
    faculty_id uuid;
BEGIN
    -- Get a faculty ID to assign as the 'marked_by' user
    SELECT id INTO faculty_id FROM profiles WHERE role = 'faculty' LIMIT 1;
    
    -- Start from March 1st, 2026
    cur_date := '2026-03-01';

    WHILE cur_date <= end_date LOOP
        -- Skip Sundays (DOW = 0 in PostgreSQL)
        IF EXTRACT(DOW FROM cur_date) = 0 THEN
            cur_date := cur_date + INTERVAL '1 day';
            CONTINUE;
        END IF;

        -- Get the full English name of the day, e.g., 'Monday', 'Tuesday'
        day_name := trim(to_char(cur_date, 'Day'));
        
        -- Loop through all timetables scheduled for this day of the week
        FOR tt IN SELECT * FROM timetables WHERE day_of_week ILIKE '%' || day_name || '%' LOOP
            
            -- Ensure no missing department/year/section before proceeding (to avoid massive global joins)
            IF tt.department IS NOT NULL AND tt.year IS NOT NULL AND tt.section IS NOT NULL THEN
                
                -- Create the session if it doesn't already exist for this class on this date
                INSERT INTO attendance_sessions (timetable_id, marked_by, date) 
                VALUES (tt.id, faculty_id, cur_date)
                ON CONFLICT (timetable_id, date) DO NOTHING;
                
                -- Retrieve the session ID (whether newly inserted or existing)
                SELECT id INTO sess_id FROM attendance_sessions 
                WHERE timetable_id = tt.id AND date = cur_date LIMIT 1;
                
                IF sess_id IS NOT NULL THEN
                    -- Loop through all students matching the class's department, year, and section
                    FOR student IN SELECT * FROM profiles 
                                   WHERE role = 'student' 
                                     AND department = tt.department 
                                     AND year = tt.year 
                                     AND section = tt.section 
                    LOOP
                        -- Procedurally generate random status (approx 80% present, 10% absent, 10% late)
                        IF random() < 0.8 THEN
                            random_status := 'present';
                        ELSIF random() < 0.9 THEN
                            random_status := 'absent';
                        ELSE
                            random_status := 'late';
                        END IF;

                        -- Insert the record for the student
                        INSERT INTO attendance_records (session_id, student_id, status)
                        VALUES (sess_id, student.id, random_status)
                        ON CONFLICT (session_id, student_id) DO NOTHING;
                    END LOOP;
                END IF;
                
            END IF;
            
        END LOOP;
        
        -- Increment date
        cur_date := cur_date + INTERVAL '1 day';
    END LOOP;
END;
$$;
