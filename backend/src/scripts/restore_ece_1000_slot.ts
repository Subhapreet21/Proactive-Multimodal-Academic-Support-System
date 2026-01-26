import { supabase } from '../services/supabaseClient';

/**
 * Restore Script: Re-create ECE 10:00-11:00 Classes
 * 
 * This script restores the deleted ECE classes for the 10:00-11:00 slot
 * across all years and sections using the original seed data structure.
 */

const adminId = 'de278918-f8e5-46c9-8f3b-5fdfd5beb40e';
const sections = ['A', 'B', 'C'];
const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

const roomPools: Record<string, string[]> = {
    '1': ['Room 101', 'Room 102', 'Room 103', 'Physics Lab', 'Chem Lab', 'Workshop'],
    '2': ['Room 201', 'Room 202', 'Room 203', 'Network Lab', 'DBMS Lab', 'Seminar Hall'],
    '3': ['Room 301', 'Room 302', 'Room 303', 'IoT Lab', 'Cloud Lab', 'AI Lab'],
    '4': ['Room 401', 'Room 402', 'Room 403', 'Project Lab', 'Placement Cell', 'Startup Hub']
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

async function restoreECE1000Slot() {
    try {
        console.log('🔧 Restoring ECE 10:00-11:00 classes...\n');

        const allEntries: any[] = [];
        const slotStart = '10:00';
        const slotEnd = '11:00';

        // Loop through all years
        for (const year of Object.keys(eceSubjects)) {
            const subjects = eceSubjects[year];
            const locations = roomPools[year];

            console.log(`📝 Processing ECE Year ${year}...`);

            for (let sIdx = 0; sIdx < sections.length; sIdx++) {
                const section = sections[sIdx];

                // Use same logic as seed script to maintain consistency
                // Start from slot index 1 (second slot) since 10:00-11:00 is the second class slot
                let subjectIterator = sIdx * 3 + 1; // +1 for second slot
                let locationIterator = sIdx + 1; // +1 for second slot

                for (const day of days) {
                    const subject = subjects[subjectIterator % subjects.length];
                    const location = locations[locationIterator % locations.length];

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

                    subjectIterator++;
                    locationIterator++;
                }

                console.log(`   ✅ Year ${year}, Section ${section}: ${days.length} classes prepared`);
            }
        }

        console.log(`\n📊 Total classes to insert: ${allEntries.length}`);
        console.log('   Expected: 4 years × 3 sections × 6 days = 72 classes\n');

        // Insert all entries
        const { error } = await supabase.from('timetables').insert(allEntries);

        if (error) {
            console.error('❌ Error inserting classes:', error);
        } else {
            console.log(`✅ Successfully restored ${allEntries.length} ECE classes for 10:00-11:00 slot!`);
        }

        // Verify
        console.log('\n🔍 Verifying restoration...');
        const { data: verifyData } = await supabase
            .from('timetables')
            .select('start_time')
            .eq('department', 'ECE');

        const counts: { [key: string]: number } = {};
        verifyData?.forEach(c => {
            counts[c.start_time] = (counts[c.start_time] || 0) + 1;
        });

        console.log('📊 ECE class distribution after restoration:');
        Object.keys(counts).sort().forEach(time => {
            console.log(`   ${time}: ${counts[time]} classes`);
        });

        console.log('\n🎉 Restoration complete!');

    } catch (error) {
        console.error('❌ Restoration failed:', error);
    }
}

// Run restoration
restoreECE1000Slot()
    .then(() => {
        console.log('\n✅ Restoration script completed');
        process.exit(0);
    })
    .catch((error) => {
        console.error('\n❌ Restoration script failed:', error);
        process.exit(1);
    });
