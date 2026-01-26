
import { Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

import { generateText, getEmbedding } from '../services/aiService';

// Initialize Supabase Client
const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

export const generateStudyPlan = async (req: Request, res: Response) => {
    try {
        const { userId, date, energyLevel } = req.body;

        if (!userId) {
            return res.status(400).json({ error: 'Missing userId' });
        }

        const today = date ? new Date(date) : new Date();
        const startOfDay = new Date(today.setHours(0, 0, 0, 0)).toISOString();
        const endOfDay = new Date(today.setHours(23, 59, 59, 999)).toISOString();

        // Get Day Name for Timetable (e.g., 'Monday')
        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const dayName = days[today.getDay()];

        console.log(`🧠 Generating study plan for ${userId} on ${dayName} (${startOfDay})`);

        // 1. Fetch Student Profile
        const { data: profile, error: profileError } = await supabase
            .from('profiles')
            .select('department, year, section')
            .eq('id', userId)
            .single();

        if (profileError || !profile) {
            console.error('❌ Profile missing:', profileError);
            return res.status(404).json({ error: 'Profile not found' });
        }

        // 2. Fetch Timetable for the Specific Day
        const { data: timetableData, error: ttError } = await supabase
            .from('timetables')
            .select('start_time, end_time, course_name, location')
            .eq('department', profile.department)
            .eq('year', profile.year)
            .eq('section', profile.section)
            .eq('day_of_week', dayName)
            .order('start_time', { ascending: true });

        const timetableStr = timetableData && timetableData.length > 0
            ? timetableData.map((t: any) => `${t.start_time} - ${t.end_time}: ${t.course_name}`).join('\n')
            : "No classes scheduled today. Entire day is theoretically free.";

        // 3. Fetch Pending Tasks
        const { data: tasks, error: tasksError } = await supabase
            .from('reminders')
            .select('title, category, due_at, description')
            .eq('user_id', userId)
            .eq('is_completed', false)
            .lte('due_at', new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()) // Next 7 days
            .order('due_at', { ascending: true });

        // 4. Knowledge Base Context (Optimize: Search based on task titles)
        let kbContext = "No specific study resources found.";
        if (tasks && tasks.length > 0) {
            try {
                // effective query: combine top 3 task titles
                const queryText = tasks.slice(0, 3).map((t: any) => t.title).join(' ');
                const embedding = await getEmbedding(queryText);

                const { data: kbData } = await supabase.rpc('match_kb_articles', {
                    query_embedding: embedding,
                    match_threshold: 0.3,
                    match_count: 3
                });

                if (kbData && kbData.length > 0) {
                    kbContext = kbData.map((d: any) => `- ${d.title}: ${d.content.substring(0, 150)}...`).join('\n');
                }
            } catch (e) {
                console.warn("KB Search failed:", e);
            }
        }

        // 5. Fetch Events
        const { data: events, error: eventsError } = await supabase
            .from('events_notices')
            .select('title, date, category')
            .gte('date', startOfDay)
            .lte('date', endOfDay);

        // 6. Construct Prompt
        const prompt = `
        Act as an expert academic study planner.
        Create a personalized study schedule for ${dayName}, ${today.toLocaleDateString()} for a ${profile.department} student.

        **Context:**
        - **Energy Level:** ${energyLevel || 'Medium'} (Adjust intensity accordingly).
        - **Fixed Schedule (Classes):** 
        ${timetableStr}
        
        - **Pending Tasks (Prioritize these):** ${JSON.stringify(tasks)}
        
        - **Relevant Study Resources (from Knowledge Base):**
        ${kbContext}

        - **Campus Events Today:** ${JSON.stringify(events)}
        
        **Goal:**
        - Identify free time slots around the fixed class schedule.
        - Allocate time for pending tasks based on urgency.
        - Include short breaks (Pomodoro style).
        - Suggest specific revision topics based on the tasks and KB resources.
        - If the day is full of classes, focus on evening study blocks.

        **Output Format (Strict JSON):**
        {
          "schedule": [
            {
              "time": "HH:MM - HH:MM",
              "activity": "Actionable Title",
              "focus_tip": "Specific tip or resource reference",
              "type": "task" | "break" | "revision" | "class"
            }
          ],
          "message": "A short, encouraging summary tailored to the workload."
        }
        `;

        // 7. Call Gemini
        const text = await generateText(prompt);

        // 8. Parse & Return
        const jsonStr = text.replace(/```json/g, '').replace(/```/g, '').trim();
        const plan = JSON.parse(jsonStr);

        res.json(plan);

    } catch (error) {
        console.error('Error generating study plan:', error);
        res.status(500).json({ error: 'Failed to generate study plan' });
    }
};
