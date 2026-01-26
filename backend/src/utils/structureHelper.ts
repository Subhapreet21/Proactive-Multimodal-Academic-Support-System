import { supabase } from '../services/supabaseClient';

// Helper to fetch structure from DB or return default
export async function getActiveStructure() {
    const { data, error } = await supabase
        .from('timetable_metadata')
        .select('value')
        .eq('key', 'timetable_structure')
        .single();

    if (error || !data) {
        console.log("No config found in DB, using fallback defaults...");
        return [
            { start: '09:00', end: '10:00', type: 'class' },
            { start: '10:00', end: '11:00', type: 'class' },
            { start: '11:00', end: '11:10', type: 'break', label: 'Short Break' },
            { start: '11:10', end: '12:10', 'type': 'class' },
            { start: '12:10', end: '13:00', 'type': 'break', 'label': 'Lunch Break' },
            { start: '13:00', end: '14:00', 'type': 'class' },
            { start: '14:00', end: '15:00', 'type': 'class' }
        ];
    }

    // Filter for CLASS slots only
    return data.value; // Returns full structure including breaks
}
