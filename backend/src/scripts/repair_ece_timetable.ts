import { supabase } from '../services/supabaseClient';

/**
 * Comprehensive Repair Script: Fix All ECE Timetable Entries
 * 
 * This script finds and repairs all ECE classes that are at incorrect times
 * due to failed structure migrations.
 */

async function repairAllECETimetables() {
    try {
        console.log('🔧 Starting comprehensive ECE timetable repair...\n');

        // 1. Check what times have classes
        const { data: allClasses, error: fetchError } = await supabase
            .from('timetables')
            .select('id, start_time, end_time, year, section, day_of_week, course_name')
            .eq('department', 'ECE')
            .order('start_time');

        if (fetchError) {
            console.error('❌ Error fetching classes:', fetchError);
            return;
        }

        if (!allClasses || allClasses.length === 0) {
            console.log('⚠️ No ECE classes found');
            return;
        }

        // Group by start time
        const timeGroups: { [key: string]: any[] } = {};
        allClasses.forEach(c => {
            const key = c.start_time;
            if (!timeGroups[key]) timeGroups[key] = [];
            timeGroups[key].push(c);
        });

        console.log('📊 Current ECE class distribution:');
        Object.keys(timeGroups).sort().forEach(time => {
            console.log(`   ${time}: ${timeGroups[time].length} classes`);
        });
        console.log('');

        // 2. Find classes at 10:10 (should be at 10:00)
        const classesAt1010 = allClasses.filter(c => c.start_time === '10:10:00');

        if (classesAt1010.length > 0) {
            console.log(`� Found ${classesAt1010.length} classes at 10:10 that should be at 10:00`);
            console.log('   Sample classes:');
            classesAt1010.slice(0, 3).forEach(c => {
                console.log(`   - Year ${c.year}, Section ${c.section}, ${c.day_of_week}: ${c.course_name}`);
            });

            const ids = classesAt1010.map(c => c.id);
            const { error: updateError } = await supabase
                .from('timetables')
                .update({
                    start_time: '10:00:00',
                    end_time: '11:00:00'
                })
                .in('id', ids);

            if (updateError) {
                console.error('   ❌ Error updating classes:', updateError);
            } else {
                console.log(`   ✅ Moved ${ids.length} classes from 10:10-11:10 to 10:00-11:00`);
            }
        } else {
            console.log('✅ No classes found at 10:10');
        }

        // 3. Verify the fix
        console.log('\n🔍 Verifying repair...');
        const { data: verifyClasses } = await supabase
            .from('timetables')
            .select('start_time')
            .eq('department', 'ECE');

        const verifyGroups: { [key: string]: number } = {};
        verifyClasses?.forEach(c => {
            const key = c.start_time;
            verifyGroups[key] = (verifyGroups[key] || 0) + 1;
        });

        console.log('📊 After repair:');
        Object.keys(verifyGroups).sort().forEach(time => {
            console.log(`   ${time}: ${verifyGroups[time]} classes`);
        });

        console.log('\n🎉 ECE timetable repair complete!');

    } catch (error) {
        console.error('❌ Repair failed:', error);
    }
}

// Run repair
repairAllECETimetables()
    .then(() => {
        console.log('\n✅ Repair script completed');
        process.exit(0);
    })
    .catch((error) => {
        console.error('\n❌ Repair script failed:', error);
        process.exit(1);
    });
