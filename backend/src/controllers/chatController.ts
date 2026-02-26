import { Request, Response } from 'express';
import { generateText, generateFromImage } from '../services/aiService';
import { supabase } from '../services/supabaseClient';

import { getEmbedding } from '../services/aiService';

import { WithAuthProp } from '@clerk/clerk-sdk-node';

export const handleTextChat = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        let { message, conversationId, history } = req.body;

        conversationId = conversationId || 'ephemeral-session';

        // A. Get Profile first to know role/Dept/Year/Section
        const { data: profile } = await supabase
            .from('profiles')
            .select('role, department, year, section, full_name')
            .eq('id', userId)
            .single();

        // Helper: current day
        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const todayIndex = new Date().getDay();
        const currentDay = days[todayIndex];

        // --- Smart Day Detection ---
        let targetDay = currentDay;
        const lowerMsg = message.toLowerCase();
        let isWeekendLookahead = false;

        if (lowerMsg.includes('tomorrow')) {
            targetDay = days[(todayIndex + 1) % 7];
        } else if (lowerMsg.includes('yesterday')) {
            targetDay = days[(todayIndex - 1 + 7) % 7];
        } else {
            let explicitDayFound = false;
            for (const day of days) {
                if (lowerMsg.includes(day.toLowerCase())) {
                    targetDay = day;
                    explicitDayFound = true;
                    break;
                }
            }
            if (!explicitDayFound && todayIndex === 0) {
                targetDay = 'Monday';
                isWeekendLookahead = true;
                console.log('[Chat] Sunday detected. Auto-switching target to Monday.');
            }
        }

        console.log(`[Chat] Smart Day Detection: User asked about '${message}' -> Target Day: ${targetDay}`);

        // --- Build timetable query based on role ---
        let timetableQuery = supabase.from('timetables').select('*');
        if (profile) {
            if (profile.role === 'student') {
                if (profile.department && profile.year && profile.section) {
                    timetableQuery = timetableQuery
                        .eq('department', profile.department)
                        .eq('year', profile.year)
                        .eq('section', profile.section)
                        .eq('day_of_week', targetDay);
                } else {
                    timetableQuery = timetableQuery.eq('id', '00000000-0000-0000-0000-000000000000');
                }
            } else if (profile.role === 'faculty') {
                if (profile.department) {
                    timetableQuery = timetableQuery
                        .eq('department', profile.department)
                        .eq('day_of_week', targetDay)
                        .limit(50);
                } else {
                    timetableQuery = timetableQuery.eq('id', '00000000-0000-0000-0000-000000000000');
                }
            } else {
                timetableQuery = timetableQuery.eq('day_of_week', targetDay).limit(50);
            }
        } else {
            timetableQuery = timetableQuery.eq('id', '00000000-0000-0000-0000-000000000000');
        }

        const todayStr = new Date().toISOString().split('T')[0];
        const role = profile?.role || 'student';

        // ---------------------------------------------------------------
        // B. Build role-aware attendance + quiz queries (all in parallel)
        // ---------------------------------------------------------------

        // --- ATTENDANCE QUERIES ---
        const studentAttendancePromise = role === 'student'
            ? supabase
                .from('attendance_records')
                .select('status, attendance_sessions!inner(date, timetables(course_name, course_code))')
                .eq('student_id', userId)
                .lte('attendance_sessions.date', todayStr)
            : Promise.resolve({ data: null });

        const facultyAttendancePromise = role === 'faculty' && profile?.department
            ? supabase
                .from('attendance_records')
                .select('student_id, status, attendance_sessions!inner(date, timetables(department, course_name))')
                .eq('attendance_sessions.timetables.department', profile.department)
                .gte('attendance_sessions.date', (() => { const d = new Date(); d.setDate(d.getDate() - 30); return d.toISOString().split('T')[0]; })())
                .lte('attendance_sessions.date', todayStr)
                .limit(300)
            : Promise.resolve({ data: null });

        const adminAttendancePromise = role === 'admin'
            ? supabase
                .from('attendance_records')
                .select('status, attendance_sessions!inner(date, timetables(department))')
                .gte('attendance_sessions.date', (() => { const d = new Date(); d.setDate(d.getDate() - 30); return d.toISOString().split('T')[0]; })())
                .lte('attendance_sessions.date', todayStr)
                .limit(500)
            : Promise.resolve({ data: null });

        // --- QUIZ QUERIES ---
        const studentQuizPromise = role === 'student'
            ? supabase
                .from('quiz_attempts')
                .select('score, total_questions, submitted_at, quizzes(title, max_attempts, time_limit_mins)')
                .eq('student_id', userId)
                .order('submitted_at', { ascending: false })
                .limit(10)
            : Promise.resolve({ data: null });

        const facultyQuizPromise = role === 'faculty'
            ? supabase
                .from('quizzes')
                .select(`
                    id, title, is_active, max_attempts, time_limit_mins, target_year,
                    valid_from, valid_until,
                    quiz_attempts(score, total_questions)
                `)
                .eq('created_by', userId)
                .order('created_at', { ascending: false })
                .limit(10)
            : Promise.resolve({ data: null });

        const adminQuizPromise = role === 'admin'
            ? supabase
                .from('quizzes')
                .select('id, title, is_active, target_year, quiz_attempts(score, total_questions)')
                .order('created_at', { ascending: false })
                .limit(15)
            : Promise.resolve({ data: null });

        // ---------------------------------------------------------------
        // C. Fire all queries in parallel
        // ---------------------------------------------------------------
        const [
            timetableRes, remindersRes, eventsRes,
            studentAttRes, facultyAttRes, adminAttRes,
            studentQuizRes, facultyQuizRes, adminQuizRes
        ] = await Promise.all([
            timetableQuery,
            supabase.from('reminders').select('*').eq('user_id', userId).eq('is_completed', false),
            supabase.from('events_notices').select('*').order('created_at', { ascending: false }).limit(5),
            studentAttendancePromise,
            facultyAttendancePromise,
            adminAttendancePromise,
            studentQuizPromise,
            facultyQuizPromise,
            adminQuizPromise,
        ]);

        const timetables = timetableRes.data || [];
        const reminders = remindersRes.data || [];
        const events = eventsRes.data || [];

        // ---------------------------------------------------------------
        // D. Process attendance & quiz data into readable summaries
        // ---------------------------------------------------------------
        let attendanceContext = '';
        let quizContext = '';

        // --- STUDENT attendance summary ---
        if (role === 'student' && studentAttRes.data) {
            const records = studentAttRes.data as any[];
            const subjectStats: Record<string, { present: number, total: number }> = {};
            records.forEach(r => {
                const course = r.attendance_sessions?.timetables?.course_name || 'Unknown';
                if (!subjectStats[course]) subjectStats[course] = { present: 0, total: 0 };
                subjectStats[course].total++;
                if (r.status === 'present') subjectStats[course].present++;
            });
            const totalClasses = records.length;
            const totalPresent = records.filter(r => r.status === 'present').length;
            const overallPct = totalClasses === 0 ? 100 : Math.round((totalPresent / totalClasses) * 100);
            const subjectLines = Object.entries(subjectStats)
                .map(([course, s]) => `  - ${course}: ${s.present}/${s.total} (${Math.round((s.present / s.total) * 100)}%)`)
                .join('\n');
            attendanceContext = `ATTENDANCE SUMMARY (My Record up to today):
Overall: ${overallPct}% (${totalPresent}/${totalClasses} classes attended)
Per-Subject Breakdown:
${subjectLines || '  No subject data available.'}`;
        }

        // --- FACULTY attendance summary (last 30 days) ---
        if (role === 'faculty' && facultyAttRes.data) {
            const records = facultyAttRes.data as any[];
            const courseStats: Record<string, { present: number, total: number }> = {};
            const studentAbsences: Record<string, number> = {};
            records.forEach((r: any) => {
                const course = r.attendance_sessions?.timetables?.course_name || 'Unknown';
                if (!courseStats[course]) courseStats[course] = { present: 0, total: 0 };
                courseStats[course].total++;
                if (r.status === 'present') courseStats[course].present++;
                else if (r.status === 'absent') {
                    studentAbsences[r.student_id] = (studentAbsences[r.student_id] || 0) + 1;
                }
            });
            const courseLines = Object.entries(courseStats)
                .map(([course, s]) => `  - ${course}: ${Math.round((s.present / s.total) * 100)}% (${s.present}/${s.total})`)
                .join('\n');
            const atRiskCount = Object.values(studentAbsences).filter(n => n >= 3).length;
            attendanceContext = `DEPARTMENT ATTENDANCE (Last 30 days — ${profile?.department}):
Subject-wise Averages:
${courseLines || '  No data yet.'}
At-risk students (3+ absences): ${atRiskCount}`;
        }

        // --- ADMIN attendance summary (last 30 days) ---
        if (role === 'admin' && adminAttRes.data) {
            const records = adminAttRes.data as any[];
            const deptStats: Record<string, { present: number, total: number }> = {};
            records.forEach((r: any) => {
                const dept = r.attendance_sessions?.timetables?.department || 'Unknown';
                if (!deptStats[dept]) deptStats[dept] = { present: 0, total: 0 };
                deptStats[dept].total++;
                if (r.status === 'present') deptStats[dept].present++;
            });
            const deptLines = Object.entries(deptStats)
                .map(([dept, s]) => `  - ${dept}: ${Math.round((s.present / s.total) * 100)}% (${s.present}/${s.total})`)
                .join('\n');
            const total = records.length;
            const present = records.filter(r => r.status === 'present').length;
            attendanceContext = `SYSTEM-WIDE ATTENDANCE (Last 30 days):
Overall: ${total === 0 ? 'N/A' : Math.round((present / total) * 100)}% (${present}/${total} records)
By Department:
${deptLines || '  No data yet.'}`;
        }

        // --- STUDENT quiz summary ---
        if (role === 'student' && studentQuizRes.data) {
            const attempts = studentQuizRes.data as any[];
            if (attempts.length === 0) {
                quizContext = 'QUIZ HISTORY: No quiz attempts yet.';
            } else {
                const lines = attempts.map((a: any) => {
                    const pct = a.total_questions > 0 ? Math.round((a.score / a.total_questions) * 100) : 0;
                    const date = new Date(a.submitted_at).toLocaleDateString('en-IN');
                    return `  - "${a.quizzes?.title || 'Untitled'}": ${a.score}/${a.total_questions} (${pct}%) on ${date}`;
                }).join('\n');
                quizContext = `QUIZ HISTORY (Recent 10 attempts):
${lines}`;
            }
        }

        // --- FACULTY quiz summary ---
        if (role === 'faculty' && facultyQuizRes.data) {
            const quizzes = facultyQuizRes.data as any[];
            if (quizzes.length === 0) {
                quizContext = 'MY QUIZZES: No quizzes created yet.';
            } else {
                const lines = quizzes.map((q: any) => {
                    const attempts = q.quiz_attempts || [];
                    const totalAttempts = attempts.length;
                    const avgScore = totalAttempts === 0 ? 'N/A'
                        : Math.round(attempts.reduce((sum: number, a: any) => sum + (a.total_questions > 0 ? (a.score / a.total_questions) * 100 : 0), 0) / totalAttempts) + '%';
                    const status = q.is_active ? 'Active' : 'Inactive';
                    return `  - "${q.title}" [${status}] | Target: Year ${q.target_year} | ${totalAttempts} attempts | Avg Score: ${avgScore} | Validity: ${q.valid_from ? new Date(q.valid_from).toLocaleDateString('en-IN') : 'N/A'} – ${q.valid_until ? new Date(q.valid_until).toLocaleDateString('en-IN') : 'N/A'}`;
                }).join('\n');
                quizContext = `MY QUIZZES (Created by me):
${lines}`;
            }
        }

        // --- ADMIN quiz overview ---
        if (role === 'admin' && adminQuizRes.data) {
            const quizzes = adminQuizRes.data as any[];
            if (quizzes.length === 0) {
                quizContext = 'QUIZZES (System): No quizzes in the system yet.';
            } else {
                const lines = quizzes.map((q: any) => {
                    const attempts = q.quiz_attempts || [];
                    const totalAttempts = attempts.length;
                    const avgScore = totalAttempts === 0 ? 'N/A'
                        : Math.round(attempts.reduce((sum: number, a: any) => sum + (a.total_questions > 0 ? (a.score / a.total_questions) * 100 : 0), 0) / totalAttempts) + '%';
                    return `  - "${q.title}" [${q.is_active ? 'Active' : 'Inactive'}] Year ${q.target_year} | ${totalAttempts} attempts | Avg: ${avgScore}`;
                }).join('\n');
                quizContext = `QUIZZES (System-wide, latest 15):
${lines}`;
            }
        }

        // ---------------------------------------------------------------
        // E. Fetch Knowledge Base Context
        // ---------------------------------------------------------------
        const embedding = await getEmbedding(message);
        let kbData: any[] = [];
        const lowerMsgInput = message.toLowerCase().trim();

        if (lowerMsgInput.includes('rules') && lowerMsgInput.includes('regulations')) {
            console.log(`[Chat] "Rules and Regulations" request detected. Fetching broad KB context.`);
            const { data: allRules } = await supabase.from('kb_articles').select('title, content').limit(30);
            kbData = allRules || [];
        } else {
            const { data } = await supabase.rpc('match_kb_articles', {
                query_embedding: embedding,
                match_threshold: 0.3,
                match_count: 5
            });
            kbData = data || [];
        }

        // ---------------------------------------------------------------
        // F. Construct System Prompt
        // ---------------------------------------------------------------
        const userRole = profile?.role ? profile.role.toUpperCase() : 'USER';
        const userDept = profile?.department || 'General';
        const userName = profile?.full_name || 'User';
        const conversationHistory = history || [];

        const systemContext = `
You are the Campus Assistant AI. You are talking to ${userName} (${userRole}) from the ${userDept} department.
Current Real-Time: ${new Date().toLocaleString('en-US', { timeZone: 'Asia/Kolkata' })} (${currentDay}).
${isWeekendLookahead ? `**NOTE**: It is currently ${currentDay} (Weekend). The user likely wants to prepare for tomorrow. The TIMETABLE below is for MONDAY.` : ''}

### INSTRUCTIONS:
1. **Context-Aware Answers**: Always prioritize User Context (Timetable, Attendance, Quizzes, Reminders, Notices) and Knowledge Base.
   - If the user asks about "Next Class": check the TIMETABLE.
     - **STUDENT**: Compare 'start_time' with Current Time to find the next upcoming class.
     - **FACULTY**: List the upcoming classes for the department for that day.
     - **Weekend handling**: If today is ${currentDay === 'Sunday' ? 'Sunday' : 'not a weekend'}, say so and show Monday's schedule.
   - If the user asks about "attendance", "percentage", "how many classes", "absent", "present" or anything related to attendance: Use the ATTENDANCE SUMMARY section below. Be specific with subject names and percentages.
   - If the user asks about "quiz", "score", "assessment", "attempt", "my quiz", "results": Use the QUIZ section below.
   - If the user asks about "Pending Tasks", check the PENDING REMINDERS section.
   - If the user asks about "Notices" or "Events", check the RECENT NOTICES section and only mention those relevant to a ${userRole}.
   - If the user asks about "Rules and Regulations", summarize ALL Knowledge Base articles by category.
   - If the user asks specific questions like "Library fines", check the KNOWLEDGE BASE.

2. **Role-Specific Guidance for Attendance & Quizzes**:
   - **STUDENT**: Give your own attendance %, which subjects are low (<75%), and your recent quiz performance. Encourage improvement.
   - **FACULTY**: Report department attendance trends, highlight at-risk student counts, and summarize results from quizzes you created.
   - **ADMIN**: Give a system-wide attendance health picture by department and overall quiz engagement.

3. **General Knowledge Fallback**:
   - If the query is not campus-related (e.g., "What is the capital of France?"), use your general knowledge. Be helpful.
   - Do not say "I don't know" unless it's a specific personal data point not in the context.

4. **Tone**:
   - For Students: Encouraging, helpful, and concise.
   - For Faculty: Professional, organized, and respectful.
   - For Admin: Operational, direct, and data-focused.

--- CONVERSATION HISTORY (Last 10 messages) ---
${conversationHistory.map((m: any) => `${m.role.toUpperCase()}: ${m.content}`).join('\n')}

--- USER CONTEXT ---
TIMETABLE (Showing Data For: ${targetDay}):
${timetables.length ? timetables.map((t: any) => `- ${t.course_name} (${t.course_code}) at ${t.start_time} [Loc: ${t.location}]`).join('\n') : `No classes scheduled for ${targetDay}.`}

PENDING REMINDERS:
${reminders.length ? reminders.map((r: any) => `- ${r.title} (Due: ${r.due_at})`).join('\n') : "No pending reminders."}

--- ATTENDANCE & QUIZ DATA ---
${attendanceContext || 'No attendance data available for your role.'}

${quizContext || 'No quiz data available.'}

--- CAMPUS CONTEXT ---
RECENT NOTICES:
${events.length ? events.map((e: any) => `- ${e.title}: ${e.description}`).join('\n') : "No recent notices."}

KNOWLEDGE BASE (matches for query):
${kbData && kbData.length > 0 ? kbData.map((d: any) => `- ${d.title}: ${d.content}`).join('\n') : "No specific KB articles found."}
--------------------
`;

        const responseText = await generateText(message, systemContext);

        res.json({
            response: responseText,
            conversationId: conversationId
        });
    } catch (error: any) {
        console.error(error);
        res.status(500).json({ error: error.message || 'Failed to generate response' });
    }
}

export const handleImageChat = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { prompt, conversationId: reqConvId } = req.body;
        let conversationId = reqConvId || 'ephemeral-session';

        if (!req.file) {
            res.status(400).json({ error: 'No files were uploaded.' });
            return;
        }

        const imageFile = req.file;
        console.log('📸 Received Image for Chat:', {
            name: imageFile.originalname,
            size: imageFile.size,
            mimetype: imageFile.mimetype
        });

        const imageBuffer = imageFile.buffer;
        let mimeType = imageFile.mimetype;

        // Fix for "application/octet-stream" from generic uploaders
        if (mimeType === 'application/octet-stream' && imageFile.originalname) {
            const ext = imageFile.originalname.split('.').pop()?.toLowerCase();
            if (ext) {
                const mimeMap: { [key: string]: string } = {
                    'jpg': 'image/jpeg',
                    'jpeg': 'image/jpeg',
                    'png': 'image/png',
                    'webp': 'image/webp',
                    'heic': 'image/heic',
                    'heif': 'image/heif'
                };
                if (mimeMap[ext]) {
                    mimeType = mimeMap[ext];
                    console.log(`🔧 Fixed MIME type from octet-stream to ${mimeType} based on extension .${ext}`);
                }
            }
        }

        // Skip DB Inserts (Stateless)

        const responseText = await generateFromImage(prompt || 'Describe this image', imageBuffer, mimeType);

        res.json({
            response: responseText,
            conversationId: conversationId
        });
    } catch (error: any) {
        console.error(error);
        res.status(500).json({ error: error.message || 'Failed to process image' });
    }
};

export const getChatHistory = async (req: Request, res: Response): Promise<void> => {
    try {
        const { conversationId } = req.params;
        const { data, error } = await supabase
            .from('messages')
            .select('*')
            .eq('conversation_id', conversationId)
            .order('created_at', { ascending: true });

        if (error) throw error;
        res.json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const getConversations = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { data, error } = await supabase
            .from('conversations')
            .select('*')
            .eq('user_id', userId)
            .order('updated_at', { ascending: false });

        if (error) throw error;
        res.json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
