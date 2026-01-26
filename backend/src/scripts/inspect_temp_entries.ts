import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const supabaseUrl = process.env.SUPABASE_URL!;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!supabaseUrl || !supabaseKey) {
    console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

async function inspect() {
    console.log('🔍 Inspecting ECE-1-A Friday & Saturday...');

    // Fetch Fri/Sat for ECE-1-A
    const { data, error } = await supabase
        .from('timetables')
        .select('*')
        .eq('department', 'ECE')
        .eq('year', '1')
        .eq('section', 'A')
        .in('day_of_week', ['Friday', 'Saturday']);

    if (error) {
        console.error('Error fetching:', error);
        return;
    }

    if (data && data.length > 0) {
        console.log(`📋 FOUND ${data.length} ENTRIES:`);
        data.sort((a, b) => a.start_time.localeCompare(b.start_time));

        data.forEach(e => {
            console.log(` - [${e.day_of_week}] ${e.start_time} - ${e.end_time} : ${e.course_code} (ID: ${e.id})`);
        });
    } else {
        console.log('❌ No entries found for ECE-1-A Fri/Sat.');
    }
}

inspect();
