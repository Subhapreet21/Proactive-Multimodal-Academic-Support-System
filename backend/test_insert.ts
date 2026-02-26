import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';

const envPath = path.resolve(__dirname, '.env');
dotenv.config({ path: envPath });

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

async function testInsert() {
    try {
        console.log("Fetching a KB article id...");
        const { data: articles, error: fetchErr } = await supabase.from('kb_articles').select('id, title').limit(1);
        if (fetchErr || !articles || articles.length === 0) {
            console.error("Failed to fetch KB article:", fetchErr);
            return;
        }

        const kb_article_id = articles[0].id;
        const title = "Test generated quiz";

        console.log("Testing insert into quizzes with kb_article_id:", kb_article_id);
        const { data, error } = await supabase.from('quizzes').insert({
            title: title,
            description: "Some test",
            kb_article_id: kb_article_id,
            content: [],
            // we will skip created_by to see if it causes an error when not authenticated
            // wait, if created_by is a required foreign key?
            // "created_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL" - it is nullable!
        }).select().single();

        if (error) {
            console.error("Insert Error:", error);
        } else {
            console.log("Insert Success:", data);
        }
    } catch (err) {
        console.error("Script exception:", err);
    }
}

testInsert();
