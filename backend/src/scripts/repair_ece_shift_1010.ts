import { supabase } from '../services/supabaseClient';

/**
 * Repair Script: Shift ECE Data to Match Structure
 * 
 * The ECE structure currently has classes at 10:10, but data is at 10:00.
 * This script moves the data to 10:10 to align with the structure.
 */

async function repairECEAlignment() {
    try {
        console.log('🔧 Aligning ECE timetable data with structure...\n');

        // 1. Check classes at 10:00
        const { data: classesAt1000, error: fetchError } = await supabase
            .from('timetables')
            .select('id')
            .eq('department', 'ECE')
            .eq('start_time', '10:00:00');

        if (fetchError) {
            console.error('❌ Error fetching classes:', fetchError);
            return;
        }

        if (!classesAt1000 || classesAt1000.length === 0) {
            console.log('⚠️ No ECE classes found at 10:00. Already moved?');
            return;
        }

        console.log(`📝 Found ${classesAt1000.length} classes at 10:00. Moving to 10:10...`);
        const ids = classesAt1000.map(c => c.id);

        const { error: updateError } = await supabase
            .from('timetables')
            .update({
                start_time: '10:10:00',
                end_time: '11:10:00'
            })
            .in('id', ids);

        if (updateError) {
            console.error('❌ Error updating classes:', updateError);
        } else {
            console.log(`✅ Successfully moved ${ids.length} classes to 10:10-11:10`);
        }

    } catch (error) {
        console.error('❌ Repair failed:', error);
    }
}

repairECEAlignment()
    .then(() => {
        console.log('\n✅ Repair script completed');
        process.exit(0);
    })
    .catch((error) => {
        console.error('\n❌ Repair script failed:', error);
        process.exit(1);
    });
