import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
dotenv.config();

const apiKey = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey || "");

async function listModels() {
    try {
        console.log("Checking models for API Key:", apiKey ? "PRESENT" : "MISSING");
        // Note: The newer JS SDK doesn't have a direct listModels on genAI in all versions, 
        // but we can try to fetch it or just try a few fallback models.

        const models = ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-pro", "gemini-1.0-pro"];

        for (const m of models) {
            try {
                const model = genAI.getGenerativeModel({ model: m });
                const result = await model.generateContent("test");
                console.log(`✅ Model ${m} is working.`);
                break;
            } catch (e: any) {
                console.log(`❌ Model ${m} failed: ${e.message}`);
            }
        }
    } catch (error) {
        console.error("List Models Error:", error);
    }
}

listModels();
