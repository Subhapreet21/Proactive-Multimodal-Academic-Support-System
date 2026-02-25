import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { WithAuthProp } from '@clerk/clerk-sdk-node';
import { GoogleGenAI } from '@google/genai';

const AI_MODEL = 'gemini-2.5-flash';

// ─── Per-role TTL durations (milliseconds) ─────────────────────────────────
const TTL_STUDENT = 4 * 60 * 60 * 1000;    // 4 hours
const TTL_DEPT = 12 * 60 * 60 * 1000;   // 12 hours

// ─── API Key rotation ───────────────────────────────────────────────────────
const apiKeys = [
    process.env.GEMINI_API_KEY,
    process.env.GEMINI_API_KEY_1,
    process.env.GEMINI_API_KEY_2,
    process.env.GEMINI_API_KEY_3,
    process.env.GEMINI_API_KEY_4,
    process.env.GEMINI_API_KEY_5,
    process.env.GEMINI_API_KEY_6,
    process.env.GEMINI_API_KEY_7
].filter(k => k) as string[];

const executeWithRetry = async <T>(operation: (ai: GoogleGenAI) => Promise<T>): Promise<T> => {
    let lastError: any;
    const shuffledKeys = [...apiKeys].sort(() => Math.random() - 0.5);
    for (const key of shuffledKeys) {
        try {
            const ai = new GoogleGenAI({ apiKey: key });
            return await operation(ai);
        } catch (error: any) {
            console.warn(`⚠️  Error with key ...${key.substring(key.length - 4)}: ${error.message}`);
            lastError = error;
        }
    }
    throw lastError || new Error('All API keys failed or no API keys configured');
};

// ─── DB helpers ─────────────────────────────────────────────────────────────

/**
 * Reads the latest AI insight from the persistent table.
 * Returns null if no record exists.
 */
const readInsight = async (targetId: string, type: 'student_forecast' | 'dept_audit') => {
    const { data, error } = await supabase
        .from('ai_insights')
        .select('content, last_updated, is_stale')
        .eq('target_id', targetId)
        .eq('type', type)
        .single();

    if (error && error.code !== 'PGRST116') throw error;
    return data ?? null;
};

/**
 * Upserts (insert or update) an AI insight in the persistent table.
 */
const writeInsight = async (targetId: string, type: 'student_forecast' | 'dept_audit', content: any) => {
    const { error } = await supabase
        .from('ai_insights')
        .upsert({
            target_id: targetId,
            type,
            content,
            last_updated: new Date().toISOString(),
            is_stale: false,
        }, { onConflict: 'target_id,type' });

    if (error) console.error(`[writeInsight] Failed to write ${type} for ${targetId}:`, error.message);
};

/**
 * Marks one or more student insights as stale so the next read triggers a background refresh.
 * Called by attendanceController after a session is submitted.
 */
export const markStudentInsightsStale = async (studentIds: string[]) => {
    if (!studentIds.length) return;
    const { error } = await supabase
        .from('ai_insights')
        .update({ is_stale: true })
        .in('target_id', studentIds)
        .eq('type', 'student_forecast');

    if (error) console.error('[markStudentInsightsStale] Error:', error.message);
};

/**
 * Marks the dept audit as stale (called after any attendance submission).
 */
export const markDeptAuditStale = async () => {
    const { error } = await supabase
        .from('ai_insights')
        .update({ is_stale: true })
        .eq('type', 'dept_audit');

    if (error) console.error('[markDeptAuditStale] Error:', error.message);
};

// ─── Core AI computation functions ──────────────────────────────────────────

const computeStudentForecast = async (studentId: string): Promise<any> => {
    const { data: profile } = await supabase
        .from('profiles')
        .select('full_name, department, year, section')
        .eq('id', studentId)
        .single();

    if (!profile) throw new Error('Student not found.');

    const { data: records, error: recordsError } = await supabase
        .from('attendance_records')
        .select('status, attendance_sessions!inner(date, timetables(course_name))')
        .eq('student_id', studentId);

    if (recordsError) throw recordsError;

    const totalRecords = records?.length || 0;
    const presentRecords = records?.filter((r: any) => r.status === 'present').length || 0;
    const absentRecords = records?.filter((r: any) => r.status === 'absent').length || 0;
    const currentPercentage = totalRecords === 0 ? 100 : Math.round((presentRecords / totalRecords) * 100);

    const sortedRecords = [...(records || [])].sort((a: any, b: any) =>
        new Date(b.attendance_sessions.date).getTime() - new Date(a.attendance_sessions.date).getTime()
    );
    const recentRecords = sortedRecords.slice(0, 10);
    const recentPresent = recentRecords.filter((r: any) => r.status === 'present').length;
    const recentPercentage = recentRecords.length === 0 ? 100 : Math.round((recentPresent / recentRecords.length) * 100);
    const trend = recentPercentage >= currentPercentage ? 'improving or stable' : 'declining';

    const prompt = `
    You are an academic support AI analyzing a student's attendance to provide proactive guidance.
    Student Name: ${profile.full_name}
    Total Classes Scheduled: ${totalRecords}
    Total Classes Attended: ${presentRecords}
    Total Classes Absent: ${absentRecords}
    Current Attendance Percentage: ${currentPercentage}%
    Recent Trend (Last 10 classes): ${recentPercentage}% (${trend})
    
    The university requires 75% attendance to pass.
    
    Task:
    1. Calculate a "Projected End-of-Semester Percentage". Assume the course is roughly halfway done. If the trend is declining, project a slightly lower number. If improving, project a slightly higher number. Keep it realistic and mathematically plausible based on current data.
    2. Write a short, empathetic 1-2 sentence "Nudge" or insight. If they are safe (> 80%), encourage them to maintain it. If they are at risk (< 75% or dropping fast), warn them and suggest attending the next few classes. Address the student directly by name.
    3. Write a short, 1-2 sentence "Faculty Insight". If the student is safe, say so. If they are at risk or showing a declining trend, summarize the risk pattern so the faculty member can intervene. Address the faculty.
    
    Return ONLY a JSON object exactly matching this structure, with no formatting blocks:
    {
      "projectedPercentage": 74,
      "studentNudge": "String",
      "facultyInsight": "String"
    }
    `;

    const responseText = await executeWithRetry(async (ai) => {
        const response = await ai.models.generateContent({
            model: AI_MODEL,
            contents: prompt,
            config: { responseMimeType: 'application/json' }
        });
        if (!response.text) throw new Error('AI returned empty response');
        return response.text;
    });

    const aiData = JSON.parse(responseText);

    return {
        currentPercentage,
        projectedPercentage: aiData.projectedPercentage,
        studentNudge: aiData.studentNudge,
        facultyInsight: aiData.facultyInsight,
    };
};

const computeDeptAudit = async (): Promise<string> => {
    const { data: records, error } = await supabase
        .from('attendance_records')
        .select('status, profiles!inner(department)');

    if (error) throw error;

    const deptStats: Record<string, { total: number; present: number }> = {};
    (records || []).forEach((r: any) => {
        const dept = r.profiles?.department;
        if (!dept) return;
        if (!deptStats[dept]) deptStats[dept] = { total: 0, present: 0 };
        deptStats[dept].total++;
        if (r.status === 'present') deptStats[dept].present++;
    });

    const deptSummary = Object.keys(deptStats).map(dept => {
        const pct = deptStats[dept].total === 0 ? 0 : Math.round((deptStats[dept].present / deptStats[dept].total) * 100);
        return `${dept}: ${pct}% (${deptStats[dept].total} records)`;
    }).join('\n');

    const prompt = `
    Institutional academic auditor risk analysis.
    Departments:
    ${deptSummary}

    Task:
    1. Identify any departments significantly below the 75% institutional requirement.
    2. Write a 2-sentence "Systemic Risk Audit" summarizing the health and identifying the most at-risk department or praising the strongest.
    
    Return ONLY JSON: {"auditMessage": "String"}
    `;

    const responseText = await executeWithRetry(async (ai) => {
        const response = await ai.models.generateContent({
            model: AI_MODEL,
            contents: prompt,
            config: { responseMimeType: 'application/json' }
        });
        return response.text || '';
    });

    const aiData = JSON.parse(responseText);
    return aiData.auditMessage || 'No audit message generated.';
};

// ─── Background revalidation (fire-and-forget) ──────────────────────────────
// These  are intentionally not awaited so they don't block the HTTP response.

const triggerStudentRefresh = (studentId: string) => {
    computeStudentForecast(studentId)
        .then(data => writeInsight(studentId, 'student_forecast', data))
        .catch(err => console.error(`[backgroundRefresh] student ${studentId}:`, err.message));
};

const triggerDeptRefresh = () => {
    computeDeptAudit()
        .then(msg => writeInsight('__dept__', 'dept_audit', { auditMessage: msg }))
        .catch(err => console.error('[backgroundRefresh] dept audit:', err.message));
};

// ─── Public API Routes ───────────────────────────────────────────────────────

// GET /api/attendance/ai/forecast-student/:id
export const getStudentForecast = async (req: Request, res: Response): Promise<void> => {
    try {
        const studentId = req.params.id;
        const now = Date.now();

        // 1. Try DB-persisted insight first
        const cached = await readInsight(studentId, 'student_forecast');

        if (cached) {
            const ageMs = now - new Date(cached.last_updated).getTime();
            const expired = ageMs > TTL_STUDENT;

            // Return cached data immediately (Stale-While-Revalidate pattern)
            res.json({
                ...cached.content,
                _meta: {
                    lastUpdated: cached.last_updated,
                    isStale: cached.is_stale || expired,
                }
            });

            // If stale or expired, kick off background refresh
            if (cached.is_stale || expired) {
                triggerStudentRefresh(studentId);
            }
            return;
        }

        // 2. No cached data at all — compute synchronously for first load
        console.log(`[getStudentForecast] First-time computation for ${studentId}`);
        const data = await computeStudentForecast(studentId);
        await writeInsight(studentId, 'student_forecast', data);
        res.json({ ...data, _meta: { lastUpdated: new Date().toISOString(), isStale: false } });

    } catch (error: any) {
        console.error('[getStudentForecast] Error:', error.message);
        res.status(500).json({ error: error.message });
    }
};

// Internal helper for the admin stats endpoint
export const generateDepartmentAuditInternal = async (): Promise<string> => {
    try {
        const now = Date.now();
        const cached = await readInsight('__dept__', 'dept_audit');

        if (cached) {
            const ageMs = now - new Date(cached.last_updated).getTime();
            const expired = ageMs > TTL_DEPT;
            if (cached.is_stale || expired) triggerDeptRefresh();
            return cached.content.auditMessage || 'Audit unavailable.';
        }

        // First-time: compute synchronously
        const msg = await computeDeptAudit();
        await writeInsight('__dept__', 'dept_audit', { auditMessage: msg });
        return msg;

    } catch (error: any) {
        console.error('[generateDepartmentAuditInternal] Error:', error.message);
        return 'Audit service temporarily unavailable.';
    }
};

// GET /api/attendance/ai/forecast-department
export const getDepartmentForecast = async (req: Request, res: Response): Promise<void> => {
    try {
        const auditMessage = await generateDepartmentAuditInternal();
        res.json({ auditMessage });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
