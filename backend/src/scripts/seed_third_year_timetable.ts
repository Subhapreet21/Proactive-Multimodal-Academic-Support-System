
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

// Subjects from the provided images (Sem 5 & 6 combined), excluding user-specified ones:
// Excluded: Application Development-IOT & ML, Professional Development Skills-2, DSA_Java_Practice, Campus Recruitment Training.
const subjects = [
    // Image 1
    { code: 'CS301', name: 'Agile Software Development' },
    { code: 'CS302', name: 'Artificial Intelligence & Machine Learning' },
    { code: 'CS303', name: 'Compiler Design' },
    { code: 'HRM301', name: 'Human Resource Management' },
    { code: 'CS304', name: 'Internet of Things' },
    { code: 'PDS301', name: 'Professional Development Skills' }, // Kept regular PDS, excluded PDS-2
    { code: 'CS305', name: 'Salesforce Platform Development' },

    // Image 2
    { code: 'CS306', name: 'Cloud Computing' },
    { code: 'CS307', name: 'Cryptography and Network Security' },
    { code: 'CS308', name: 'Data Analytics' },
    { code: 'CS309', name: 'Distributed Operating Systems' },
    { code: 'CS310', name: 'Mobile Application Development' },
    { code: 'CS311', name: 'Recommendation Systems' },
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

const locations = ['Lab 3', 'IoT Lab', 'Room 301', 'Seminar Hall C', 'Room 302', 'Cloud Lab'];

async function seed() {
    console.log('🌱 Seeding 3rd Year Timetable...');

    const adminId = 'de278918-f8e5-46c9-8f3b-5fdfd5beb40e'; // User: Admin Role

    // 1. Clear existing timetable for CSE Year 3 Section A
    await supabase
        .from('timetables')
        .delete()
        .eq('department', 'CSE')
        .eq('year', '3')
        .eq('section', 'A');

    console.log('🗑️ Cleared existing 3rd Year entries.');

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
                year: '3',
                section: 'A'
            });
        }
    }

    // 2. Insert
    const { error: insertError } = await supabase.from('timetables').insert(entries);

    if (insertError) {
        console.error('Error seeding timetable:', insertError);
    } else {
        console.log(`✅ Successfully inserted ${entries.length} timetable entries for 3rd Year.`);
    }
}

seed();
