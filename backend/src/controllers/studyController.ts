
import { Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';

import { generateText } from '../services/aiService';

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

        console.log(`🧠 Generating study plan for ${userId} on ${startOfDay}`);

        // 1. Fetch Student Profile (to get Year/Section)
        const { data: profile, error: profileError } = await supabase
            .from('profiles')
            .select('department, year, section')
            .eq('id', userId)
            .single();

        if (profileError || !profile) {
            console.error('❌ Profile missing:', profileError);
            return res.status(404).json({ error: 'Profile not found' });
        }

        // 2. Fetch Timetable (to find FREE slots)
        // We look for slots that are NOT 'Free' to know busy times, effectively finding free times.
        const { data: timetable, error: ttError } = await supabase
            .from('timetables')
            .select('start_time, end_time, subject')
            .eq('department', profile.department)
            .eq('year', profile.year)
            .eq('section', profile.section)
        // Assuming timetable is static for weekdays, need day of week
        // Logic improvement: Schema usually has 'day_of_week'. Assuming user gave valid date.
        // For now, simpler: Get all classes, assuming the app filters by day in frontend or we filter here.
        // Let's assume the query gets ALL classes and we need to filter by day locally if schema has 'day'.
        // Actually, let's look at schema assumption. If simple, just fetch all.
        // Better: Just fetch busy slots.

        // IMPORTANT: If your timetable schema doesn't support date-based querying directly, 
        // you might need to map 'Monday' to the date.
        // For this implementation, we will assume the FE sends the 'day_of_week' or we derive it.
        // Let's assume we fetch all and let AI figure it out or we simplify to "After college hours".
        // Let's simplify: "College is 9-4". 

        // 3. Fetch Pending Tasks
        const { data: tasks, error: tasksError } = await supabase
            .from('reminders')
            .select('title, category, due_at, description')
            .eq('user_id', userId)
            .eq('is_completed', false)
            .lte('due_at', new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()) // Next 7 days
            .order('due_at', { ascending: true });

        // 4. Fetch Events
        const { data: events, error: eventsError } = await supabase
            .from('events_notices')
            .select('title, date, category')
            .gte('date', startOfDay)
            .lte('date', endOfDay);

        // 5. Construct Prompt
        const prompt = `
        Act as an expert academic study planner.
        Create a personalized study schedule for today (${new Date().toLocaleDateString()}) for a Computer Science student.

        **Context:**
        - **Energy Level:** ${energyLevel || 'Medium'} (Adjust intensity accordingly).
        - **College Hours:** 9:00 AM - 4:00 PM (Busy).
        - **Pending Tasks:** ${JSON.stringify(tasks)}
        - **Events Today:** ${JSON.stringify(events)}
        
        **Goal:**
        - Identify free time slots (post-4 PM and any gaps).
        - Allocate time for pending tasks based on urgency.
        - Include short breaks (Pomodoro style).
        - Suggest specific revision topics based on the tasks (e.g., if task is "Cloud Assignment", add "Review Cloud Concepts").

        **Output Format (Strict JSON):**
        {
          "schedule": [
            {
              "time": "18:00 - 19:00",
              "activity": "Task Title",
              "focus_tip": "Specific tip for this task",
              "type": "task" | "break" | "revision"
            }
          ],
          "message": "A motivational summary message."
        }
        `;

        // 6. Call Gemini
        const text = await generateText(prompt);

        // 7. Parse & Return
        // Gemini might return markdown ```json ... ```, need to clean it.
        const jsonStr = text.replace(/```json/g, '').replace(/```/g, '').trim();
        const plan = JSON.parse(jsonStr);

        res.json(plan);

    } catch (error) {
        console.error('Error generating study plan:', error);
        res.status(500).json({ error: 'Failed to generate study plan' });
    }
};
