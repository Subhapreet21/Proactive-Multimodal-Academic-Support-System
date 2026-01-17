
import { supabase } from './services/supabaseClient';

const testEvents = async () => {
    console.log("Testing Supabase Connection...");
    try {
        const { data, error } = await supabase
            .from('events_notices')
            .select('*');

        if (error) {
            console.error("Supabase Error:", error);
        } else {
            console.log("Events Data:", JSON.stringify(data, null, 2));
            console.log("Count:", data.length);
        }
    } catch (err) {
        console.error("Unexpected Error:", err);
    }
};

testEvents();
