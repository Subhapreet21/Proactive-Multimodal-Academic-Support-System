import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { WithAuthProp } from '@clerk/clerk-sdk-node'; // Using this as type, though auth might be supabase. Let's stick to existing project patterns.

// GET /api/attendance/class?timetable_id=UUID&date=YYYY-MM-DD
export const getClassAttendance = async (req: Request, res: Response): Promise<void> => {
    try {
        const { timetable_id, date } = req.query;

        if (!timetable_id || !date) {
            res.status(400).json({ error: 'timetable_id and date are required.' });
            return;
        }

        // 1. Find if a session already exists
        const { data: session, error: sessionError } = await supabase
            .from('attendance_sessions')
            .select('id, marked_by, profiles!attendance_sessions_marked_by_fkey(full_name)')
            .eq('timetable_id', timetable_id)
            .eq('date', date)
            .single();

        if (sessionError && sessionError.code !== 'PGRST116') { // PGRST116 is 'not found'
            throw sessionError;
        }

        if (session) {
            // Already marked, fetch the records
            const { data: records, error: recordsError } = await supabase
                .from('attendance_records')
                .select(`
                    student_id,
                    status,
                    profiles!attendance_records_student_id_fkey(full_name, avatar_url)
                `)
                .eq('session_id', session.id);

            if (recordsError) throw recordsError;

            res.json({
                isMarked: true,
                markedBy: (session.profiles as any)?.full_name || (Array.isArray(session.profiles) ? (session.profiles[0] as any)?.full_name : 'Unknown'),
                markedById: session.marked_by,
                records: records.map((r: any) => ({
                    student_id: r.student_id,
                    name: r.profiles?.full_name,
                    avatar_url: r.profiles?.avatar_url,
                    status: r.status
                }))
            });
            return;
        }

        // 2. Not marked yet. We need to fetch the students for this batch so faculty can mark them.
        // First get the timetable details to know the batch.
        const { data: timetable, error: ttError } = await supabase
            .from('timetables')
            .select('department, year, section')
            .eq('id', timetable_id)
            .single();

        if (ttError) throw ttError;
        if (!timetable) {
            res.status(404).json({ error: 'Timetable entry not found.' });
            return;
        }

        // Fetch students in this batch
        const { data: students, error: studentsError } = await supabase
            .from('profiles')
            .select('id, full_name, avatar_url')
            .eq('role', 'student')
            .eq('department', timetable.department)
            .eq('year', timetable.year)
            .eq('section', timetable.section)
            .order('full_name');

        if (studentsError) throw studentsError;

        res.json({
            isMarked: false,
            records: students.map((s: any) => ({
                student_id: s.id,
                name: s.full_name,
                avatar_url: s.avatar_url,
                status: 'present' // Default status
            }))
        });

    } catch (error: any) {
        console.error('[getClassAttendance] Error:', error.message);
        res.status(500).json({ error: error.message });
    }
};

// POST /api/attendance/mark
// Body: { timetable_id: UUID, date: YYYY-MM-DD, records: [{student_id, status}] }
export const markAttendance = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { timetable_id, date, records } = req.body;

        if (!timetable_id || !date || !records || !Array.isArray(records)) {
            res.status(400).json({ error: 'Invalid payload.' });
            return;
        }

        // Verify if user is faculty or admin
        const { data: profile } = await supabase.from('profiles').select('role, department').eq('id', userId).single();
        if (!profile || profile.role === 'student') {
            res.status(403).json({ error: 'Unauthorized.' });
            return;
        }

        // Faculty department check
        if (profile.role === 'faculty') {
            const { data: tt } = await supabase.from('timetables').select('department').eq('id', timetable_id).single();
            if (tt && tt.department !== profile.department) {
                res.status(403).json({ error: 'Can only mark attendance for your department.' });
                return;
            }
        }

        // 1. Transaction to Upsert Session and Records
        // Check if session exists
        let sessionId;
        const { data: existingSession } = await supabase
            .from('attendance_sessions')
            .select('id')
            .eq('timetable_id', timetable_id)
            .eq('date', date)
            .single();

        if (existingSession) {
            sessionId = existingSession.id;
            // Optionally update marked_by if overriding
            await supabase.from('attendance_sessions').update({ marked_by: userId }).eq('id', sessionId);
        } else {
            // Create new session
            const { data: newSession, error: insertError } = await supabase
                .from('attendance_sessions')
                .insert({
                    timetable_id,
                    date,
                    marked_by: userId
                })
                .select()
                .single();

            if (insertError) throw insertError;
            sessionId = newSession.id;
        }

        // 2. Upsert Records
        // Delete existing records for this session to handle updates efficiently, then re-insert
        await supabase.from('attendance_records').delete().eq('session_id', sessionId);

        const recordsToInsert = records.map(r => ({
            session_id: sessionId,
            student_id: r.student_id,
            status: r.status
        }));

        const { error: recordsInsertError } = await supabase
            .from('attendance_records')
            .insert(recordsToInsert);

        if (recordsInsertError) throw recordsInsertError;

        res.json({ message: 'Attendance marked successfully', sessionId });
    } catch (error: any) {
        console.error('[markAttendance] Error:', error.message);
        res.status(500).json({ error: 'Failed to mark attendance. It might already exist.' });
    }
};

// GET /api/attendance/student?student_id=UUID
export const getStudentAttendance = async (req: Request, res: Response): Promise<void> => {
    try {
        const requestingUserId = (req as WithAuthProp<Request>).auth.userId;
        let targetStudentId = req.query.student_id as string;

        // If no explicit target, fetch for the requesting user
        if (!targetStudentId) {
            const { data: profile } = await supabase.from('profiles').select('role').eq('id', requestingUserId).single();
            if (profile?.role !== 'student') {
                res.status(400).json({ error: 'student_id is required.' });
                return;
            }
            targetStudentId = requestingUserId as string;
        }

        // Query all records for the student joined with session and timetable to calculate percentages per subject
        const { data: records, error } = await supabase
            .from('attendance_records')
            .select(`
                status,
                attendance_sessions!inner(date, timetables(course_name, course_code))
            `)
            .eq('student_id', targetStudentId);

        if (error) throw error;

        // Filter out future dates (useful since seed script may add records into the future)
        const todayStr = new Date().toISOString().split('T')[0];
        const validRecords = records.filter((r: any) => {
            const sessionDate = r.attendance_sessions?.date;
            return sessionDate && sessionDate <= todayStr;
        });

        // Calculate stats
        let totalClasses = 0;
        let totalPresent = 0;
        const subjectStats: Record<string, { present: number, total: number }> = {};

        validRecords.forEach((r: any) => {
            const courseName = r.attendance_sessions?.timetables?.course_name || 'Unknown';
            if (!subjectStats[courseName]) {
                subjectStats[courseName] = { present: 0, total: 0 };
            }

            subjectStats[courseName].total++;
            totalClasses++;

            if (r.status === 'present') {
                subjectStats[courseName].present++;
                totalPresent++;
            }
        });

        const overallPercentage = totalClasses === 0 ? 100 : Math.round((totalPresent / totalClasses) * 100);

        const subjectBreakdown = Object.keys(subjectStats).map(course => ({
            course,
            present: subjectStats[course].present,
            total: subjectStats[course].total,
            percentage: Math.round((subjectStats[course].present / subjectStats[course].total) * 100)
        }));

        // Sort for recent history
        validRecords.sort((a: any, b: any) => {
            const dateA = new Date(a.attendance_sessions?.date || 0).getTime();
            const dateB = new Date(b.attendance_sessions?.date || 0).getTime();
            return dateB - dateA;
        });

        // Increase size from 5 to 20 so the frontend can easily filter out today's classes
        const recentHistory = validRecords.slice(0, 20).map((r: any) => ({
            date: r.attendance_sessions?.date,
            course: r.attendance_sessions?.timetables?.course_name || 'Unknown',
            status: r.status
        }));

        res.json({
            overallPercentage,
            totalClasses,
            totalPresent,
            subjectBreakdown,
            recentHistory
        });

    } catch (error: any) {
        console.error('[getStudentAttendance] Error:', error.message);
        res.status(500).json({ error: error.message });
    }
};

// GET /api/attendance/admin/stats
export const getAdminStats = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;

        // Verify Admin
        const { data: profile } = await supabase.from('profiles').select('role').eq('id', userId).single();
        if (profile?.role !== 'admin') {
            res.status(403).json({ error: 'Admin access required.' });
            return;
        }

        // Just fetching high level overview for the dashboard
        // We'll calculate the total present / relative to total records over the last 30 days
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

        const { data: records, error } = await supabase
            .from('attendance_records')
            .select('status, attendance_sessions!inner(date, timetables(department))')
            .gte('attendance_sessions.date', thirtyDaysAgo.toISOString().split('T')[0]);

        if (error) throw error;

        let totalRecords = 0;
        let totalPresent = 0;
        const deptStats: Record<string, { present: number, total: number }> = {};

        records.forEach((r: any) => {
            const dept = r.attendance_sessions?.timetables?.department || 'Unknown';
            if (!deptStats[dept]) {
                deptStats[dept] = { present: 0, total: 0 };
            }

            deptStats[dept].total++;
            totalRecords++;

            if (r.status === 'present') {
                deptStats[dept].present++;
                totalPresent++;
            }
        });

        const overallPercentage = totalRecords === 0 ? 0 : Math.round((totalPresent / totalRecords) * 100);

        const departmentBreakdown = Object.keys(deptStats).map(dept => ({
            department: dept,
            percentage: Math.round((deptStats[dept].present / deptStats[dept].total) * 100)
        }));

        res.json({
            overallPercentage,
            departmentBreakdown
        });

    } catch (error: any) {
        console.error('[getAdminStats] Error:', error.message);
        res.status(500).json({ error: error.message });
    }
};

// GET /api/attendance/filtered-students
// Fetches students matching department/year/section filters and calculates overall attendance %
export const getFilteredStudentAttendance = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { department, year, section } = req.query;

        // Verify if user is faculty or admin
        const { data: profile } = await supabase.from('profiles').select('role, department').eq('id', userId).single();
        if (!profile || profile.role === 'student') {
            res.status(403).json({ error: 'Unauthorized.' });
            return;
        }

        // Faculty department check
        let queryDept = department;
        if (profile.role === 'faculty') {
            queryDept = profile.department; // enforce faculty's department
        }

        // 1. Fetch all students matching filters
        let usersQuery = supabase.from('profiles').select('id, full_name, email').eq('role', 'student');

        if (queryDept && queryDept !== 'All') {
            usersQuery = usersQuery.eq('department', queryDept);
        }
        if (year && year !== 'All') {
            usersQuery = usersQuery.eq('year', year);
        }
        if (section && section !== 'All') {
            usersQuery = usersQuery.eq('section', section);
        }

        const { data: students, error: studentError } = await usersQuery;
        if (studentError) throw studentError;

        if (!students || students.length === 0) {
            res.json([]);
            return;
        }

        const studentIds = students.map((s: any) => s.id);

        // 2. Fetch attendance records for these students
        const { data: records, error: recordsError } = await supabase
            .from('attendance_records')
            .select(`
                student_id,
                status,
                attendance_sessions!inner(date)
            `)
            .in('student_id', studentIds);

        if (recordsError) throw recordsError;

        // 3. Filter valid dates and calculate stats
        const todayStr = new Date().toISOString().split('T')[0];
        const validRecords = (records || []).filter((r: any) => {
            const sessionDate = r.attendance_sessions?.date;
            return sessionDate && sessionDate <= todayStr;
        });

        const statsMap: Record<string, { total: number, present: number }> = {};
        studentIds.forEach((id: string) => statsMap[id] = { total: 0, present: 0 });

        validRecords.forEach((r: any) => {
            if (statsMap[r.student_id]) {
                statsMap[r.student_id].total++;
                if (r.status === 'present') {
                    statsMap[r.student_id].present++;
                }
            }
        });

        // 4. Map back to student objects and sort by roll number
        const results = students.map((s: any) => {
            const stats = statsMap[s.id];
            const percentage = stats.total === 0 ? 100 : Math.round((stats.present / stats.total) * 100);
            return {
                ...s,
                total_classes: stats.total,
                attended_classes: stats.present,
                overall_percentage: percentage
            };
        }).sort((a: any, b: any) => (a.full_name || '').localeCompare(b.full_name || ''));

        res.json(results);

    } catch (error: any) {
        console.error('[getFilteredStudentAttendance] Error:', error.message);
        res.status(500).json({ error: error.message });
    }
};
