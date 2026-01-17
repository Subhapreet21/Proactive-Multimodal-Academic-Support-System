import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
dotenv.config();

const apiKey = process.env.GEMINI_API_KEY;

// Need to use the REST API to list models if the SDK doesn't expose it easily, 
// but newer SDKs have listModels on the manager. 
// Let's try a direct fetch to the API endpoint to be sure.

async function listModels() {
    if (!apiKey) {
        console.error("No API Key found");
        return;
    }

    try {
        const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`);
        if (!response.ok) {
            console.error(`Failed to list models: ${response.status} ${response.statusText}`);
            const text = await response.text();
            console.error(text);
            return;
        }

        const data = await response.json();
        console.log("AVAILABLE MODELS:");
        data.models.forEach((m: any) => {
            if (m.supportedGenerationMethods.includes('generateContent')) {
                console.log(`- ${m.name.replace('models/', '')} (${m.supportedGenerationMethods.join(', ')})`);
            }
        });
    } catch (error) {
        console.error("Error listing models:", error);
    }
}

listModels();
