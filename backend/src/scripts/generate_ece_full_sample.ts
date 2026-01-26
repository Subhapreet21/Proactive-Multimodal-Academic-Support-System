import * as fs from 'fs';
import * as path from 'path';
import * as XLSX from 'xlsx';

const SAMPLES_DIR = path.join(__dirname, '../../samples');

if (!fs.existsSync(SAMPLES_DIR)) {
    fs.mkdirSync(SAMPLES_DIR);
}

// ECE Subjects (Year 2 Only)
const eceSubjects = {
    '2': [
        { code: 'ECE201', name: 'Analog Circuits' },
        { code: 'ECE202', name: 'Digital Logic Design' },
        { code: 'ECE203', name: 'Signals and Systems' },
        { code: 'MAT201', name: 'Mathematics-3' },
        { code: 'ECE204', name: 'Electromagnetic Fields' },
        { code: 'ECE205', name: 'Network Analysis' },
        { code: 'ECE206', name: 'Linear Integrated Circuits' },
        { code: 'CS201', name: 'Data Structures' },
    ]
};

const slots = [
    { start: '09:00:00', end: '10:00:00' },
    { start: '10:00:00', end: '11:00:00' },
    // Break 11:00-11:10
    { start: '11:10:00', end: '12:10:00' },
    // Break 12:10-13:00
    { start: '13:00:00', end: '14:00:00' },
    { start: '14:00:00', end: '15:00:00' }
];

const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
const sections = ['A']; // Only Section A

const data: any[] = [];

// Generate Data
Object.keys(eceSubjects).forEach(year => {
    // Shuffle subjects to randomize schedule and avoid clashes with other sections
    const subjects = [...eceSubjects[year as keyof typeof eceSubjects]].sort(() => Math.random() - 0.5);

    sections.forEach(section => {
        let subjectIndex = 0;

        days.forEach(day => {
            slots.forEach((slot, slotIndex) => {
                const subject = subjects[subjectIndex % subjects.length];
                subjectIndex++;

                // Deterministic Room Allocation
                // Year 2: Room 201/202. Year 3: Room 301/302.
                // Rotate based on slot to simulate lab movements
                const baseRoom = `ECE-${year}0${section === 'A' ? 1 : 2}`;
                const labRoom = `ECE-${year}-LAB-${slotIndex}`;

                // Every 5th slot is a "Lab" just for variety
                const location = (slotIndex === 4) ? labRoom : baseRoom;

                data.push({
                    day_of_week: day,
                    start_time: slot.start,
                    end_time: slot.end,
                    course_code: subject.code,
                    course_name: subject.name,
                    location: location,
                    department: 'ECE',
                    year: year,
                    section: section
                });
            });
        });
    });
});

// 1. Generate CSV
const csvHeaders = ['day_of_week', 'start_time', 'end_time', 'course_code', 'course_name', 'location', 'department', 'year', 'section'];
const csvContent = [
    csvHeaders.join(','),
    ...data.map(row => [
        row.day_of_week,
        row.start_time,
        row.end_time,
        row.course_code,
        row.course_name,
        row.location,
        row.department,
        row.year,
        row.section
    ].join(','))
].join('\n');

const csvPath = path.join(SAMPLES_DIR, 'sample_ece_full.csv');
fs.writeFileSync(csvPath, csvContent);
console.log(`✅ Generated CSV: ${csvPath}`);

// 2. Generate Excel (XLSX)
const ws = XLSX.utils.json_to_sheet(data);
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, ws, 'ECE_Schedule');

const xlsxPath = path.join(SAMPLES_DIR, 'sample_ece_full.xlsx');
XLSX.writeFile(wb, xlsxPath);
console.log(`✅ Generated Excel: ${xlsxPath}`);

console.log(`\n🎉 Generated full week ECE timetable for Year 2 & 3 (Sections A & B). Total entries: ${data.length}`);
