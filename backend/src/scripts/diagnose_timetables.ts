import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!);

async function diagnose() {
    // Check ECE-1-A
    const { data, error } = await supabase
        .from('timetables')
        .select('id, day_of_week, start_time, course_code')
        .eq('department', 'ECE')
        .eq('year', '1')
        .eq('section', 'A');

    if (error) { console.error(error); return; }

    // Group by Day
    const distribution: Record<string, number> = {};
    const slots: Record<string, string[]> = {};

    data.forEach(e => {
        const dayKey = e.day_of_week;
        distribution[dayKey] = (distribution[dayKey] || 0) + 1;

        const slotKey = `${e.day_of_week} | ${e.start_time}`;
        if (!slots[slotKey]) slots[slotKey] = [];
        slots[slotKey].push(e.id);
    });

    console.log('--- JSON REPORT ---');
    console.log(JSON.stringify({
        total: data.length,
        distribution,
        slot_duplicates: Object.entries(slots)
            .filter(([k, v]) => v.length > 1)
            .map(([k, v]) => ({ slot: k, count: v.length, ids: v })),
        all_entries: data.map(e => `${e.day_of_week} | ${e.start_time} | ${e.course_code} | ${e.id}`)
    }, null, 2));
}

diagnose();
