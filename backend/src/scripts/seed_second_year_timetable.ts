
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

// Load env vars
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseKey) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Subjects from the provided images (Sem 3 & 4 combined), excluding user-specified ones
const subjects = [
    // Image 1
    { code: 'CN201', name: 'Computer Networks' },
    { code: 'DBMS201', name: 'Database Management System' },
    { code: 'DAA201', name: 'Design and Analysis of Algorithms' },
    { code: 'DM201', name: 'Discrete Mathematics' },
    { code: 'IHE201', name: 'India Heritage and Economy' },
    { code: 'JP201', name: 'Java Programming' },
    { code: 'OOSE201', name: 'Object Oriented Software Engineering' },

    // Image 2
    { code: 'ADS201', name: 'Advanced Data Structures' },
    { code: 'COA201', name: 'Computer Organization and Architecture' },
    { code: 'DM202', name: 'Data Mining' },
    { code: 'ENG201', name: 'English for Technical Communication and Employability Skills' },
    { code: 'EVS201', name: 'Environmental Sciences' },
    { code: 'MERN201', name: 'MERN Stack Web Development' },
    { code: 'OS201', name: 'Operating Systems' },
    { code: 'PS201', name: 'Probability and Statistics' },
];

const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

// Time slots: 5 classes. 9:00-3:00 layout
const slots = [
    { start: '09:00:00', end: '10:00:00' },
    { start: '10:00:00', end: '11:00:00' },
    { start: '11:10:00', end: '12:10:00' }, // Post-break
    { start: '13:00:00', end: '14:00:00' }, // Post-lunch
    { start: '14:00:00', end: '15:00:00' },
];

const locations = ['Room 201', 'Network Lab', 'DBMS Lab', 'Seminar Hall B', 'Room 202', 'Java Lab'];

async function seed() {
    console.log('🌱 Seeding 2nd Year Timetable...');

    const adminId = 'de278918-f8e5-46c9-8f3b-5fdfd5beb40e'; // User: Admin Role

    // 1. Clear existing timetable for CSE Year 2 Section A
    await supabase
        .from('timetables')
        .delete()
        .eq('department', 'CSE')
        .eq('year', '2')
        .eq('section', 'A');

    console.log('🗑️ Cleared existing 2nd Year entries.');

    const entries: any[] = [];
    let subjectIdx = 0;

    for (const day of days) {
        for (let i = 0; i < slots.length; i++) {
            const slot = slots[i];
            const subject = subjects[subjectIdx % subjects.length];
            subjectIdx++; // Rotate subjects

            entries.push({
                user_id: adminId, // Created by Admin
                day_of_week: day,
                start_time: slot.start,
                end_time: slot.end,
                course_code: subject.code,
                course_name: subject.name,
                location: locations[i % locations.length],
                department: 'CSE',
                year: '2',
                section: 'A'
            });
        }
    }

    // 2. Insert
    const { error: insertError } = await supabase.from('timetables').insert(entries);

    if (insertError) {
        console.error('Error seeding timetable:', insertError);
    } else {
        console.log(`✅ Successfully inserted ${entries.length} timetable entries for 2nd Year.`);
    }
}

seed();
