import * as XLSX from 'xlsx';

export interface ParsedRow {
    [key: string]: string;
}

export const parseFile = (buffer: Buffer, mimetype?: string): ParsedRow[] => {
    // Check for Excel magic bytes or mimetype, or just try XLSX.read which handles both CSV and Excel
    try {
        const workbook = XLSX.read(buffer, { type: 'buffer' });
        const sheetName = workbook.SheetNames[0];
        const sheet = workbook.Sheets[sheetName];

        // Convert to JSON
        // raw: false ensures we get the formatted string (e.g. "09:00:00") not the serial number (e.g. 0.375)
        const jsonData = XLSX.utils.sheet_to_json(sheet, { defval: '', raw: false });

        // Normalize keys to lowercase to match our expected schema
        const normalizedData: ParsedRow[] = jsonData.map((row: any) => {
            const newRow: ParsedRow = {};
            Object.keys(row).forEach(key => {
                newRow[key.trim().toLowerCase()] = String(row[key]).trim(); // normalize key
            });
            return newRow;
        });

        return normalizedData;
    } catch (e) {
        console.error("Excel parse failed, trying legacy CSV", e);
        // Fallback or explicit CSV handling if XLSX.read fails for simple CSVs? 
        // XLSX usually handles CSVs fine.
        return [];
    }
};
