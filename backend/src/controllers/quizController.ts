import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { generateText } from '../services/aiService';
import { SchemaType, GenerationConfig } from '@google/generative-ai';
import { v4 as uuidv4 } from 'uuid';
import * as xlsx from 'xlsx';

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

        // 1. Resolve user profile (role, year, dept) to strictly enforce student rules
        const { data: profile } = await supabase.from('profiles').select('role, year, department').eq('id', userId).single();
        const isStudent = profile?.role === 'student';
        const studentProfile = profile;

        const now = new Date();
        const formattedData = (data as any[]).flatMap(q => {
            // Guard: hide expired, inactive, or un-targeted quizzes for students
            if (isStudent) {
                if (!q.is_active) return [];
                if (q.valid_until && new Date(q.valid_until) < now) return [];

                // Fallback targeted filtering 
                if (studentProfile) {
                    const qYear = String(q.target_year || '').trim();
                    const sYear = String(studentProfile.year || '').trim();
                    const qDept = String(q.target_department || '').trim();
                    const sDept = String(studentProfile.department || '').trim();

                    if (qYear && qYear !== 'All' && qYear !== sYear) return [];
                    if (qDept && qDept !== 'All' && qDept !== sDept) return [];
                }
            } else {
                // Faculty strictly only see the quizzes they created themselves
                if (q.created_by !== userId) return [];
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

        // 2. Enforce max attempts — count how many attempts this student has already made
        if (quiz.max_attempts !== null && quiz.max_attempts !== undefined) {
            const { count, error: countError } = await supabase
                .from('quiz_attempts')
                .select('id', { count: 'exact', head: true })
                .eq('quiz_id', quiz_id)
                .eq('student_id', userId);

            if (!countError && count !== null && count >= quiz.max_attempts) {
                return res.status(429).json({
                    error: `Maximum attempts (${quiz.max_attempts}) reached. You cannot attempt this quiz again.`
                });
            }
        }

        const questions: QuizQuestion[] = quiz.content;

        // 3. Score the Quiz
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

        // 4. Generate Personalized Nudge (If they missed anything)
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

        // 5. Save Attempt
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

        // 6. Auto-generate faculty AI overview in the background (fire-and-forget)
        // Do NOT await — this must not block the student's result response
        (async () => {
            try {
                // Fetch all attempts by this student for this quiz (including the one just saved)
                const { data: allAttempts } = await supabase
                    .from('quiz_attempts')
                    .select('*')
                    .eq('quiz_id', quiz_id)
                    .eq('student_id', userId)
                    .order('created_at', { ascending: true });

                if (!allAttempts || allAttempts.length === 0) return;

                let performanceCompilation = `Quiz Title: ${quiz.title}\nTotal Questions: ${questions.length}\n\n`;
                allAttempts.forEach((att: any, index: number) => {
                    performanceCompilation += `--- Attempt ${index + 1} (Score: ${att.score}/${att.total_questions}) ---\n`;
                    let incorrectThisAttempt: string[] = [];
                    att.answers.forEach((ans: any) => {
                        const q = questions.find((question: QuizQuestion) => question.id === ans.questionId);
                        if (q && q.correctAnswer !== ans.selectedOption) {
                            incorrectThisAttempt.push(`Q: "${q.text}". They guessed: "${ans.selectedOption}", but correct is "${q.correctAnswer}". Reason: ${q.explanation}`);
                        }
                    });
                    performanceCompilation += incorrectThisAttempt.length === 0
                        ? "Perfect Score!\n"
                        : "Missed Concepts:\n- " + incorrectThisAttempt.join('\n- ') + "\n";
                });

                const sysPrompt = `You are an expert academic evaluator. Generate TWO summaries based on a student's quiz history:
1. "student_summary": A 2-line encouraging message to the student about what they learned or still struggle with.
2. "faculty_summary": A 1-2 sentence clinical report for the professor indicating exact topic gaps.
Return ONLY a JSON object. DO NOT wrap with markdown.`;
                const usrPrompt = `Student Performance Log:\n${performanceCompilation}`;

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

                const geminiText = await generateText(sysPrompt, usrPrompt, config);
                const cleaned = geminiText.replace(/```json/g, '').replace(/```/g, '').trim();
                const resultJson = JSON.parse(cleaned);

                const latestAttempt = allAttempts[allAttempts.length - 1];
                await supabase.from('quiz_overviews').upsert({
                    quiz_id,
                    student_id: userId,
                    student_summary: resultJson.student_summary,
                    faculty_summary: resultJson.faculty_summary,
                    latest_score: latestAttempt.score,
                    total_questions: latestAttempt.total_questions,
                    updated_at: new Date().toISOString()
                }, { onConflict: 'quiz_id, student_id' } as any);

                console.log(`[submitAttempt] Auto faculty overview generated for student ${userId} on quiz ${quiz_id}`);
            } catch (bgError: any) {
                // Silently log — never surface to student
                console.warn('[submitAttempt] Background overview generation failed (non-fatal):', bgError.message);
            }
        })();

        // Return score and AI feedback immediately
        res.status(201).json({ attempt, incorrectQuestions });

    } catch (error: any) {
        console.error('[submitAttempt] General Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};


// Excel Bulk Import & Manual Creation are stubbed for now.
export const importQuizFromExcel = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).auth.userId;
        const file = req.file;

        if (!file) {
            return res.status(400).json({ error: 'No Excel file provided' });
        }

        // 1. Read Excel File
        const workbook = xlsx.read(file.buffer, { type: 'buffer' });
        const sheetName = workbook.SheetNames[0];
        const sheet = workbook.Sheets[sheetName];

        // 2. Parse to JSON
        const rawData: any[] = xlsx.utils.sheet_to_json(sheet);

        if (rawData.length === 0) {
            return res.status(400).json({ error: 'The uploaded file is empty' });
        }

        // 3. Auto-populate Target Department
        const { data: creatorProfile } = await supabase
            .from('profiles')
            .select('department')
            .eq('id', userId)
            .single();

        const defaultDepartment = creatorProfile?.department || 'General';

        // 4. Group rows by `quiz_title`
        const groupedQuizzes: Record<string, any> = {};

        for (const row of rawData) {
            const title = row['quiz_title'];
            if (!title) continue; // Skip strictly empty rows

            if (!groupedQuizzes[title]) {
                // Initialize the Quiz object for this unique title
                groupedQuizzes[title] = {
                    id: uuidv4(),
                    title: title.startsWith('Quiz: ') ? title : `Quiz: ${title}`,
                    description: 'Imported via bulk Excel upload',
                    kb_article_id: null,
                    created_by: userId,
                    is_active: false, // Default to inactive for faculty review
                    time_limit_mins: row['time_limit_mins'] ? parseInt(row['time_limit_mins']) : 15,
                    max_attempts: row['max_attempts'] ? parseInt(row['max_attempts']) : 3,
                    valid_from: row['valid_from (YYYY-MM-DD)'] ? new Date(row['valid_from (YYYY-MM-DD)']).toISOString() : new Date().toISOString(),
                    valid_until: row['valid_until (YYYY-MM-DD)'] ? new Date(row['valid_until (YYYY-MM-DD)']).toISOString() : null,
                    target_year: row['target_year'] ? String(row['target_year']) : 'All',
                    target_department: row['target_department'] || defaultDepartment,
                    content: [] // Store questions here
                };
            }

            // Parse individual question text and options
            const questionText = row['question_text'];
            const option_a = row['option_a'];
            const option_b = row['option_b'];
            const option_c = row['option_c'];
            const option_d = row['option_d'];
            const correctAnswer = row['correct_answer'];
            const explanation = row['explanation'] || '';

            if (questionText && option_a && option_b && correctAnswer) {
                // Valid question row
                const options = [option_a, option_b];
                if (option_c) options.push(option_c);
                if (option_d) options.push(option_d);

                groupedQuizzes[title].content.push({
                    id: uuidv4(),
                    text: questionText,
                    options: options,
                    explanation: explanation,
                    correctAnswer: correctAnswer
                });
            }
        }

        const formattedQuizzesArray = Object.values(groupedQuizzes);

        if (formattedQuizzesArray.length === 0) {
            return res.status(400).json({ error: 'Could not parse any valid quizzes from the file. Please ensure you are strictly following the provided template schema.' });
        }

        // 5. Bulk Insert into Supabase
        const { data, error } = await supabase
            .from('quizzes')
            .insert(formattedQuizzesArray)
            .select();

        if (error) {
            console.error('[importQuizFromExcel] Supabase Insertion Error:', error);
            return res.status(500).json({ error: 'Failed to insert parsed quizzes into the database.' });
        }

        return res.status(201).json({
            message: `Successfully imported ${formattedQuizzesArray.length} quizzes. They are currently drafted as Inactive.`,
            quizzes: data
        });

    } catch (error: any) {
        console.error('[importQuizFromExcel] Parsing general error:', error.message);
        res.status(500).json({ error: 'Failed to process Excel file. Please check file format.' });
    }
}

export const manualQuizCreation = async (req: Request, res: Response) => {
    try {
        const userId = (req as any).auth.userId;
        const {
            title,
            description,
            time_limit_mins,
            max_attempts,
            valid_from,
            valid_until,
            target_year,
            target_department,
            is_active,
            content,
        } = req.body;

        // ── Validate required fields ──────────────
        if (!title || !content || !Array.isArray(content) || content.length === 0) {
            return res.status(400).json({ error: 'Quiz title and at least one question are required.' });
        }

        if (!valid_from || !valid_until) {
            return res.status(400).json({ error: 'valid_from and valid_until dates are required.' });
        }

        // ── Enrich the content array with IDs ─────
        const enrichedContent = content.map((q: any) => ({
            id: uuidv4(),
            text: q.text,
            options: q.options,
            correctAnswer: q.correctAnswer,
            explanation: q.explanation || '',
        }));

        const now = new Date().toISOString();

        const quizRecord = {
            id: uuidv4(),
            title,
            description: description || 'Manually created quiz by faculty.',
            kb_article_id: null,
            created_by: userId,
            is_active: is_active ?? false,
            time_limit_mins: time_limit_mins ?? 15,
            max_attempts: max_attempts ?? 3,
            valid_from: new Date(valid_from).toISOString(),
            valid_until: new Date(valid_until).toISOString(),
            target_year: target_year ?? 'All',
            target_department: target_department ?? 'General',
            content: enrichedContent,
            created_at: now,
            updated_at: now,
        };

        const { data, error } = await supabase
            .from('quizzes')
            .insert([quizRecord])
            .select()
            .single();

        if (error) {
            console.error('[manualQuizCreation] Supabase error:', error);
            return res.status(500).json({ error: 'Failed to save quiz to the database.' });
        }

        return res.status(201).json({
            message: `Quiz "${title}" ${is_active ? 'published' : 'saved as draft'} successfully.`,
            quiz: data,
        });

    } catch (error: any) {
        console.error('[manualQuizCreation] Error:', error.message);
        res.status(500).json({ error: 'An unexpected error occurred while creating the quiz.' });
    }
}

export const updateQuiz = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const {
            title,
            description,
            valid_from,
            valid_until,
            time_limit_mins,
            target_year,
            max_attempts,
            is_active,
            content
        } = req.body;
        const userId = (req as any).auth.userId;

        if (!id) return res.status(400).json({ error: 'Quiz ID is required' });

        const updateData: any = {
            updated_at: new Date().toISOString()
        };

        if (title !== undefined) updateData.title = title;
        if (description !== undefined) updateData.description = description;
        if (valid_from !== undefined) updateData.valid_from = valid_from;
        if (valid_until !== undefined) updateData.valid_until = valid_until;
        if (time_limit_mins !== undefined) updateData.time_limit_mins = time_limit_mins;
        if (target_year !== undefined) updateData.target_year = target_year;
        if (max_attempts !== undefined) updateData.max_attempts = max_attempts;
        if (is_active !== undefined) updateData.is_active = is_active;

        if (content !== undefined && Array.isArray(content)) {
            // Ensure each question has a UUID
            updateData.content = content.map((q: any) => ({
                id: q.id || uuidv4(),
                text: q.text,
                options: q.options,
                correctAnswer: q.correctAnswer,
                explanation: q.explanation || '',
            }));
        }

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
        const userId = (req as any).auth?.userId;

        // 1. Fetch user's profile to understand their role/department
        const { data: profileData, error: profileError } = await supabase
            .from('profiles')
            .select('role, department')
            .eq('id', userId)
            .single();

        if (profileError || !profileData) {
            return res.status(403).json({ error: 'Unauthorized to access overviews.' });
        }

        const isStudent = profileData.role === 'student';
        const userDepartment = profileData.department;

        // 2. Fetch overviews and their joined profiles
        const { data, error } = await supabase
            .from('quiz_overviews')
            .select(`
                *,
                quizzes ( title ),
                profiles ( full_name, email, role, department )
            `)
            .order('updated_at', { ascending: false });

        if (error) {
            console.error('[getOverviews] Fetch Error:', error);
            return res.status(500).json({ error: 'Failed to fetch overviews.' });
        }

        // 3. Filter the overviews based on role
        const filteredData = (data as any[]).filter(overview => {
            if (isStudent) {
                // Students only see their own overviews
                return overview.student_id === userId;
            } else {
                // Faculty only see overviews for students in their own department
                // Fallback to true if department isn't perfectly mapped, but strictly filter if it exists
                const studentDept = overview.profiles?.department;
                if (!userDepartment || userDepartment === 'All') return true; // generic faculty
                return studentDept === userDepartment;
            }
        });

        res.status(200).json(filteredData);
    } catch (error: any) {
        console.error('[getOverviews] General Error:', error.message);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

