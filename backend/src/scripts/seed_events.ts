
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

const events = [
    {
        title: 'Semester End Exams',
        description: 'Final examinations for Fall Semester 2025. Verify your hall tickets.',
        event_date: '2026-02-15 09:00:00+00',
        category: 'Academic',
        location: 'Exam Hall Block A',
    },
    {
        title: 'Hackathon 2026',
        description: '24-hour coding marathon. Themes: AI, Blockchain, and IoT.',
        event_date: '2026-01-20 10:00:00+00',
        category: 'Workshop', // Mapped from Technical
        location: 'Innovation Hub',
    },
    {
        title: 'Guest Lecture: AI Ethics',
        description: 'Talk by Dr. A. Smith from Stanford University on the future of Responsible AI.',
        event_date: '2026-01-25 14:00:00+00',
        category: 'Academic',
        location: "Auditorium",
    },
    {
        title: 'Cricket Tournament Finals',
        description: 'Inter-department cricket finals: CSE vs ECE.',
        event_date: '2026-01-28 16:00:00+00',
        category: 'Sports',
        location: 'Main Ground',
    },
    {
        title: 'Placement Drive: Google',
        description: 'On-campus recruitment drive for final year students. Position: Software Engineer.',
        event_date: '2026-02-05 09:00:00+00',
        category: 'Academic', // Mapped from Placement (best fit) or General
        location: 'Placement Cell',
    },
    {
        title: 'Library Closed',
        description: 'Main library will be closed for maintenance on Sunday.',
        event_date: '2026-01-18 00:00:00+00',
        category: 'General', // Mapped from Notice
        location: 'Library',
    },
    {
        title: 'Scholarship Deadline',
        description: 'Last date to submit applications for the Merit Scholarship Program.',
        event_date: '2026-01-30 23:59:00+00',
        category: 'General', // Mapped from Administration
        location: 'Admin Office',
    },
    {
        title: 'Blood Donation Camp',
        description: 'Organized by NSS unit. Be a hero, donate blood.',
        event_date: '2026-02-10 10:00:00+00',
        category: 'Cultural', // Mapped from Social (closest fit in list)
        location: 'Student Center',
    },
    {
        title: 'Workshop: React Native',
        description: 'Hands-on workshop on building mobile apps with React Native.',
        event_date: '2026-02-12 13:00:00+00',
        category: 'Workshop',
        location: 'Lab 4',
    }
];

async function seed() {
    console.log('📢 Seeding Events & Notices...');

    // Use a fixed admin ID for creator if possible, or leave null as per current valid schema
    const adminId = 'de278918-f8e5-46c9-8f3b-5fdfd5beb40e';

    // 1. Clear existing events to prevent duplicates and remove invalid categories
    const { error: deleteError } = await supabase
        .from('events_notices')
        .delete()
        .neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all (using a condition that is always true/matched for non-null ids)

    if (deleteError) {
        console.error('Error clearing events:', deleteError);
    } else {
        console.log('🗑️ Cleared existing events.');
    }

    // Prepare entries
    const entries = events.map(e => ({
        ...e,
        created_by: adminId,
        source_image_url: null // Or valid URLs if we had them
    }));

    const { data, error } = await supabase
        .from('events_notices')
        .insert(entries)
        .select();

    if (error) {
        console.error('Error seeding events:', error);
    } else {
        console.log(`✅ Successfully inserted ${data.length} new events/notices.`);
    }
}

seed();
