
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

// Subjects from the provided images (Sem 1 & 2 combined)
const subjects = [
    // Sem 1
    { code: 'PHY101', name: 'Applied Physics' },
    { code: 'EEE101', name: 'Basic Electrical and Electronics Engineering' },
    { code: 'ENG101', name: 'English' },
    { code: 'HVP101', name: 'Human Values and Professional Ethics' },
    { code: 'MAT101', name: 'Mathematics-1' },
    { code: 'CS101', name: 'Python Programming' },
    // Sem 2
    { code: 'CS102', name: 'Adaptive Computer Technologies' },
    { code: 'CS103', name: 'App Development' },
    { code: 'ME101', name: 'Computer Aided Engineering Graphics' },
    { code: 'CS104', name: 'Data Structures' },
    { code: 'MAT102', name: 'Differential and Integral Calculus' },
    { code: 'FIN101', name: 'Financial Institutions Markets and Services' },
    { code: 'FRE101', name: 'French' },
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

const locations = ['Room 101', 'Physics Lab', 'Chemistry Lab', 'Workshop A', 'Auditorium', 'Room 102'];

async function seed() {
    console.log('🌱 Seeding 1st Year Timetable...');

    const adminId = 'de278918-f8e5-46c9-8f3b-5fdfd5beb40e'; // User: Admin Role

    // 1. Clear existing timetable for CSE Year 1 Section A
    await supabase
        .from('timetables')
        .delete()
        .eq('department', 'CSE')
        .eq('year', '1')
        .eq('section', 'A');

    console.log('🗑️ Cleared existing 1st Year entries.');

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
                year: '1',
                section: 'A'
            });
        }
    }

    // 2. Insert
    const { error: insertError } = await supabase.from('timetables').insert(entries);

    if (insertError) {
        console.error('Error seeding timetable:', insertError);
    } else {
        console.log(`✅ Successfully inserted ${entries.length} timetable entries for 1st Year.`);
    }
}

seed();
