import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
import path from 'path';

// The .env is in the backend root. 
// src/services/aiService.ts -> ../../.env
const envPath = path.resolve(__dirname, '../../.env');
dotenv.config({ path: envPath });

const apiKeys = [
    process.env.GEMINI_API_KEY, // Fallback/Legacy
    process.env.GEMINI_API_KEY_1,
    process.env.GEMINI_API_KEY_2,
    process.env.GEMINI_API_KEY_3,
    process.env.GEMINI_API_KEY_4,
    process.env.GEMINI_API_KEY_5,
    process.env.GEMINI_API_KEY_6,
    process.env.GEMINI_API_KEY_7
].filter(k => k) as string[];

if (apiKeys.length === 0) {
    console.warn(`⚠️  No GEMINI_API_KEYS found. Looked in: ${envPath}`);
} else {
    // Determine which keys were found for logging (masking content)
    const foundKeys = apiKeys.map(k => `...${k.substring(k.length - 4)}`);
    console.log(`✅ Found ${apiKeys.length} Gemini API Key(s): ${foundKeys.join(', ')}`);
}

// Helper to execute AI calls with key rotation (Load Balancing + Failover)
const executeWithRetry = async <T>(operation: (genAI: GoogleGenerativeAI) => Promise<T>): Promise<T> => {
    let lastError: any;

    // Shuffle keys for simple random load balancing
    const shuffledKeys = [...apiKeys].sort(() => Math.random() - 0.5);

    for (const key of shuffledKeys) {
        try {
            const genAI = new GoogleGenerativeAI(key);
            // Log fewer details in production, but useful here
            // console.log(`🔑 Using API Key ending in ...${key.substring(key.length - 4)}`); 
            return await operation(genAI);
        } catch (error: any) {
            console.warn(`⚠️  Error with key ...${key.substring(key.length - 4)}: ${error.message}`);
            lastError = error;

            // Check for specific errors that warrant a retry (e.g., 429 Too Many Requests)
            // For now, we retry on mostly everything as a robust fallback.
            // If it's a 400 (Bad Request), it might be the prompt, so retrying same prompt on different key won't help, 
            // but for safety we continue the loop.
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
