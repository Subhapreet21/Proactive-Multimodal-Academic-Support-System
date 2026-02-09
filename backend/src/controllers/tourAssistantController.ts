import { Request, Response } from 'express';
import { generateText } from '../services/aiService';
import * as fs from 'fs';
import * as path from 'path';
import { WithAuthProp } from '@clerk/clerk-sdk-node';

// Load the scene knowledge base
const knowledgeBasePath = path.join(__dirname, '../../data/scene_knowledge_base.json');
let sceneKnowledgeBase: any = {};

try {
    const rawData = fs.readFileSync(knowledgeBasePath, 'utf-8');
    sceneKnowledgeBase = JSON.parse(rawData);
    console.log(`✅ Loaded scene knowledge base with ${Object.keys(sceneKnowledgeBase).length} scenes`);
} catch (error) {
    console.error('❌ Failed to load scene knowledge base:', error);
}

export const askTourAssistant = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { sceneId, question, conversationHistory } = req.body;

        // Validate inputs
        if (!sceneId || !question) {
            res.status(400).json({ error: 'sceneId and question are required' });
            return;
        }

        // Get scene context from knowledge base
        const sceneContext = sceneKnowledgeBase[sceneId];

        if (!sceneContext) {
            res.status(404).json({ error: `Scene '${sceneId}' not found in knowledge base` });
            return;
        }

        // Build conversation history string
        const historyStr = conversationHistory && conversationHistory.length > 0
            ? conversationHistory.map((m: any) => `${m.role.toUpperCase()}: ${m.content}`).join('\n')
            : 'No previous conversation.';

        // Construct rich system prompt with scene context
        const systemPrompt = `
You are an AI Tour Guide for Malla Reddy University's Virtual Campus Tour.
You are friendly, helpful, and knowledgeable about the campus.

=== CURRENT LOCATION CONTEXT ===
Location: ${sceneContext.title}
Category: ${sceneContext.category}
Description: ${sceneContext.description}

FACILITIES AVAILABLE:
${sceneContext.facilities.length > 0 ? sceneContext.facilities.map((f: string) => `- ${f}`).join('\n') : 'Not specified'}

${sceneContext.departments.length > 0 ? `DEPARTMENTS:\n${sceneContext.departments.join(', ')}` : ''}

${sceneContext.programs.length > 0 ? `PROGRAMS OFFERED:\n${sceneContext.programs.join(', ')}` : ''}

${sceneContext.timings ? `TIMINGS: ${sceneContext.timings}` : ''}

${sceneContext.contactInfo ? `CONTACT: ${sceneContext.contactInfo}` : ''}

${sceneContext.directions ? `DIRECTIONS: ${sceneContext.directions}` : ''}

${sceneContext.nearbyLocations.length > 0 ? `NEARBY LOCATIONS:\n${sceneContext.nearbyLocations.map((loc: string) => `- ${loc}`).join('\n')}` : ''}

${sceneContext.historicalInfo ? `HISTORICAL INFO: ${sceneContext.historicalInfo}` : ''}

=== CONVERSATION HISTORY ===
${historyStr}

=== INSTRUCTIONS ===
- Answer the student's question based on the current location context above
- Be informative, friendly, and concise
- If asked about directions, use the "Directions" and "Nearby Locations" information
- If asked about something not in the context, provide general helpful information
- Focus on helping prospective students understand the campus

STUDENT QUESTION: ${question}

Provide a helpful, accurate response:
`;

        // Generate AI response using Gemini
        const answer = await generateText(question, systemPrompt);

        // Generate suggested follow-up questions based on scene type
        const suggestedQuestions = generateSuggestedQuestions(sceneContext);

        res.json({
            answer,
            conversationId: `tour-${sceneId}-${Date.now()}`,
            sceneContext: {
                title: sceneContext.title,
                category: sceneContext.category,
                suggestedQuestions
            }
        });

    } catch (error: any) {
        console.error('Error in tour assistant:', error);
        res.status(500).json({ error: error.message || 'Failed to generate response' });
    }
};

// Helper function to generate context-aware suggested questions
function generateSuggestedQuestions(sceneContext: any): string[] {
    const questions: string[] = [];

    // Always include basic questions
    questions.push("What is this place?");

    // Add context-specific questions
    if (sceneContext.facilities && sceneContext.facilities.length > 0) {
        questions.push("What facilities are available here?");
    }

    if (sceneContext.programs && sceneContext.programs.length > 0) {
        questions.push("What programs are offered?");
    }

    if (sceneContext.timings) {
        questions.push("What are the timings?");
    }

    if (sceneContext.nearbyLocations && sceneContext.nearbyLocations.length > 0) {
        questions.push("What's nearby?");
    }

    // Category-specific questions
    if (sceneContext.category.includes('DEPT')) {
        questions.push("What can I study here?");
    } else if (sceneContext.category === 'LIBRARY') {
        questions.push("How can I access the library resources?");
    } else if (sceneContext.category === 'SPORTS') {
        questions.push("What sports facilities are available?");
    } else if (sceneContext.category === 'HOSTEL') {
        questions.push("What amenities are in the hostel?");
    }

    // Limit to 4 suggestions
    return questions.slice(0, 4);
}
