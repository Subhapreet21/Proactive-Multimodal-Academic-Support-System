import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import { getActiveStructure } from '../utils/structureHelper';

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

// Room pools per department and year - Each department has its own building
const roomPools: Record<string, Record<string, string[]>> = {
    'CSE': {
        '1': ['CSE-101', 'CSE-102', 'CSE-103', 'CSE Physics Lab', 'CSE Chem Lab', 'CSE Workshop'],
        '2': ['CSE-201', 'CSE-202', 'CSE-203', 'CSE Network Lab', 'CSE DBMS Lab', 'CSE Seminar Hall'],
        '3': ['CSE-301', 'CSE-302', 'CSE-303', 'CSE IoT Lab', 'CSE Cloud Lab', 'CSE AI Lab'],
        '4': ['CSE-401', 'CSE-402', 'CSE-403', 'CSE Project Lab', 'CSE Placement Cell', 'CSE Startup Hub']
    },
    'ECE': {
        '1': ['ECE-101', 'ECE-102', 'ECE-103', 'ECE Physics Lab', 'ECE Electronics Lab', 'ECE Workshop'],
        '2': ['ECE-201', 'ECE-202', 'ECE-203', 'ECE Circuits Lab', 'ECE Digital Lab', 'ECE Seminar Hall'],
        '3': ['ECE-301', 'ECE-302', 'ECE-303', 'ECE VLSI Lab', 'ECE Communication Lab', 'ECE DSP Lab'],
        '4': ['ECE-401', 'ECE-402', 'ECE-403', 'ECE Embedded Lab', 'ECE Microwave Lab', 'ECE Project Lab']
    },
    'EEE': {
        '1': ['EEE-101', 'EEE-102', 'EEE-103', 'EEE Physics Lab', 'EEE Electrical Lab', 'EEE Workshop'],
        '2': ['EEE-201', 'EEE-202', 'EEE-203', 'EEE Machines Lab', 'EEE Measurements Lab', 'EEE Seminar Hall'],
        '3': ['EEE-301', 'EEE-302', 'EEE-303', 'EEE Power Electronics Lab', 'EEE Control Lab', 'EEE HV Lab'],
        '4': ['EEE-401', 'EEE-402', 'EEE-403', 'EEE Smart Grid Lab', 'EEE Drives Lab', 'EEE Project Lab']
    },
    'ME': {
        '1': ['ME-101', 'ME-102', 'ME-103', 'ME Physics Lab', 'ME Workshop-1', 'ME Drawing Hall'],
        '2': ['ME-201', 'ME-202', 'ME-203', 'ME Strength Lab', 'ME Thermal Lab', 'ME Seminar Hall'],
        '3': ['ME-301', 'ME-302', 'ME-303', 'ME CAD Lab', 'ME Metrology Lab', 'ME Dynamics Lab'],
        '4': ['ME-401', 'ME-402', 'ME-403', 'ME FEA Lab', 'ME Robotics Lab', 'ME Project Lab']
    },
    'CE': {
        '1': ['CE-101', 'CE-102', 'CE-103', 'CE Physics Lab', 'CE Materials Lab', 'CE Drawing Hall'],
        '2': ['CE-201', 'CE-202', 'CE-203', 'CE Surveying Lab', 'CE Concrete Lab', 'CE Seminar Hall'],
        '3': ['CE-301', 'CE-302', 'CE-303', 'CE Structures Lab', 'CE Geotechnical Lab', 'CE Hydraulics Lab'],
        '4': ['CE-401', 'CE-402', 'CE-403', 'CE CAD Lab', 'CE Transportation Lab', 'CE Project Lab']
    },
    'IT': {
        '1': ['IT-101', 'IT-102', 'IT-103', 'IT Physics Lab', 'IT Programming Lab', 'IT Workshop'],
        '2': ['IT-201', 'IT-202', 'IT-203', 'IT Data Structures Lab', 'IT DBMS Lab', 'IT Seminar Hall'],
        '3': ['IT-301', 'IT-302', 'IT-303', 'IT Cloud Lab', 'IT Security Lab', 'IT Mobile Dev Lab'],
        '4': ['IT-401', 'IT-402', 'IT-403', 'IT ML Lab', 'IT Big Data Lab', 'IT Project Lab']
    }
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

const departments = ['CSE', 'ECE', 'EEE', 'ME', 'CE', 'IT'];

// Subject Definitions per Dept & Year
const deptSubjects: Record<string, Record<string, { code: string, name: string }[]>> = {
    'CSE': yearSubjects, // Use existing CSE list
    'ECE': {
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
    },
    'EEE': {
        '1': [
            { code: 'EEE101', name: 'Basic Electrical Engineering' },
            { code: 'PHY101', name: 'Engineering Physics' },
            { code: 'MAT101', name: 'Mathematics-1' },
            { code: 'CHM101', name: 'Engineering Chemistry' },
            { code: 'ENG101', name: 'English' },
            { code: 'ME101', name: 'Engineering Graphics' },
            { code: 'CS101', name: 'Programming for Problem Solving' },
            { code: 'EEE102', name: 'Electrical Circuit Analysis' },
            { code: 'MAT102', name: 'Mathematics-2' }
        ],
        '2': [
            { code: 'EEE201', name: 'Electrical Machines-1' },
            { code: 'EEE202', name: 'Network Analysis' },
            { code: 'EEE203', name: 'Electromagnetic Fields' },
            { code: 'MAT201', name: 'Mathematics-3' },
            { code: 'EEE204', name: 'Analog Electronics' },
            { code: 'EEE205', name: 'Electrical Measurements' },
            { code: 'EEE206', name: 'Power Systems-1' },
            { code: 'EEE207', name: 'Control Systems' },
            { code: 'CS201', name: 'Data Structures' }
        ],
        '3': [
            { code: 'EEE301', name: 'Electrical Machines-2' },
            { code: 'EEE302', name: 'Power Electronics' },
            { code: 'EEE303', name: 'Power Systems-2' },
            { code: 'EEE304', name: 'Microprocessors and Microcontrollers' },
            { code: 'EEE305', name: 'Digital Signal Processing' },
            { code: 'EEE306', name: 'High Voltage Engineering' },
            { code: 'EEE307', name: 'Renewable Energy Systems' },
            { code: 'EEE308', name: 'Electrical Machine Design' }
        ],
        '4': [
            { code: 'EEE401', name: 'Power System Protection' },
            { code: 'EEE402', name: 'HVDC Transmission' },
            { code: 'EEE403', name: 'Electric Drives' },
            { code: 'EEE404', name: 'Smart Grid Technology' },
            { code: 'EEE405', name: 'Power Quality' },
            { code: 'EEE406', name: 'Energy Management' },
            { code: 'EEE407', name: 'Industrial Automation' }
        ]
    },
    'ME': {
        '1': [
            { code: 'ME101', name: 'Engineering Graphics' },
            { code: 'PHY101', name: 'Engineering Physics' },
            { code: 'MAT101', name: 'Mathematics-1' },
            { code: 'CHM101', name: 'Engineering Chemistry' },
            { code: 'ENG101', name: 'English' },
            { code: 'ME102', name: 'Engineering Mechanics' },
            { code: 'CS101', name: 'Programming for Problem Solving' },
            { code: 'ME103', name: 'Manufacturing Processes' },
            { code: 'MAT102', name: 'Mathematics-2' }
        ],
        '2': [
            { code: 'ME201', name: 'Strength of Materials' },
            { code: 'ME202', name: 'Thermodynamics' },
            { code: 'ME203', name: 'Fluid Mechanics' },
            { code: 'MAT201', name: 'Mathematics-3' },
            { code: 'ME204', name: 'Material Science' },
            { code: 'ME205', name: 'Kinematics of Machinery' },
            { code: 'ME206', name: 'Manufacturing Technology' },
            { code: 'EEE201', name: 'Basic Electrical Engineering' },
            { code: 'ME207', name: 'Engineering Drawing' }
        ],
        '3': [
            { code: 'ME301', name: 'Heat Transfer' },
            { code: 'ME302', name: 'Machine Design' },
            { code: 'ME303', name: 'Dynamics of Machinery' },
            { code: 'ME304', name: 'Thermal Engineering' },
            { code: 'ME305', name: 'Metrology and Measurements' },
            { code: 'ME306', name: 'Computer Aided Design' },
            { code: 'ME307', name: 'Automobile Engineering' },
            { code: 'ME308', name: 'Industrial Engineering' }
        ],
        '4': [
            { code: 'ME401', name: 'Finite Element Analysis' },
            { code: 'ME402', name: 'Robotics and Automation' },
            { code: 'ME403', name: 'Refrigeration and Air Conditioning' },
            { code: 'ME404', name: 'Composite Materials' },
            { code: 'ME405', name: 'Additive Manufacturing' },
            { code: 'ME406', name: 'Mechatronics' },
            { code: 'ME407', name: 'Energy Systems' }
        ]
    },
    'CE': {
        '1': [
            { code: 'CE101', name: 'Engineering Mechanics' },
            { code: 'PHY101', name: 'Engineering Physics' },
            { code: 'MAT101', name: 'Mathematics-1' },
            { code: 'CHM101', name: 'Engineering Chemistry' },
            { code: 'ENG101', name: 'English' },
            { code: 'CE102', name: 'Building Materials and Construction' },
            { code: 'ME101', name: 'Engineering Graphics' },
            { code: 'CS101', name: 'Programming for Problem Solving' },
            { code: 'MAT102', name: 'Mathematics-2' }
        ],
        '2': [
            { code: 'CE201', name: 'Strength of Materials' },
            { code: 'CE202', name: 'Surveying' },
            { code: 'CE203', name: 'Fluid Mechanics' },
            { code: 'MAT201', name: 'Mathematics-3' },
            { code: 'CE204', name: 'Structural Analysis' },
            { code: 'CE205', name: 'Geotechnical Engineering' },
            { code: 'CE206', name: 'Environmental Engineering' },
            { code: 'EEE201', name: 'Basic Electrical Engineering' },
            { code: 'CE207', name: 'Concrete Technology' }
        ],
        '3': [
            { code: 'CE301', name: 'Design of Concrete Structures' },
            { code: 'CE302', name: 'Design of Steel Structures' },
            { code: 'CE303', name: 'Transportation Engineering' },
            { code: 'CE304', name: 'Water Resources Engineering' },
            { code: 'CE305', name: 'Foundation Engineering' },
            { code: 'CE306', name: 'Construction Management' },
            { code: 'CE307', name: 'Hydraulic Engineering' },
            { code: 'CE308', name: 'Earthquake Engineering' }
        ],
        '4': [
            { code: 'CE401', name: 'Advanced Structural Design' },
            { code: 'CE402', name: 'Bridge Engineering' },
            { code: 'CE403', name: 'Pavement Design' },
            { code: 'CE404', name: 'Green Building Technology' },
            { code: 'CE405', name: 'Coastal Engineering' },
            { code: 'CE406', name: 'Quantity Surveying' },
            { code: 'CE407', name: 'Infrastructure Planning' }
        ]
    },
    'IT': {
        '1': [
            { code: 'IT101', name: 'Introduction to Information Technology' },
            { code: 'PHY101', name: 'Engineering Physics' },
            { code: 'MAT101', name: 'Mathematics-1' },
            { code: 'ENG101', name: 'English' },
            { code: 'CS101', name: 'Programming in C' },
            { code: 'IT102', name: 'Digital Logic Design' },
            { code: 'ME101', name: 'Engineering Graphics' },
            { code: 'CHM101', name: 'Engineering Chemistry' },
            { code: 'MAT102', name: 'Mathematics-2' }
        ],
        '2': [
            { code: 'IT201', name: 'Data Structures' },
            { code: 'IT202', name: 'Object Oriented Programming' },
            { code: 'IT203', name: 'Database Management Systems' },
            { code: 'MAT201', name: 'Discrete Mathematics' },
            { code: 'IT204', name: 'Computer Networks' },
            { code: 'IT205', name: 'Operating Systems' },
            { code: 'IT206', name: 'Web Technologies' },
            { code: 'IT207', name: 'Software Engineering' },
            { code: 'EEE201', name: 'Basic Electronics' }
        ],
        '3': [
            { code: 'IT301', name: 'Computer Architecture' },
            { code: 'IT302', name: 'Design and Analysis of Algorithms' },
            { code: 'IT303', name: 'Artificial Intelligence' },
            { code: 'IT304', name: 'Cloud Computing' },
            { code: 'IT305', name: 'Information Security' },
            { code: 'IT306', name: 'Mobile Application Development' },
            { code: 'IT307', name: 'Data Analytics' },
            { code: 'IT308', name: 'Internet of Things' }
        ],
        '4': [
            { code: 'IT401', name: 'Machine Learning' },
            { code: 'IT402', name: 'Big Data Technologies' },
            { code: 'IT403', name: 'Blockchain Technology' },
            { code: 'IT404', name: 'DevOps Practices' },
            { code: 'IT405', name: 'Cyber Security' },
            { code: 'IT406', name: 'Natural Language Processing' },
            { code: 'IT407', name: 'Digital Marketing' }
        ]
    }
};

async function seed() {
    console.log('🌱 Seeding Full Timetable for All Departments...');

    // [NEW] Fetch Structure from DB
    const structure = await getActiveStructure();
    console.log(`📋 Using Schedule Structure: ${structure.length} slots`);

    // Filter only CLASS slots for seeding content
    const classSlots = structure.filter((s: any) => s.type === 'class');
    console.log(`ℹ️ Found ${classSlots.length} class slots per day.`);

    const allEntries: any[] = [];

    // Loop through Departments
    for (const dept of departments) {
        console.log(`🔹 Processing Department: ${dept}`);
        const yearsData = deptSubjects[dept];

        for (const year of Object.keys(yearsData)) {
            const subjects = yearsData[year];
            const locations = roomPools[dept][year]; // Department-specific rooms

            // Clear existing data for this department/year first
            await supabase.from('timetables').delete().eq('department', dept).eq('year', year);
            console.log(`   🗑️ Cleared ${dept} Year ${year}`);

            for (let sIdx = 0; sIdx < sections.length; sIdx++) {
                const section = sections[sIdx];
                let subjectIterator = sIdx * 3;

                // Each section gets dedicated rooms to avoid clashes
                // Section A: rooms 0,1; Section B: rooms 2,3; Section C: rooms 4,5
                const roomOffset = sIdx * 2;

                for (const day of days) {
                    // Loop through DYNAMIC class slots
                    for (let i = 0; i < classSlots.length; i++) {
                        const slot = classSlots[i];
                        const subject = subjects[subjectIterator % subjects.length];
                        subjectIterator++;

                        // Assign rooms: alternate between 2 dedicated rooms per section
                        const location = locations[(roomOffset + (i % 2)) % locations.length];

                        allEntries.push({
                            user_id: adminId,
                            day_of_week: day,
                            start_time: slot.start,
                            end_time: slot.end,
                            course_code: subject.code,
                            course_name: subject.name,
                            location: location,
                            department: dept,
                            year: year,
                            section: section
                        });

                        // Insert in batches of 500 to avoid Supabase limits
                        if (allEntries.length >= 500) {
                            console.log(`   📦 Inserting batch of ${allEntries.length} entries...`);
                            const { error: batchError } = await supabase.from('timetables').insert(allEntries);
                            if (batchError) {
                                console.error('   ❌ Batch insert error:', batchError);
                            } else {
                                console.log(`   ✅ Batch inserted successfully`);
                            }
                            allEntries.length = 0; // Clear array
                        }
                    }
                }
            }
        }
    }

    // Insert remaining entries
    if (allEntries.length > 0) {
        console.log(`📦 Inserting final batch of ${allEntries.length} entries...`);
        const { error } = await supabase.from('timetables').insert(allEntries);

        if (error) {
            console.error('❌ Final batch insert error:', error);
        } else {
            console.log(`✅ Final batch inserted successfully`);
        }
    }

    // Verify total count
    const { count } = await supabase.from('timetables').select('*', { count: 'exact', head: true });
    console.log(`\n🎉 Seeding complete! Total entries in database: ${count}`);
    console.log(`📋 Expected: ${departments.length * 4 * sections.length * days.length * classSlots.length} entries`);
    console.log(`   (${departments.length} depts × 4 years × ${sections.length} sections × ${days.length} days × ${classSlots.length} slots)`);
}

seed();
