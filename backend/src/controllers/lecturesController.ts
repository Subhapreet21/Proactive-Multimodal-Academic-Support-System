
import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { generateText } from '../services/aiService';

// GET /api/lectures/subjects
// Returns distinct subjects + calculated duration for the faculty
export const getFacultySubjects = async (req: Request, res: Response) => {
    try {
        const { year, department } = req.query;

        if (!year) {
            return res.status(400).json({ error: 'Year is required' });
        }

        let query = supabase
            .from('timetables')
            .select('course_name, start_time, end_time')
            .eq('year', parseInt(year as string));

        // Add department filter if provided
        if (department) {
            query = query.eq('department', department as string);
        }

        const { data, error } = await query;

        if (error) throw error;

        // Process to find distinct courses + avg duration
        const subjectMap = new Map<string, number>();

        data?.forEach((slot: any) => {
            if (slot.course_name) {
                // Calculate duration in minutes
                const start = new Date(`1970-01-01T${slot.start_time}`);
                const end = new Date(`1970-01-01T${slot.end_time}`);
                const diffMs = end.getTime() - start.getTime();
                const durationMins = Math.round(diffMs / 60000); // ms to minutes

                // Store if not exists or update if different (simplified: just store first valid duration found)
                if (!subjectMap.has(slot.course_name)) {
                    subjectMap.set(slot.course_name, durationMins > 0 ? durationMins : 60); // Default 60 if calc fails
                }
            }
        });

        // Convert to array
        const distinctSubjects = Array.from(subjectMap.entries()).map(([name, duration]) => ({
            name,
            duration,
        }));

        res.json({ subjects: distinctSubjects });
    } catch (err: any) {
        console.error('Error fetching subjects:', err);
        res.status(500).json({ error: 'Failed to fetch subjects' });
    }
};

// POST /api/lectures/generate
export const generateLecturePlan = async (req: Request, res: Response) => {
    const { subject, topic, year, tone, duration, classType } = req.body;

    try {
        const isRevision = classType === 'revision';

        // Construct the Pedagogical Prompt
        const systemInstruction = `
      You are an expert University Professor with 20 years of experience in ${subject}.
      Your task is to create a highly detailed, minute-by-minute Lesson Plan for a ${duration}-minute class on "${topic}".
      
      CONTEXT:
      - Audience: Year ${year} Undergraduates.
      - Tone: ${tone || 'Engaging'}.
      - Class Type: ${isRevision ? 'REVISION / EXAM PREP' : 'DAILY LECTURE / NEW CONTENT'}.

      STRATEGY:
      ${isRevision
                ? '- Focus: Retrieval practice, "Spaced Repetition", correcting common misconceptions, and rapid-fire exam drills. Skip deep intro, jump to application.'
                : '- Focus: Deep conceptual understanding. Use Constructivist scaffolding: Hook -> Concept -> Practice -> Review.'}

      CRITICAL REQUIREMENTS:
      1. The "Hook" MUST use a specific, non-technical real-world analogy.
      2. The "Timeline" must strictly add up to ${duration} minutes.
      3. Provide at least 5 specific external resource search queries (mix of YouTube video titles and Article titles) that are highly relevant.

      OUTPUT FORMAT (JSON ONLY):
      {
        "title": "Lesson Title",
        "hook_analogy": "The detailed analogy to start with...",
        "core_theory_points": ["Point 1", "Point 2", "Point 3"],
        "timeline": [
          { "time": "00:00 - 05:00", "section": "The Hook", "script_notes": "Say this..." },
          { "time": "...", "section": "Core Concept", "script_notes": "..." }
        ],
        "resources": [
          { "type": "Video", "title": "Exact Video Title to Search" },
          { "type": "Article", "title": "Article Title" }
        ]
      }
    `;

        const aiResponse = await generateText(systemInstruction);

        // Parse JSON safely
        let parsedPlan;
        try {
            // Robust JSON extraction: Find the first '{' and the last '}'
            const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);

            if (jsonMatch) {
                parsedPlan = JSON.parse(jsonMatch[0]);
            } else {
                // Fallback: try basic cleanup if regex fails (unlikely for valid JSON)
                const cleanJson = aiResponse.replace(/```json/g, '').replace(/```/g, '').trim();
                parsedPlan = JSON.parse(cleanJson);
            }
        } catch (e) {
            // Fallback if AI returns partial text or invalid JSON
            console.error("JSON Parse Error:", e);
            parsedPlan = { error: "AI Format Error", raw: aiResponse };
        }

        res.json(parsedPlan);

    } catch (err: any) {
        console.error('Error generating lecture:', err);
        res.status(500).json({ error: 'AI Generation Failed' });
    }
};
