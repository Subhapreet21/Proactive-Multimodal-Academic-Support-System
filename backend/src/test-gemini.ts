import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
dotenv.config();

const apiKey = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey || "");

async function testModel(modelName: string) {
    try {
        console.log(`Testing model: ${modelName}...`);
        const model = genAI.getGenerativeModel({ model: modelName });
        const result = await model.generateContent("Hello, are you working?");
        console.log(`✅ ${modelName} is WORKING.`);
        // console.log(result.response.text());
        return true;
    } catch (error: any) {
        console.error(`❌ ${modelName} FAILED: ${error.message}`);
        return false;
    }
}

async function runTests() {
    console.log("Checking API Key availability...");
    await testModel("gemini-1.5-flash");
    await testModel("gemini-pro");
    await testModel("gemini-1.0-pro");
}

runTests();
