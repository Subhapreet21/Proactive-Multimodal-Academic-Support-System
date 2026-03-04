-- Run this script in your Supabase SQL Editor to populate artificial attendance data for Jan-Dec 2026

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
    base_prob numeric;
    jitter numeric;
BEGIN
    -- First, clear out existing attendance data to prevent constraint violations and start fresh
    -- Because this is inside the BEGIN...END block, if the script fails later, 
    -- these deletions will AUTOMATICALLY ROLL BACK, restoring your old data.
    DELETE FROM attendance_records;
    DELETE FROM attendance_sessions;

    -- Start from January 1st, 2026
    cur_date := '2026-01-01';

    WHILE cur_date <= end_date LOOP
        -- Skip Sundays (DOW = 0 in PostgreSQL)
        IF EXTRACT(DOW FROM cur_date) = 0 THEN
            cur_date := cur_date + INTERVAL '1 day';
            CONTINUE;
        END IF;

        -- Realistic Holiday Generator: ~5% chance any given day (excluding Sundays) is a public/college holiday
        IF random() < 0.05 THEN
            cur_date := cur_date + INTERVAL '1 day';
            CONTINUE;
        END IF;

        -- Get the full English name of the day, e.g., 'Monday', 'Tuesday'
        day_name := trim(to_char(cur_date, 'Day'));
        
        -- Loop through all timetables scheduled for this day of the week
        FOR tt IN SELECT * FROM timetables WHERE day_of_week ILIKE '%' || day_name || '%' LOOP
            
            -- Ensure no missing department/year/section before proceeding
            IF tt.department IS NOT NULL AND tt.year IS NOT NULL AND tt.section IS NOT NULL THEN
                
                -- Determine a base probability based on the department to add realistic variance
                IF tt.department = 'CSE' THEN base_prob := 0.85;
                ELSIF tt.department = 'ECE' THEN base_prob := 0.78;
                ELSIF tt.department = 'EEE' THEN base_prob := 0.81;
                ELSIF tt.department = 'ME' THEN base_prob := 0.72;
                ELSIF tt.department = 'CE' THEN base_prob := 0.75;
                ELSIF tt.department = 'IT' THEN base_prob := 0.83;
                ELSE base_prob := 0.80;
                END IF;

                -- Select a RANDOM faculty member from the SAME department as the class
                SELECT id INTO faculty_id 
                FROM profiles 
                WHERE role = 'faculty' AND department = tt.department 
                ORDER BY random() 
                LIMIT 1;

                -- Only proceed if a faculty member exists for this department
                IF faculty_id IS NOT NULL THEN
                    
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
                            -- Add a tiny bit of random jitter (-0.05 to +0.05) to the base department probability
                            jitter := (random() * 0.1) - 0.05;
                            
                            IF random() < (base_prob + jitter) THEN
                                random_status := 'present';
                            ELSIF random() < (base_prob + jitter + 0.10) THEN
                                -- Usually 10% chance of being explicitly absent if not present
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
                    
                END IF; -- End check for faculty_id
            END IF;
            
        END LOOP;
        
        -- Increment date
        cur_date := cur_date + INTERVAL '1 day';
    END LOOP;
END;
$$;

-- Finally, since we completely altered historical data, force the AI to rethink the audit
DELETE FROM ai_insights WHERE type = 'dept_audit';

