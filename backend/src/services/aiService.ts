import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
import path from 'path';

// The .env is in the backend root. 
// src/services/aiService.ts -> ../../.env
const envPath = path.resolve(__dirname, '../../.env');
dotenv.config({ path: envPath });

const apiKeys = [
    process.env.GEMINI_API_KEY,
    process.env.GEMINI_API_KEY_2,
    process.env.GEMINI_API_KEY_3
].filter(k => k) as string[];

if (apiKeys.length === 0) {
    console.warn(`⚠️  No GEMINI_API_KEYS found. Looked in: ${envPath}`);
} else {
    console.log(`✅ Found ${apiKeys.length} Gemini API Key(s)`);
}

// Helper to execute AI calls with key rotation
const executeWithRetry = async <T>(operation: (genAI: GoogleGenerativeAI) => Promise<T>): Promise<T> => {
    let lastError: any;

    for (const key of apiKeys) {
        try {
            const genAI = new GoogleGenerativeAI(key);
            console.log(`🔑 Using API Key ending in ...${key.substring(key.length - 4)}`);
            return await operation(genAI);
        } catch (error: any) {
            console.warn(`⚠️  Error with key ...${key.substring(key.length - 4)}: ${error.message}`);
            lastError = error;
            // Continue to next key if it's a quota or permission error
            // If it's a completely unrelated error (e.g. prompt invalid), we might still want to try? 
            // For now, simple rotation for any error.
        }
    }
    throw lastError || new Error("All API keys failed");
};

export const generateText = async (prompt: string, context?: string) => {
    return executeWithRetry(async (genAI) => {
        console.log("🤖 Generating text with gemini-2.5-flash...");
        const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });
        const fullPrompt = context ? `Context: ${context}\n\nQuestion: ${prompt}` : prompt;
        const result = await model.generateContent(fullPrompt);
        return result.response.text();
    });
};

export const generateFromImage = async (prompt: string, imageBuffer: Buffer, mimeType: string) => {
    return executeWithRetry(async (genAI) => {
        console.log("👁️ Generating vision response with gemini-2.5-flash...");
        const model = genAI.getGenerativeModel({ model: "gemini-2.5-flash" });

        // Convert buffer to base64
        const imagePart = {
            inlineData: {
                data: imageBuffer.toString('base64'),
                mimeType
            }
        };

        const result = await model.generateContent([prompt, imagePart]);
        return result.response.text();
    });
};

export const getEmbedding = async (text: string) => {
    return executeWithRetry(async (genAI) => {
        console.log("🧬 Generating embedding with text-embedding-004...");
        const model = genAI.getGenerativeModel({ model: "text-embedding-004" });
        const result = await model.embedContent(text);
        return result.embedding.values;
    });
}
