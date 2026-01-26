import * as fs from 'fs';
import * as path from 'path';
import * as XLSX from 'xlsx';

const SAMPLES_DIR = path.join(__dirname, '../../samples');

if (!fs.existsSync(SAMPLES_DIR)) {
    fs.mkdirSync(SAMPLES_DIR);
}

const data = [
    {
        day_of_week: 'Monday',
        start_time: '09:00:00',
        end_time: '10:00:00',
        course_code: 'TEST101',
        course_name: 'Introduction to Bulk Import',
        location: 'Room 101',
        department: 'CSE',
        year: '1',
        section: 'A'
    },
    {
        day_of_week: 'Tuesday',
        start_time: '10:00:00',
        end_time: '11:00:00',
        course_code: 'TEST102',
        course_name: 'Advanced Excel Parsing',
        location: 'Lab 2',
        department: 'CSE',
        year: '1',
        section: 'A'
    },
    {
        day_of_week: 'Wednesday',
        start_time: '11:00:00',
        end_time: '12:00:00',
        course_code: 'TEST103',
        course_name: 'CSV Mastery',
        location: 'Hall A',
        department: 'CSE',
        year: '1',
        section: 'A'
    }
];

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

const csvPath = path.join(SAMPLES_DIR, 'sample_timetable.csv');
fs.writeFileSync(csvPath, csvContent);
console.log(`✅ Generated CSV: ${csvPath}`);

// 2. Generate Excel (XLSX)
const ws = XLSX.utils.json_to_sheet(data);
const wb = XLSX.utils.book_new();
XLSX.utils.book_append_sheet(wb, ws, 'Timetable');

const xlsxPath = path.join(SAMPLES_DIR, 'sample_timetable.xlsx');
XLSX.writeFile(wb, xlsxPath);
console.log(`✅ Generated Excel: ${xlsxPath}`);

console.log('\nUse these files to test the Bulk Import feature.');
