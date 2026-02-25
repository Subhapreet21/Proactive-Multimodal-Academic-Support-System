import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { WithAuthProp } from '@clerk/clerk-sdk-node';
import { GoogleGenAI } from '@google/genai';

const AI_MODEL = 'gemini-2.5-flash';

// 2-hour cache for department audit to reduce resource consumption
let departmentAuditCache: { message: string, timestamp: number } | null = null;
const CACHE_DURATION = 2 * 60 * 60 * 1000;

// 4-hour cache for individual student forecasts
const studentForecastCache = new Map<string, { data: any, timestamp: number }>();
const STUDENT_CACHE_DURATION = 4 * 60 * 60 * 1000;


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
    throw lastError || new Error("All API keys failed or no API keys configured");
};

// GET /api/attendance/ai/forecast-student/:id
export const getStudentForecast = async (req: Request, res: Response): Promise<void> => {
    try {
        const studentId = req.params.id;

        const now = Date.now();
        const cached = studentForecastCache.get(studentId);
        if (cached && (now - cached.timestamp < STUDENT_CACHE_DURATION)) {
            res.json(cached.data);
            return;
        }

        // 1. Fetch student profile
        const { data: profile } = await supabase.from('profiles').select('full_name, department, year, section').eq('id', studentId).single();
        if (!profile) {
            res.status(404).json({ error: 'Student not found.' });
            return;
        }

        // 2. Fetch all attendance records for this student
        const { data: records, error: recordsError } = await supabase
            .from('attendance_records')
            .select(`
                status,
                attendance_sessions!inner(date, timetables(course_name))
            `)
            .eq('student_id', studentId);

        if (recordsError) throw recordsError;

        const totalRecords = records?.length || 0;
        const presentRecords = records?.filter((r: any) => r.status === 'present').length || 0;
        const currentPercentage = totalRecords === 0 ? 100 : Math.round((presentRecords / totalRecords) * 100);

        // Calculate a simple trend (last 10 classes vs overall)
        const sortedRecords = [...(records || [])].sort((a: any, b: any) => {
            return new Date(b.attendance_sessions.date).getTime() - new Date(a.attendance_sessions.date).getTime();
        });

        const recentRecords = sortedRecords.slice(0, 10);
        const recentPresent = recentRecords.filter(r => r.status === 'present').length;
        const recentPercentage = recentRecords.length === 0 ? 100 : Math.round((recentPresent / recentRecords.length) * 100);

        const trend = recentPercentage >= currentPercentage ? 'improving or stable' : 'declining';

        // 3. Construct prompt for Gemini
        const prompt = `
        You are an academic support AI analyzing a student's attendance to provide proactive guidance.
        Student Name: ${profile.full_name}
        Total Classes Scheduled: ${totalRecords}
        Total Classes Attended: ${presentRecords}
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

        // 4. Call Gemini API
        const responseText = await executeWithRetry(async (ai) => {
            const response = await ai.models.generateContent({
                model: AI_MODEL,
                contents: prompt,
                config: {
                    responseMimeType: 'application/json'
                }
            });
            if (!response.text) {
                throw new Error("AI returned empty response");
            }
            return response.text;
        });

        const aiData = JSON.parse(responseText);

        const responseData = {
            currentPercentage,
            projectedPercentage: aiData.projectedPercentage,
            studentNudge: aiData.studentNudge,
            facultyInsight: aiData.facultyInsight
        };

        // Save to cache
        studentForecastCache.set(studentId, { data: responseData, timestamp: now });

        res.json(responseData);

    } catch (error: any) {
        console.error('[getStudentForecast] Error:', error.message);
        res.status(500).json({ error: error.message });
    }
};

// Internal helper for proactive computation
export const generateDepartmentAuditInternal = async (): Promise<string> => {
    try {
        const now = Date.now();
        if (departmentAuditCache && (now - departmentAuditCache.timestamp < CACHE_DURATION)) {
            return departmentAuditCache.message;
        }

        const { data: records, error } = await supabase
            .from('attendance_records')
            .select(`
                status,
                profiles!inner(department)
            `);

        if (error) throw error;

        const deptStats: Record<string, { total: number, present: number }> = {};
        (records || []).forEach((r: any) => {
            const dept = r.profiles?.department;
            if (!dept) return;
            if (!deptStats[dept]) {
                deptStats[dept] = { total: 0, present: 0 };
            }
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
            return response.text || "";
        });

        const aiData = JSON.parse(responseText);
        const message = aiData.auditMessage || "No audit message generated.";

        // Save to cache
        departmentAuditCache = { message, timestamp: now };
        return message;

    } catch (error: any) {
        console.error('[generateDepartmentAuditInternal] Error:', error.message);
        return departmentAuditCache?.message || "Audit service temporarily unavailable.";
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
