
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

// Load environment variables
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
    console.error('❌ Missing Supabase URL or Service Key in .env file');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

const targetUserId = 'faff0393-e6d7-48ce-984c-ca202c7868d1';

// Tasks designed for a 4th Year CSE Student (Major Project, Advanced Subjects)
const tasks = [
    // --- PENDING TASKS (Urgent/Upcoming) ---
    {
        title: 'Major Project Phase 1 Documentation',
        description: 'Finalize the requirement analysis and system architecture diagrams for the capstone project. Submit to guide.',
        category: 'Project',
        due_at: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(), // Due in 2 days
        is_completed: false,
    },
    {
        title: 'Cloud Computing Assignment 2',
        description: 'Write a comparative analysis of AWS Lambda vs Azure Functions. Include code snippets.',
        category: 'Assignment',
        due_at: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000).toISOString(), // Due in 4 days
        is_completed: false,
    },
    {
        title: 'Study for Machine Learning Internal',
        description: 'Revise Unit 3: Support Vector Machines and Decision Trees. Practice numerical problems.',
        category: 'Exam',
        due_at: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000).toISOString(), // Due in 5 days
        is_completed: false,
    },
    {
        title: 'Team Meeting for Capstone',
        description: 'Weekly sync with the team to discuss frontend integration and API blockers.',
        category: 'Project',
        due_at: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000).toISOString(), // Due tomorrow
        is_completed: false,
    },
    {
        title: 'Cyber Security Lab Record',
        description: 'Complete the record for Experiment 5: Packet Sniffing using Wireshark.',
        category: 'Assignment',
        due_at: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(), // Due in 3 days
        is_completed: false,
    },

    // --- COMPLETED TASKS (History) ---
    {
        title: 'Register for Hackathon 2026',
        description: 'Sign up the team "Code_Crunchers" on Devpost. Upload initial idea draft.',
        category: 'General',
        due_at: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(), // Due 2 days ago
        is_completed: true,
    },
    {
        title: 'Submit Internship Report',
        description: 'Upload the signed monthly report for the summer internship at TechCorp.',
        category: 'Assignment',
        due_at: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(), // Due 5 days ago
        is_completed: true,
    },
    {
        title: 'Web Dev Lab Evaluation',
        description: 'Prepare for the external viva on ReactJS components and State Management.',
        category: 'Exam',
        due_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(), // Due 1 day ago
        is_completed: true,
    },
    {
        title: 'Library Book Return',
        description: 'Return "Artificial Intelligence: A Modern Approach" to the central library.',
        category: 'General',
        due_at: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(), // Due 1 week ago
        is_completed: true,
    },
    {
        title: 'Solve LeetCode Weekly Contest',
        description: 'Attempt at least 3 problems from the weekly contest to improve DSA skills.',
        category: 'General',
        due_at: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(), // Due 3 days ago
        is_completed: true,
    }
];

async function seedStudentTasks() {
    console.log(`🌱 Seeding tasks for student: ${targetUserId}...`);

    // 1. Clear existing tasks for this user (Optional, keeps it clean)
    const { error: deleteError } = await supabase
        .from('reminders')
        .delete()
        .eq('user_id', targetUserId);

    if (deleteError) {
        console.error('⚠️ Error clearing existing tasks:', deleteError.message);
    } else {
        console.log('🗑️ Cleared existing tasks for user.');
    }

    // 2. Insert new tasks
    const tasksToInsert = tasks.map(task => ({
        user_id: targetUserId,
        title: task.title,
        description: task.description,
        due_at: task.due_at,
        category: task.category,
        is_completed: task.is_completed,
        created_at: new Date().toISOString(), // Default created_at
    }));

    const { data, error } = await supabase
        .from('reminders')
        .insert(tasksToInsert)
        .select();

    if (error) {
        console.error('❌ Error inserting tasks:', error.message);
    } else {
        console.log(`✅ Successfully inserted ${data.length} tasks!`);
        console.table(data.map(t => ({
            title: t.title,
            category: t.category,
            status: t.is_completed ? '✅ Done' : '⏳ Pending'
        })));
    }
}

seedStudentTasks();
