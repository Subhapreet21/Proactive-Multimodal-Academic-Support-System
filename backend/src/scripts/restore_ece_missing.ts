import { supabase } from '../services/supabaseClient';

/**
 * Restore Script: Re-create Missing ECE Classes at 10:00
 * 
 * Target: ECE Department
 * Slot: 10:00-11:00
 */

const adminId = 'de278918-f8e5-46c9-8f3b-5fdfd5beb40e';
const sections = ['A', 'B', 'C'];
const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

// ECE Specific Rooms (from seed_full_timetable.ts logic)
const roomPools: Record<string, string[]> = {
    '1': ['ECE-101', 'ECE-102', 'ECE-103', 'ECE Physics Lab', 'ECE Chem Lab', 'ECE Workshop'],
    '2': ['ECE-201', 'ECE-202', 'ECE-203', 'ECE Network Lab', 'ECE DBMS Lab', 'ECE Seminar Hall'],
    '3': ['ECE-301', 'ECE-302', 'ECE-303', 'ECE IoT Lab', 'ECE Cloud Lab', 'ECE AI Lab'],
    '4': ['ECE-401', 'ECE-402', 'ECE-403', 'ECE Project Lab', 'ECE Placement Cell', 'ECE Startup Hub']
};

const eceSubjects: Record<string, { code: string, name: string }[]> = {
    '1': [
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
    ],
    '2': [
        { code: 'ECE201', name: 'Analog Circuits' },
        { code: 'ECE202', name: 'Digital Logic Design' },
        { code: 'ECE203', name: 'Signals and Systems' },
        { code: 'MAT201', name: 'Mathematics-3' },
        { code: 'ECE204', name: 'Electromagnetic Fields' },
        { code: 'ECE205', name: 'Network Analysis' },
        { code: 'ECE206', name: 'Linear Integrated Circuits' },
        { code: 'CS201', name: 'Data Structures' },
        { code: 'ECE207', name: 'Pulse and Digital Circuits' },
        { code: 'ECE208', name: 'Antennas and Wave Propagation' }
    ],
    '3': [
        { code: 'ECE301', name: 'Control Systems' },
        { code: 'ECE302', name: 'Microprocessors' },
        { code: 'ECE303', name: 'VLSI Design' },
        { code: 'ECE304', name: 'Digital Signal Processing' },
        { code: 'ECE305', name: 'Communication Systems' },
        { code: 'ECE306', name: 'Microcontrollers' },
        { code: 'ECE307', name: 'Information Theory and Coding' },
        { code: 'ECE308', name: 'Computer Networks' },
        { code: 'ECE309', name: 'Digital Image Processing' },
        { code: 'ECE310', name: 'Optical Communication' }
    ],
    '4': [
        { code: 'ECE401', name: 'Embedded Systems' },
        { code: 'ECE402', name: 'Wireless Communication' },
        { code: 'ECE403', name: 'Satellite Engineering' },
        { code: 'ECE404', name: 'Radar Systems' },
        { code: 'ECE405', name: 'Mobile Computing' },
        { code: 'ECE406', name: 'Microwave Engineering' },
        { code: 'ECE407', name: 'Nano Electronics' },
        { code: 'ECE408', name: 'Bio-Medical Electronics' },
        { code: 'ECE409', name: 'IoT Applications' }
    ]
};

async function restoreECEMissing() {
    try {
        console.log('🔧 Restoring Missing ECE 10:00 classes...\n');

        // 1. Double check if they are missing
        const { count } = await supabase.from('timetables').select('*', { count: 'exact', head: true }).eq('department', 'ECE').eq('start_time', '10:00:00');
        if (count && count > 0) {
            console.log(`⚠️ Data already exists at 10:00! Count: ${count}`);
            // if force overwrite is needed, uncomment below:
            // return;
        }

        const allEntries: any[] = [];
        const slotStart = '10:00';
        const slotEnd = '11:00';

        // Loop through all years
        for (const year of Object.keys(eceSubjects)) {
            const subjects = eceSubjects[year];
            const locations = roomPools[year];

            // New logic: Each section gets dedicated room pairings
            // Same as seed_full_timetable

            for (let sIdx = 0; sIdx < sections.length; sIdx++) {
                const section = sections[sIdx];
                let subjectIterator = sIdx * 3 + 1; // 2nd slot logic
                const roomOffset = sIdx * 2;
                // ECE has 7 slots total but we only care about the absolute slot index for consistency
                // The 2nd *class* slot is Index 1.
                // In generic script, 10:00 is Index 1.

                // Room assignment in generic script:
                // locations[(roomOffset + (i % 2)) % locations.length]
                // i is slot index. 10:00 is i=1 ???
                // Wait, in generic script, slots are filtered class slots.
                // 09:00 (i=0), 10:00 (i=1), 11:10 (i=2)...
                // So at 10:00, i=1.

                const i = 1;

                for (const day of days) {
                    const subject = subjects[subjectIterator % subjects.length];
                    subjectIterator++;

                    const location = locations[(roomOffset + (i % 2)) % locations.length];

                    allEntries.push({
                        user_id: adminId,
                        day_of_week: day,
                        start_time: slotStart,
                        end_time: slotEnd,
                        course_code: subject.code,
                        course_name: subject.name,
                        location: location,
                        department: 'ECE',
                        year: year,
                        section: section
                    });
                }
            }
        }

        console.log(`\n📊 Preparing insert of ${allEntries.length} entries at 10:00...`);
        const { error } = await supabase.from('timetables').insert(allEntries);

        if (error) {
            console.error('❌ Insert failed:', error);
        } else {
            console.log('✅ Successfully restored 10:00 classes.');
        }

    } catch (error) {
        console.error('❌ Script failed:', error);
    }
}

restoreECEMissing()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
