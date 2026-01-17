
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

// Load env vars
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!; // Use service role to bypass RLS if needed, or ANON if fine.
// ideally use service role for seeding.

if (!supabaseUrl || !supabaseKey) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

const subjects = [
    { code: 'CS401', name: 'Big Data Analytics' },
    { code: 'CS402', name: 'Deep Learning and its Applications' },
    { code: 'CS403', name: 'Mulesoft Anypoint Platform' },
    { code: 'CS404', name: 'Software Quality Testing' },
    { code: 'CS405', name: 'Startup Innovation and Entrepreneurship' },
    { code: 'HS401', name: 'Career Advancement Skills' },
    { code: 'HS402', name: 'Campus Recruitment Training' },
];

const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

// Time slots: 5 classes. 
// 9:00-10:00, 10:00-11:00, (Break 10m), 11:10-12:10, (Lunch 50m), 13:00-14:00, 14:00-15:00.
// Wait, Lunch 12:10 - 13:00 (50 mins). 
// Checks:
// 1. 09:00 - 10:00
// 2. 10:00 - 11:00
// Break 11:00-11:10
// 3. 11:10 - 12:10
// Lunch 12:10-13:00
// 4. 13:00 - 14:00
// 5. 14:00 - 15:00
// Total 5 classes. Fits 9am - 3pm. 

const slots = [
    { start: '09:00:00', end: '10:00:00' },
    { start: '10:00:00', end: '11:00:00' },
    { start: '11:10:00', end: '12:10:00' },
    { start: '13:00:00', end: '14:00:00' },
    { start: '14:00:00', end: '15:00:00' },
];

const locations = ['Room 401', 'Lab 2', 'Room 402', 'Seminar Hall', 'Lab 4'];

async function seed() {
    console.log('🌱 Seeding Timetable...');

    // 1. Find a target user (Student, 4th Year, CSE)
    // For demo, we'll try to find one, or update a specific one.
    // Let's assume we want to seed for the currently logged in user logic, but we don't have that context here.
    // We'll search for a user with email 'student@example.com' or just any student in CSE 4th year.
    // Better: Create a new user or use a hardcoded ID if we know it.
    // Let's just grab the first user who is a student.

    const { data: users, error: userError } = await supabase
        .from('profiles')
        .select('id, email')
        .eq('role', 'student')
        .eq('year', '4')
        .limit(1);

    if (userError || !users?.length) {
        console.error('No 4th Year Student found. Please create one first or update profile.');
        // Fallback: try to find ANY student and update them to 4th year for the demo
        const { data: anyStudent } = await supabase.from('profiles').select('id, email').eq('role', 'student').limit(1);

        if (!anyStudent?.length) {
            console.error('No students found at all.');
            return;
        }

        console.log(`Updating ${anyStudent[0].email} to 4th Year CSE...`);
        await supabase.from('profiles').update({ year: '4', department: 'CSE' }).eq('id', anyStudent[0].id);
        users![0] = anyStudent[0];
    }

    const user = users![0];
    console.log(`Target User (Student Reference): ${user.email} (${user.id})`);

    // Use the Admin ID provided by the user as the Creator
    const adminId = 'de278918-f8e5-46c9-8f3b-5fdfd5beb40e';

    // 2. Clear existing timetable for this specific Class (CSE 4th Year Sec A)
    // We delete by group, not by creator, to ensure no duplicates for the students.
    await supabase
        .from('timetables')
        .delete()
        .eq('department', 'CSE')
        .eq('year', '4')
        .eq('section', 'A');

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
                year: '4',
                section: 'A' // Assume Section A
            });
        }
    }

    // 3. Insert
    const { error: insertError } = await supabase.from('timetables').insert(entries);

    if (insertError) {
        console.error('Error seeding timetable:', insertError);
    } else {
        console.log(`✅ Successfully inserted ${entries.length} timetable entries.`);
    }
}

seed();
