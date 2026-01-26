import { Request, Response } from 'express';
import { generateText, generateFromImage } from '../services/aiService';
import { supabase } from '../services/supabaseClient';

import { getEmbedding } from '../services/aiService';

import { WithAuthProp } from '@clerk/clerk-sdk-node';

export const handleTextChat = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        let { message, conversationId, history } = req.body;

        // 1. Skip Conversation Creation (Stateless)
        // We just echo back the ID or use a dummy one if null
        conversationId = conversationId || 'ephemeral-session';

        // 2. Skip User Message Insert
        // await supabase.from('messages').insert([...]); 

        // 3. Fetch User Context (Parallel) - REMOVED history fetch from DB
        // 3. Fetch User Context
        // A. Get Profile first to know Dept/Year/Section for Timetable
        const { data: profile } = await supabase
            .from('profiles')
            .select('role, department, year, section')
            .eq('id', userId)
            .single();

        // Helper to get current day name
        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const todayIndex = new Date().getDay();
        const currentDay = days[todayIndex];

        // --- Smart Day Detection ---
        let targetDay = currentDay;
        const lowerMsg = message.toLowerCase();

        if (lowerMsg.includes('tomorrow')) {
            targetDay = days[(todayIndex + 1) % 7];
        } else if (lowerMsg.includes('yesterday')) {
            targetDay = days[(todayIndex - 1 + 7) % 7];
        } else {
            // Check for explicit day names
            for (const day of days) {
                if (lowerMsg.includes(day.toLowerCase())) {
                    targetDay = day;
                    break;
                }
            }
        }

        console.log(`[Chat] Smart Day Detection: User asked about '${message}' -> Target Day: ${targetDay}`);

        let timetableQuery = supabase.from('timetables').select('*');

        if (profile) {
            if (profile.role === 'student') {
                if (profile.department && profile.year && profile.section) {
                    timetableQuery = timetableQuery
                        .eq('department', profile.department)
                        .eq('year', profile.year)
                        .eq('section', profile.section)
                        // Also filter Students by day to be precise, though strictly not required for load, it helps context focus
                        .eq('day_of_week', targetDay);
                } else {
                    // Incomplete student profile
                    timetableQuery = timetableQuery.eq('id', '00000000-0000-0000-0000-000000000000');
                }
            } else if (profile.role === 'faculty') {
                if (profile.department) {
                    // Faculty: Filter by Department AND Target Day
                    timetableQuery = timetableQuery
                        .eq('department', profile.department)
                        .eq('day_of_week', targetDay)
                        .limit(50);
                } else {
                    timetableQuery = timetableQuery.eq('id', '00000000-0000-0000-0000-000000000000');
                }
            } else {
                // Admin: Fetch all for target day, limit 50
                timetableQuery = timetableQuery
                    .eq('day_of_week', targetDay)
                    .limit(50);
            }
        } else {
            timetableQuery = timetableQuery.eq('id', '00000000-0000-0000-0000-000000000000');
        }

        const [timetableRes, remindersRes, eventsRes] = await Promise.all([
            timetableQuery,
            supabase.from('reminders').select('*').eq('user_id', userId).eq('is_completed', false),
            supabase.from('events_notices').select('*').order('created_at', { ascending: false }).limit(5)
        ]);

        const timetables = timetableRes.data || [];
        const reminders = remindersRes.data || [];
        const events = eventsRes.data || [];

        // Use provided history or empty
        const conversationHistory = history || [];

        // 4. Fetch Knowledge Base Context
        const embedding = await getEmbedding(message);
        const { data: kbData } = await supabase.rpc('match_kb_articles', {
            query_embedding: embedding,
            match_threshold: 0.3,
            match_count: 3
        });

        // 5. Construct System Prompt
        const userRole = profile?.role ? profile.role.toUpperCase() : 'USER';
        const userDept = profile?.department || 'General';

        const systemContext = `
You are the Campus Assistant AI. You are talking to a ${userRole} from the ${userDept} department.
You have access to the user's personal schedule and campus data. 
The user's query implies interest in: ${targetDay} (Calculated from "${message}").
Current Real-Time: ${new Date().toLocaleString('en-US', { timeZone: 'Asia/Kolkata' })} (${currentDay}).

Answer the user's question based on their role:
- If STUDENT: Focus on upcoming classes, assignments, and study advice. Be encouraging.
- If FACULTY: Focus on their teaching schedule, department responsibilities, and administrative tasks. Be professional.
- If ADMIN: Focus on system status, overall schedules, and campus alerts. Be concise and operational.

Use the following context and conversation history if relevant.
If the answer is NOT found in the context, use your general knowledge to answer helpfuly.

--- CONVERSATION HISTORY (Last 10 messages) ---
${conversationHistory.map((m: any) => `${m.role.toUpperCase()}: ${m.content}`).join('\n')}

--- USER CONTEXT ---
TIMETABLE (Showing Data For: ${targetDay}):
${timetables.length ? timetables.map((t: any) => `- ${t.course_name} (${t.course_code}) at ${t.start_time} [Loc: ${t.location}]`).join('\n') : `No classes scheduled for ${targetDay}.`}

PENDING REMINDERS:
${reminders.length ? reminders.map((r: any) => `- ${r.title} (Due: ${r.due_at})`).join('\n') : "No pending reminders."}

--- CAMPUS CONTEXT ---
RECENT NOTICES:
${events.length ? events.map((e: any) => `- ${e.title}: ${e.description}`).join('\n') : "No recent notices."}

KNOWLEDGE BASE:
${kbData && kbData.length > 0 ? kbData.map((d: any) => `- ${d.title}: ${d.content}`).join('\n') : "No specific KB articles found."}
--------------------
`;

        const responseText = await generateText(message, systemContext);

        // 6. Skip Assistant Response Insert
        // await supabase.from('messages').insert([...]);

        // 7. Skip Conversation Update
        // await supabase.from('conversations').update(...)

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
