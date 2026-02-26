import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { generateText } from '../services/aiService';
import { SchemaType, GenerationConfig } from '@google/generative-ai';

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
        const {
            kb_article_id,
            num_questions = 5,
            valid_from,
            valid_until,
            time_limit_mins,
            target_year,
            max_attempts,
            is_active
        } = req.body;
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

        // 2. Construct the concise Prompt and Schema for Gemini
        const systemPrompt = `
Generate a ${num_questions}-question multiple choice quiz testing applied understanding from the text.
Constraints to severely MINIMIZE TOKENS:
1. Make questions and options extremely short and concise.
2. The explanation MUST be 1 very short sentence max.
3. Distractors should be realistic but concise.
`;

        const userPrompt = `
Article Title: ${kbArticle.title}
Article Content:
${kbArticle.content}
`;

        const generationConfig: GenerationConfig = {
            responseMimeType: "application/json",
            responseSchema: {
                type: SchemaType.ARRAY,
                items: {
                    type: SchemaType.OBJECT,
                    properties: {
                        id: { type: SchemaType.STRING, description: "ID e.g. q1" },
                        text: { type: SchemaType.STRING, description: "Concise question text" },
                        options: {
                            type: SchemaType.ARRAY,
                            items: { type: SchemaType.STRING }
                        },
                        correctAnswer: { type: SchemaType.STRING, description: "Exact match to one option" },
                        explanation: { type: SchemaType.STRING, description: "1 short sentence max" }
                    },
                    required: ["id", "text", "options", "correctAnswer", "explanation"]
                }
            }
        };

        // 3. Call Gemini
        console.log(`[generateQuizFromKB] Generating quiz for KB: ${kbArticle.title}...`);
        const geminiResponseText = await generateText(systemPrompt, userPrompt, generationConfig);

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

        const uploadData: any = {
            title,
            description,
            kb_article_id,
            content: quizJson,
            created_by: userId
        };

        if (valid_from) uploadData.valid_from = valid_from;
        if (valid_until) uploadData.valid_until = valid_until;
        if (time_limit_mins !== undefined) uploadData.time_limit_mins = time_limit_mins;
        if (target_year) uploadData.target_year = target_year;
        if (max_attempts !== undefined) uploadData.max_attempts = max_attempts;
        if (is_active !== undefined) uploadData.is_active = is_active;

        const { data: newQuiz, error: insertError } = await supabase
            .from('quizzes')
            .insert(uploadData)
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

export const updateQuiz = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { valid_from, valid_until, time_limit_mins, target_year, max_attempts, is_active } = req.body;
        const userId = (req as any).auth.userId;

        if (!id) return res.status(400).json({ error: 'Quiz ID is required' });

        const updateData: any = {};
        if (valid_from !== undefined) updateData.valid_from = valid_from;
        if (valid_until !== undefined) updateData.valid_until = valid_until;
        if (time_limit_mins !== undefined) updateData.time_limit_mins = time_limit_mins;
        if (target_year !== undefined) updateData.target_year = target_year;
        if (max_attempts !== undefined) updateData.max_attempts = max_attempts;
        if (is_active !== undefined) updateData.is_active = is_active;

        const { data, error } = await supabase
            .from('quizzes')
            .update(updateData)
            .eq('id', id)
            .select()
            .single();

        if (error) {
            console.error('[updateQuiz] Update Error:', error);
            return res.status(500).json({ error: 'Failed to update quiz settings.' });
        }

        return res.status(200).json({ message: 'Quiz updated successfully', quiz: data });
    } catch (error: any) {
        console.error('[updateQuiz] General Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

export const deleteQuiz = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        if (!id) return res.status(400).json({ error: 'Quiz ID is required' });

        const { error } = await supabase
            .from('quizzes')
            .delete()
            .eq('id', id);

        if (error) {
            console.error('[deleteQuiz] Delete Error:', error);
            return res.status(500).json({ error: 'Failed to delete quiz.' });
        }

        return res.status(200).json({ message: 'Quiz deleted successfully' });
    } catch (error: any) {
        console.error('[deleteQuiz] General Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

