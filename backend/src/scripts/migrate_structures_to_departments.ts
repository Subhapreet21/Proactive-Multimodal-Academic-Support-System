import { supabase } from '../services/supabaseClient';

/**
 * Migration Script: Copy Global Structure to All Departments
 * 
 * This script copies the current global timetable structure to all departments
 * to ensure each department starts with the same structure.
 */

const DEPARTMENTS = ['CSE', 'ECE', 'MECH', 'CIVIL', 'EEE', 'IT'];

async function migrateStructuresToDepartments() {
    try {
        console.log('🚀 Starting migration: Copying global structure to all departments...\n');

        // 1. Fetch global structure
        const { data: globalData, error: globalError } = await supabase
            .from('timetable_metadata')
            .select('value')
            .eq('key', 'timetable_structure')
            .single();

        if (globalError) {
            console.error('❌ Error fetching global structure:', globalError);
            return;
        }

        if (!globalData) {
            console.error('❌ No global structure found!');
            return;
        }

        const globalStructure = globalData.value;
        console.log('✅ Global structure fetched:', JSON.stringify(globalStructure, null, 2));
        console.log('');

        // 2. Copy to each department
        for (const dept of DEPARTMENTS) {
            const key = `timetable_structure_${dept}`;
            console.log(`📝 Creating structure for ${dept}...`);

            const { error } = await supabase
                .from('timetable_metadata')
                .upsert({
                    key: key,
                    value: globalStructure,
                    updated_at: new Date()
                }, { onConflict: 'key' });

            if (error) {
                console.error(`   ❌ Error creating ${key}:`, error);
            } else {
                console.log(`   ✅ Created ${key}`);
            }
        }

        console.log('');
        console.log('🎉 Migration complete! All departments now have their own structure.');
        console.log('');
        console.log('📊 Summary:');
        console.log(`   - Global structure: timetable_structure (preserved)`);
        DEPARTMENTS.forEach(dept => {
            console.log(`   - ${dept}: timetable_structure_${dept}`);
        });

    } catch (error) {
        console.error('❌ Migration failed:', error);
    }
}

// Run migration
migrateStructuresToDepartments()
    .then(() => {
        console.log('\n✅ Migration script completed');
        process.exit(0);
    })
    .catch((error) => {
        console.error('\n❌ Migration script failed:', error);
        process.exit(1);
    });
