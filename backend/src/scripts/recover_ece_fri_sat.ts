import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import { getActiveStructure } from '../utils/structureHelper';

dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const supabase = createClient(process.env.SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!);

const adminId = 'de278918-f8e5-46c9-8f3b-5fdfd5beb40e';

// ECE Year 1 subjects
const subjects = [
    { code: 'ECE101', name: 'Circuit Theory' },
    { code: 'PHY102', name: 'Semiconductor Physics' },
    { code: 'MAT101', name: 'Mathematics-1' },
    { code: 'ENG101', name: 'English' },
    { code: 'CS101', name: 'Python Programming' },
    { code: 'ECE102', name: 'Electronic Devices and Circuits' },
    { code: 'ME101', name: 'Engineering Graphics' },
    { code: 'CHM101', name: 'Engineering Chemistry' },
    { code: 'EVS101', name: 'Environmental Studies' },
    { code: 'MAT102', name: 'Mathematics-2' }
];

const locations = ['Room 101', 'Room 102', 'Room 103', 'Physics Lab', 'Chem Lab', 'Workshop'];

async function recover() {
    console.log('🔧 Recovering ECE-1-A Friday & Saturday data...');

    // Get structure
    const structure = await getActiveStructure();
    const classSlots = structure.filter((s: any) => s.type === 'class');

    console.log(`Found ${classSlots.length} class slots per day`);

    // Delete existing Fri/Sat for ECE-1-A
    await supabase
        .from('timetables')
        .delete()
        .eq('department', 'ECE')
        .eq('year', '1')
        .eq('section', 'A')
        .in('day_of_week', ['Friday', 'Saturday']);

    console.log('✅ Cleared existing Friday & Saturday entries');

    // Re-create entries
    const entries = [];
    let subjectIdx = 0;
    let locationIdx = 0;

    for (const day of ['Friday', 'Saturday']) {
        for (const slot of classSlots) {
            const subject = subjects[subjectIdx % subjects.length];
            const location = locations[locationIdx % locations.length];

            entries.push({
                user_id: adminId,
                day_of_week: day,
                start_time: slot.start,
                end_time: slot.end,
                course_code: subject.code,
                course_name: subject.name,
                location: location,
                department: 'ECE',
                year: '1',
                section: 'A'
            });

            subjectIdx++;
            locationIdx++;
        }
    }

    const { error } = await supabase.from('timetables').insert(entries);

    if (error) {
        console.error('❌ Error:', error);
    } else {
        console.log(`✅ Successfully restored ${entries.length} entries (${classSlots.length} per day)`);
    }
}

recover();
