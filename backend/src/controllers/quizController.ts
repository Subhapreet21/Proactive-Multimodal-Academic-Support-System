import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { generateText } from '../services/aiService';

// Interfaces for our JSONB structure
interface QuizQuestion {
    id: string; // Unique ID per question (e.g., q1, q2)
    text: string;
    options: string[];
    correctAnswer: string;
    explanation: string;
}

export const generateQuizFromKB = async (req: Request, res: Response) => {
    try {
        const { kb_article_id, num_questions = 5 } = req.body;
        const userId = (req as any).auth.userId; // From authMiddleware

        if (!kb_article_id) {
            return res.status(400).json({ error: 'kb_article_id is required' });
        }

        // 1. Fetch the KB Article
        const { data: kbArticle, error: kbError } = await supabase
            .from('kb_articles')
            .select('title, content')
            .eq('id', kb_article_id)
            .single();

        if (kbError || !kbArticle) {
            console.error('[generateQuizFromKB] KB fetch error:', kbError);
            return res.status(404).json({ error: 'Knowledge Base article not found.' });
        }

        // 2. Construct the Prompt for Gemini
        const systemPrompt = `
You are an expert university professor creating an adaptive assessment.
Your task is to generate a ${num_questions}-question multiple choice quiz based strictly on the provided text.

The quiz must be research-worthy and adaptive:
1. Do NOT just make simple "What is X?" questions. Test applied understanding.
2. Dynamic Distractor Generation: The wrong Options MUST be plausible misconceptions that a student might actually believe. Do not use obvious throwaway fake answers.
3. Every question must have an explanation for WHY the correct answer is right and why the distractors are wrong based on the text.

Output exactly a JSON array of ${num_questions} objects, with NO markdown formatting, NO backticks. Follow this exact schema:
[
  {
    "id": "q1",
    "text": "The question text here?",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswer": "Option A",
    "explanation": "Option A is correct because..."
  }
]
`;

        const userPrompt = `
Article Title: ${kbArticle.title}
Article Content:
${kbArticle.content}
`;

        // 3. Call Gemini
        console.log(`[generateQuizFromKB] Generating quiz for KB: ${kbArticle.title}...`);
        const geminiResponseText = await generateText(systemPrompt, userPrompt);

        let quizJson = [];
        try {
            // Clean up backticks in case Gemini ignores instructions
            const cleanedText = geminiResponseText.replace(/```json/g, '').replace(/```/g, '').trim();
            quizJson = JSON.parse(cleanedText);
        } catch (e) {
            console.error('[generateQuizFromKB] Failed to parse JSON from AI:', geminiResponseText);
            return res.status(500).json({ error: 'AI failed to generate a valid quiz format.' });
        }

        // 4. Save to Database
        const title = `Quiz: ${kbArticle.title}`;
        const description = `AI Generated assessment from the knowledge base article.`;

        const { data: newQuiz, error: insertError } = await supabase
            .from('quizzes')
            .insert({
                title,
                description,
                kb_article_id,
                content: quizJson,
                created_by: userId
            })
            .select()
            .single();

        if (insertError) {
            console.error('[generateQuizFromKB] Quiz Insert Error:', insertError);
            return res.status(500).json({ error: 'Failed to save generated quiz.' });
        }

        return res.status(201).json({ message: 'Quiz generated successfully', quiz: newQuiz });

    } catch (error: any) {
        console.error('[generateQuizFromKB] General Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

export const getQuizzes = async (req: Request, res: Response) => {
    try {
        const { data, error } = await supabase
            .from('quizzes')
            .select(`
                *,
                kb_articles ( title )
            `)
            .order('created_at', { ascending: false });

        if (error) {
            console.error('[getQuizzes] Fetch Error:', error);
            return res.status(500).json({ error: 'Failed to fetch quizzes.' });
        }

        res.status(200).json(data);
    } catch (error: any) {
        console.error('[getQuizzes] General Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

export const submitAttempt = async (req: Request, res: Response) => {
    try {
        const { quiz_id, answers } = req.body;
        const userId = (req as any).auth.userId;

        if (!quiz_id || !answers || !Array.isArray(answers)) {
            return res.status(400).json({ error: 'quiz_id and an array of answers are required' });
        }

        // 1. Fetch the Quiz
        const { data: quiz, error: quizError } = await supabase
            .from('quizzes')
            .select('*')
            .eq('id', quiz_id)
            .single();

        if (quizError || !quiz) {
            return res.status(404).json({ error: 'Quiz not found' });
        }

        const questions: QuizQuestion[] = quiz.content;

        // 2. Score the Quiz
        let score = 0;
        let incorrectQuestions: any[] = [];

        answers.forEach((userAnswer: { questionId: string, selectedOption: string }) => {
            const question = questions.find(q => q.id === userAnswer.questionId);
            if (question) {
                if (question.correctAnswer === userAnswer.selectedOption) {
                    score++;
                } else {
                    incorrectQuestions.push({
                        question: question.text,
                        selected: userAnswer.selectedOption,
                        correct: question.correctAnswer,
                        explanation: question.explanation
                    });
                }
            }
        });

        // 3. Generate Personalized Nudge (If they missed anything)
        let feedback = "Excellent work! You got everything correct.";
        if (incorrectQuestions.length > 0) {
            const systemPrompt = `You are an academic advisor analyzing a student's quiz performance. 
             They missed ${incorrectQuestions.length} questions out of ${questions.length}.
             Identify the "Knowledge Gaps" based on the questions they got wrong. 
             Provide a short, encouraging 2-sentence nudge explicitly telling them what concepts they need to revise. Do not use markdown headers just return the plain string.`;

            const userPrompt = `Incorrect Questions Data: ${JSON.stringify(incorrectQuestions)}`;

            try {
                feedback = await generateText(systemPrompt, userPrompt);
            } catch (aiError) {
                console.error('[submitAttempt] AI Feedback error, falling back:', aiError);
                feedback = "You missed some questions. Review the exact explanations provided below.";
            }
        }

        // 4. Save Attempt
        const { data: attempt, error: attemptError } = await supabase
            .from('quiz_attempts')
            .insert({
                quiz_id,
                student_id: userId,
                score,
                total_questions: questions.length,
                answers,
                feedback
            })
            .select()
            .single();

        if (attemptError) {
            console.error('[submitAttempt] Error saving attempt:', attemptError);
            return res.status(500).json({ error: 'Failed to save quiz attempt' });
        }

        // Return score and AI feedback immediately
        res.status(201).json({ attempt, incorrectQuestions });

    } catch (error: any) {
        console.error('[submitAttempt] General Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

// Excel Bulk Import & Manual Creation are stubbed for now.
export const importQuizFromExcel = async (req: Request, res: Response) => {
    res.status(501).json({ message: "Excel import parsing logic goes here." });
}

export const manualQuizCreation = async (req: Request, res: Response) => {
    res.status(501).json({ message: "Manual creation saving logic goes here." });
}
