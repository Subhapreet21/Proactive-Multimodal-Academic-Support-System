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

            // Randomize the options for each question so correct answer isn't typically first
            quizJson.forEach((q: any) => {
                if (q.options && Array.isArray(q.options)) {
                    for (let i = q.options.length - 1; i > 0; i--) {
                        const j = Math.floor(Math.random() * (i + 1));
                        [q.options[i], q.options[j]] = [q.options[j], q.options[i]];
                    }
                }
            });
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

        // Auto-populate target_department from the creator's profile
        const { data: creatorProfile } = await supabase
            .from('profiles')
            .select('department')
            .eq('id', userId)
            .single();

        if (valid_from) uploadData.valid_from = valid_from;
        if (valid_until) uploadData.valid_until = valid_until;
        if (time_limit_mins !== undefined) uploadData.time_limit_mins = time_limit_mins;
        if (target_year) uploadData.target_year = target_year;
        if (max_attempts !== undefined) uploadData.max_attempts = max_attempts;
        if (is_active !== undefined) uploadData.is_active = is_active;
        if (creatorProfile?.department) uploadData.target_department = creatorProfile.department;

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
        const userId = (req as any).auth?.userId;

        const { data, error } = await supabase
            .from('quizzes')
            .select(`
                *,
                kb_articles ( title ),
                quiz_attempts!left ( id, student_id, quiz_id, score, total_questions, answers, feedback, created_at )
            `)
            .order('created_at', { ascending: false });

        if (error) {
            console.error('[getQuizzes] Fetch Error:', error);
            return res.status(500).json({ error: 'Failed to fetch quizzes.' });
        }

        // Map over data to count attempts specifically for this student
        // and for non-faculty users, filter out inactive or expired quizzes (RLS backup)
        // Also fetch user's profile to enforce year and department matches in-memory
        const userRole = (req as any).auth?.role;
        const isStudent = userRole === 'student';

        let studentProfile: any = null;
        if (isStudent) {
            const { data } = await supabase.from('profiles').select('year, department').eq('id', userId).single();
            studentProfile = data;
        }

        const now = new Date();
        const formattedData = (data as any[]).flatMap(q => {
            // Guard: hide expired, inactive, or un-targeted quizzes for students
            if (isStudent) {
                if (!q.is_active) return [];
                if (q.valid_until && new Date(q.valid_until) < now) return [];

                // Fallback targeted filtering 
                if (studentProfile) {
                    if (q.target_year && q.target_year !== 'All' && q.target_year !== studentProfile.year) return [];
                    if (q.target_department && q.target_department !== 'All' && q.target_department !== studentProfile.department) return [];
                }
            }

            let userAttempts = q.quiz_attempts
                ? (q.quiz_attempts as any[]).filter((att: any) => att.student_id === userId)
                : [];
            userAttempts.sort((a: any, b: any) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());

            return [{
                ...q,
                attempts_count: userAttempts.length,
                last_attempt: userAttempts.length > 0 ? userAttempts[0] : null,
                quiz_attempts: undefined // Clean up the raw join array
            }];
        });

        res.status(200).json(formattedData);
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

// ==========================================
// 8. Generate Personalized AI Overview
// ==========================================
export const generateAIOverview = async (req: Request, res: Response) => {
    try {
        const { id: quiz_id } = req.params;
        const student_id = (req as any).auth.userId;

        // 1. Fetch all attempts by this student for this quiz
        const { data: attempts, error: attemptsError } = await supabase
            .from('quiz_attempts')
            .select('*')
            .eq('quiz_id', quiz_id)
            .eq('student_id', student_id)
            .order('created_at', { ascending: true });

        if (attemptsError || !attempts || attempts.length === 0) {
            return res.status(404).json({ error: 'No attempts found to generate an overview from.' });
        }

        // 2. Fetch the Quiz text mapping to understand the context
        const { data: quiz, error: quizError } = await supabase
            .from('quizzes')
            .select('content, title')
            .eq('id', quiz_id)
            .single();

        if (quizError || !quiz) {
            return res.status(404).json({ error: 'Quiz definition not found.' });
        }

        const questions: QuizQuestion[] = quiz.content;

        // 3. Compile performance record
        let performanceCompilation = `Quiz Title: ${quiz.title}\nTotal Questions: ${questions.length}\n\n`;

        attempts.forEach((attempt, index) => {
            performanceCompilation += `--- Attempt ${index + 1} (Score: ${attempt.score}/${attempt.total_questions}) ---\n`;

            let incorrectThisAttempt: string[] = [];
            attempt.answers.forEach((ans: any) => {
                const q = questions.find(question => question.id === ans.questionId);
                if (q && q.correctAnswer !== ans.selectedOption) {
                    incorrectThisAttempt.push(`Q: "${q.text}". They guessed: "${ans.selectedOption}", but correct is "${q.correctAnswer}". Reason: ${q.explanation}`);
                }
            });

            if (incorrectThisAttempt.length === 0) {
                performanceCompilation += "Perfect Score!\n";
            } else {
                performanceCompilation += "Missed Concepts:\n- " + incorrectThisAttempt.join('\n- ') + "\n";
            }
        });

        // 4. Prompt Gemini for the Overviews
        const systemPrompt = `
You are an expert academic evaluator. You are given a student's history of attempts on a multiple-choice quiz.
You need to generate TWO distinct summaries based on their performance across ALL attempts:
1. "student_summary": An encouraging, 2-line direct message to the student summarizing what they eventually learned or the specific concepts they still struggle with.
2. "faculty_summary": A clinical, actionable, 1-2 sentence report for the professor indicating exact topic gaps the student exhibited.

Return ONLY a JSON object meeting this schema. DO NOT wrap with markdown blocks.`;

        const userPrompt = `Student Performance Log:\n${performanceCompilation}`;

        const config: GenerationConfig = {
            responseMimeType: "application/json",
            responseSchema: {
                type: SchemaType.OBJECT,
                properties: {
                    student_summary: { type: SchemaType.STRING },
                    faculty_summary: { type: SchemaType.STRING }
                },
                required: ["student_summary", "faculty_summary"]
            }
        };

        const geminiText = await generateText(systemPrompt, userPrompt, config);

        // Ensure robust parsing
        let resultJson;
        try {
            const cleaned = geminiText.replace(/```json/g, '').replace(/```/g, '').trim();
            resultJson = JSON.parse(cleaned);
        } catch (e) {
            console.error("Failed to parse Gemini overview:", geminiText);
            return res.status(500).json({ error: 'AI generated invalid insights format.' });
        }

        // 5. Upsert the generated overview, including the latest attempt's score
        const latestAttempt = attempts[attempts.length - 1]; // attempts are sorted ascending
        const { data: upsertData, error: upsertError } = await supabase
            .from('quiz_overviews')
            .upsert({
                quiz_id,
                student_id,
                student_summary: resultJson.student_summary,
                faculty_summary: resultJson.faculty_summary,
                latest_score: latestAttempt.score,
                total_questions: latestAttempt.total_questions,
                updated_at: new Date().toISOString()
            }, { onConflict: 'quiz_id, student_id' } as any)
            .select()
            .single();

        if (upsertError) {
            console.error('[generateAIOverview] Upsert Error:', upsertError);
            return res.status(500).json({ error: 'Failed to save generated AI overview.' });
        }

        res.status(200).json({ message: 'Overview generated successfully.', overview: upsertData });

    } catch (error: any) {
        console.error('[generateAIOverview] General Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

// ==========================================
// 9. Fetch Quiz Overviews
// ==========================================
export const getOverviews = async (req: Request, res: Response) => {
    try {
        const { data, error } = await supabase
            .from('quiz_overviews')
            .select(`
                *,
                quizzes ( title ),
                profiles ( full_name, email, role )
            `)
            .order('updated_at', { ascending: false });

        if (error) {
            console.error('[getOverviews] Fetch Error:', error);
            return res.status(500).json({ error: 'Failed to fetch overviews.' });
        }

        res.status(200).json(data);
    } catch (error: any) {
        console.error('[getOverviews] General Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

