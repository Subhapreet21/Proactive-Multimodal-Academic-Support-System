import { Request, Response } from 'express';
import { createClient } from '@supabase/supabase-js';
import fetch from 'node-fetch'; // Added for URL validation

import { generateText, getEmbedding } from '../services/aiService';

// Initialize Supabase Client
const supabase = createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// Helper to validate links
const validateLinks = async (plan: any) => {
    if (!plan.schedule) return plan;

    for (const slot of plan.schedule) {
        if (slot.resource_links && Array.isArray(slot.resource_links)) {
            const validatedLinks = [];

            for (const link of slot.resource_links) {
                try {
                    // 1. Fetch content (GET request with 3s timeout)
                    const controller = new AbortController();
                    const timeout = setTimeout(() => controller.abort(), 3000);

                    const response = await fetch(link.url, {
                        method: 'GET',
                        headers: { 'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36' },
                        signal: controller.signal
                    });
                    clearTimeout(timeout);

                    if (!response.ok) {
                        throw new Error(`Status ${response.status}`);
                    }

                    // 2. Deep Content Check (Read first 2KB)
                    const text = await response.text();
                    const snippet = text.substring(0, 2000).toLowerCase(); // Scan only the beginning

                    // "Red Flags" that indicate soft errors
                    const isSoft404 = snippet.includes('page not found') ||
                        snippet.includes('video unavailable') ||
                        snippet.includes('404 error') ||
                        snippet.includes('content removed');

                    if (isSoft404) {
                        throw new Error('Soft 404 detected');
                    }

                    // Valid Link
                    validatedLinks.push(link);

                } catch (e) {
                    // 3. Fallback to Google Search if unreachable or removed
                    const reason = e instanceof Error ? e.message : 'Unknown';
                    console.log(`⚠️ Link flagged (${reason}): ${link.url} -> Falling back.`);

                    validatedLinks.push({
                        title: `Search: ${link.title}`,
                        url: `https://www.google.com/search?q=${encodeURIComponent(link.title + ' ' + (slot.activity || ''))}`
                    });
                }
            }
            slot.resource_links = validatedLinks;
        }
    }
    return plan;
};

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
              "focus_tip": "Specific tip",
              "type": "task" | "break" | "revision" | "class",
              "resource_links": [
                { "title": "Source Name (e.g. GeeksforGeeks)", "url": "https://..." }
              ]
            }
          ],
          "message": "A short, encouraging summary tailored to the workload."
        }
        
        **Constraint:** For every "task" or "revision" slot, you MUST provide at least 3 high-quality educational links (e.g., GeeksforGeeks, YouTube, W3Schools, Coursera, NIST) relevant to the specific topic.
        `;

        // 7. Call Gemini
        const text = await generateText(prompt);

        // 8. Parse & Return
        const jsonStr = text.replace(/```json/g, '').replace(/```/g, '').trim();
        let plan = JSON.parse(jsonStr);

        // 9. VALIDATE LINKS
        plan = await validateLinks(plan);

        res.json(plan);

    } catch (error) {
        console.error('Error generating study plan:', error);
        res.status(500).json({ error: 'Failed to generate study plan' });
    }
};
