-- RPC: Group attendance by department
CREATE OR REPLACE FUNCTION get_admin_department_stats(start_date text)
RETURNS TABLE(department text, present_count bigint, total_count bigint)
LANGUAGE sql
AS $$
  SELECT 
    t.department,
    COUNT(CASE WHEN ar.status = 'present' THEN 1 END) as present_count,
    COUNT(*) as total_count
  FROM attendance_records ar
  JOIN attendance_sessions asess ON ar.session_id = asess.id
  JOIN timetables t ON asess.timetable_id = t.id
  WHERE asess.date >= start_date::date
  GROUP BY t.department;
$$;

-- RPC: Group attendance by day
CREATE OR REPLACE FUNCTION get_admin_daily_stats(start_date text)
RETURNS TABLE(session_date date, present_count bigint, total_count bigint)
LANGUAGE sql
AS $$
  SELECT 
    asess.date as session_date,
    COUNT(CASE WHEN ar.status = 'present' THEN 1 END) as present_count,
    COUNT(*) as total_count
  FROM attendance_records ar
  JOIN attendance_sessions asess ON ar.session_id = asess.id
  WHERE asess.date >= start_date::date
  GROUP BY asess.date
  ORDER BY asess.date ASC;
$$;
