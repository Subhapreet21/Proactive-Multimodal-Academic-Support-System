import { generateText } from './src/services/aiService';

async function testGemini() {
    try {
        console.log("Testing Gemini API...");
        const response = await generateText("What is the capital of France?", "Just answer with a single word.");
        console.log("Response:", response);
    } catch (err) {
        console.error("Gemini test failed:", err);
    }
}

testGemini();
