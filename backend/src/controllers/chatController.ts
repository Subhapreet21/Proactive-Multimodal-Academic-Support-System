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
            .select('department, year, section')
            .eq('id', userId)
            .single();

        const [timetableRes, remindersRes, eventsRes] = await Promise.all([
            // Fix: Query timetable by academic details, not user_id
            profile ? supabase.from('timetables')
                .select('*')
                .eq('department', profile.department)
                .eq('year', profile.year)
                .eq('section', profile.section)
                : { data: [] } as any,
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
        const systemContext = `
You are the Campus Assistant AI. You have access to the user's personal schedule and campus data.
Answer the user's question. Use the following context and conversation history if relevant.
If the answer is NOT found in the context, use your general knowledge to answer helpfuly (e.g. general academic advice, definitions, chit-chat).

--- CONVERSATION HISTORY (Last 10 messages) ---
${conversationHistory.map((m: any) => `${m.role.toUpperCase()}: ${m.content}`).join('\n')}

--- USER CONTEXT ---
TIMETABLE:
${timetables.length ? timetables.map((t: any) => `- ${t.day_of_week}: ${t.course_name} at ${t.start_time}`).join('\n') : "No classes scheduled."}

PENDING REMINDERS:
${reminders.length ? reminders.map((r: any) => `- ${r.title} (Due: ${r.due_at})`).join('\n') : "No pending reminders."}

--- CAMPUS CONTEXT ---
CURRENT TIME: ${new Date().toLocaleString('en-US', { timeZone: 'Asia/Kolkata' })} (Use this to determine "next" class)

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

        if (!req.files || Object.keys(req.files).length === 0) {
            res.status(400).json({ error: 'No files were uploaded.' });
            return;
        }

        const imageFile = req.files.image as any;
        console.log('📸 Received Image for Chat:', {
            name: imageFile.name,
            size: imageFile.size,
            mimetype: imageFile.mimetype
        });

        const imageBuffer = imageFile.data;
        let mimeType = imageFile.mimetype;

        // Fix for "application/octet-stream" from generic uploaders
        if (mimeType === 'application/octet-stream' && imageFile.name) {
            const ext = imageFile.name.split('.').pop()?.toLowerCase();
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
