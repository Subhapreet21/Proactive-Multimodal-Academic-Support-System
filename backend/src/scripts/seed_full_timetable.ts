
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

const adminId = 'de278918-f8e5-46c9-8f3b-5fdfd5beb40e';
const sections = ['A', 'B', 'C'];
const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

const slots = [
    { start: '09:00:00', end: '10:00:00' },
    { start: '10:00:00', end: '11:00:00' },
    { start: '11:10:00', end: '12:10:00' },
    { start: '13:00:00', end: '14:00:00' },
    { start: '14:00:00', end: '15:00:00' },
];

// Room pools per year to avoid clashes conceptually (though simplified here)
const roomPools: Record<string, string[]> = {
    '1': ['Room 101', 'Room 102', 'Room 103', 'Physics Lab', 'Chem Lab', 'Workshop'],
    '2': ['Room 201', 'Room 202', 'Room 203', 'Network Lab', 'DBMS Lab', 'Seminar Hall'],
    '3': ['Room 301', 'Room 302', 'Room 303', 'IoT Lab', 'Cloud Lab', 'AI Lab'],
    '4': ['Room 401', 'Room 402', 'Room 403', 'Project Lab', 'Placement Cell', 'Startup Hub']
};

// Data Definition
const yearSubjects: Record<string, { code: string, name: string }[]> = {
    '1': [
        { code: 'PHY101', name: 'Applied Physics' },
        { code: 'EEE101', name: 'Basic Electrical and Electronics Engineering' },
        { code: 'ENG101', name: 'English' },
        { code: 'HVP101', name: 'Human Values and Professional Ethics' },
        { code: 'MAT101', name: 'Mathematics-1' },
        { code: 'CS101', name: 'Python Programming' },
        { code: 'CS102', name: 'Adaptive Computer Technologies' },
        { code: 'CS103', name: 'App Development' },
        { code: 'ME101', name: 'Computer Aided Engineering Graphics' },
        { code: 'CS104', name: 'Data Structures' },
        { code: 'MAT102', name: 'Differential and Integral Calculus' },
        { code: 'FIN101', name: 'Financial Institutions Markets and Services' },
        { code: 'FRE101', name: 'French' },
    ],
    '2': [
        { code: 'CN201', name: 'Computer Networks' },
        { code: 'DBMS201', name: 'Database Management System' },
        { code: 'DAA201', name: 'Design and Analysis of Algorithms' },
        { code: 'DM201', name: 'Discrete Mathematics' },
        { code: 'IHE201', name: 'India Heritage and Economy' },
        { code: 'JP201', name: 'Java Programming' },
        { code: 'OOSE201', name: 'Object Oriented Software Engineering' },
        { code: 'ADS201', name: 'Advanced Data Structures' },
        { code: 'COA201', name: 'Computer Organization and Architecture' },
        { code: 'DM202', name: 'Data Mining' },
        { code: 'ENG201', name: 'English for Technical Communication' },
        { code: 'EVS201', name: 'Environmental Sciences' },
        { code: 'MERN201', name: 'MERN Stack Web Development' },
        { code: 'OS201', name: 'Operating Systems' },
        { code: 'PS201', name: 'Probability and Statistics' },
    ],
    '3': [
        { code: 'CS301', name: 'Agile Software Development' },
        { code: 'CS302', name: 'Artificial Intelligence & Machine Learning' },
        { code: 'CS303', name: 'Compiler Design' },
        { code: 'HRM301', name: 'Human Resource Management' },
        { code: 'CS304', name: 'Internet of Things' },
        { code: 'PDS301', name: 'Professional Development Skills' },
        { code: 'CS305', name: 'Salesforce Platform Development' },
        { code: 'CS306', name: 'Cloud Computing' },
        { code: 'CS307', name: 'Cryptography and Network Security' },
        { code: 'CS308', name: 'Data Analytics' },
        { code: 'CS309', name: 'Distributed Operating Systems' },
        { code: 'CS310', name: 'Mobile Application Development' },
        { code: 'CS311', name: 'Recommendation Systems' },
    ],
    '4': [
        { code: 'CS401', name: 'Big Data Analytics' },
        { code: 'CS402', name: 'Deep Learning and its Applications' },
        { code: 'CS403', name: 'Mulesoft Anypoint Platform' },
        { code: 'CS404', name: 'Software Quality Testing' },
        { code: 'CS405', name: 'Startup Innovation and Entrepreneurship' },
        { code: 'HS401', name: 'Career Advancement Skills' },
        { code: 'HS402', name: 'Campus Recruitment Training' },
    ]
};

async function seed() {
    console.log('🌱 Seeding Full Timetable (Years 1-4, Sections A-B-C)...');

    const allEntries: any[] = [];

    for (const year of Object.keys(yearSubjects)) {
        const subjects = yearSubjects[year];
        const locations = roomPools[year];

        // Clear existing data for this department/year first
        await supabase.from('timetables').delete().eq('department', 'CSE').eq('year', year);
        console.log(`🗑️ Cleared Year ${year} (All Sections)`);

        for (let sIdx = 0; sIdx < sections.length; sIdx++) {
            const section = sections[sIdx];
            // Offset subject rotation by section index (e.g. A starts at 0, B at 3, C at 6)
            // This ensures they don't have the same class at the same time.
            let subjectIterator = sIdx * 3;

            // Offset location rotation so they are in different rooms
            // A uses index 0, B uses index 1, etc.
            let locationIterator = sIdx;

            for (const day of days) {
                for (let i = 0; i < slots.length; i++) {
                    const slot = slots[i];
                    const subject = subjects[subjectIterator % subjects.length];
                    subjectIterator++; // Next subject

                    // Simple round-robin for locations
                    const location = locations[locationIterator % locations.length];
                    // Increment location only occasionally or keep fixed per day? 
                    // Let's increment per slot to simulate moving between labs/rooms, 
                    // but ensure it doesn't overlap with another section's logic easily.
                    // To guarantee no clash at this exact slot `i`, we just need to ensure 
                    // `locationIterator` for A != `locationIterator` for B.
                    // Since we started them with offsets (0, 1, 2), and increment them equally, they stay offset.
                    locationIterator++;

                    allEntries.push({
                        user_id: adminId,
                        day_of_week: day,
                        start_time: slot.start,
                        end_time: slot.end,
                        course_code: subject.code,
                        course_name: subject.name,
                        location: location,
                        department: 'CSE',
                        year: year,
                        section: section
                    });
                }
            }
        }
    }

    // Batch insert? Supabase might limit batch size. Let's do chunks of 100 if needed, or just try all.
    // 4 years * 3 sections * 6 days * 5 slots = 360 entries. Valid for single batch.
    const { error } = await supabase.from('timetables').insert(allEntries);

    if (error) {
        console.error('Error Inserting:', error);
    } else {
        console.log(`✅ Successfully inserted ${allEntries.length} entries covering all Years and Sections.`);
    }
}

seed();
