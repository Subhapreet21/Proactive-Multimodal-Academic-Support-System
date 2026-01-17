
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import { getEmbedding } from '../services/aiService';

// Load environment variables
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseKey) {
    console.error("Missing Supabase credentials in .env");
    process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

const HANDBOOK_PATH = path.resolve(__dirname, '../../../knowledge_base/university_handbook.md.resolved');

async function seedHandbook() {
    console.log("Starting Handbook Ingestion...");

    if (!fs.existsSync(HANDBOOK_PATH)) {
        console.error(`Handbook file not found at: ${HANDBOOK_PATH}`);
        process.exit(1);
    }

    const content = fs.readFileSync(HANDBOOK_PATH, 'utf-8');

    // Split content by H2 headers (## ) to get main sections
    const sections = content.split(/^## /m).filter(s => s.trim().length > 0);

    console.log(`Found ${sections.length} sections.`);

    for (const section of sections) {
        // Extract title (first line) and content (rest)
        const lines = section.trim().split('\n');
        const titleLine = lines[0].trim();
        const body = lines.slice(1).join('\n').trim();

        // Remove numbering from title if present (e.g., "1. About..." -> "About...")
        const cleanTitle = titleLine.replace(/^\d+\.\s*/, '');
        const slug = cleanTitle.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');

        console.log(`Processing: ${cleanTitle}`);

        // 1. Check if article exists, if so, update or skip. Let's Delete and Re-insert for simplicity/freshness.
        const { error: deleteError } = await supabase
            .from('kb_articles')
            .delete()
            .eq('slug', slug);

        if (deleteError) console.error("Error deleting old article:", deleteError.message);

        // 2. Insert Article
        const { data: article, error: insertError } = await supabase
            .from('kb_articles')
            .insert({
                title: cleanTitle,
                slug: slug,
                content: body,
                category: 'University Handbook'
            })
            .select()
            .single();

        if (insertError) {
            console.error(`Error inserting article ${cleanTitle}:`, insertError.message);
            continue;
        }

        console.log(`  -> Article created ID: ${article.id}`);

        // 3. Generate Embedding for the whole section (or chunks if too large, but these sections are small enough for now)
        // Gemini embedding model supports up to 2048 tokens, these sections are well within limit.
        // We embed the combination of Title + Content for better context.
        const textToEmbed = `${cleanTitle}\n\n${body}`;

        try {
            const embedding = await getEmbedding(textToEmbed);

            // 4. Insert Embedding
            const { error: embedError } = await supabase
                .from('kb_embeddings')
                .insert({
                    article_id: article.id,
                    chunk_index: 0,
                    chunk_content: body, // Storing full body as chunk for now
                    embedding: embedding
                });

            if (embedError) {
                console.error(`  -> Error inserting embedding:`, embedError.message);
            } else {
                console.log(`  -> Embedding stored.`);
            }

        } catch (err) {
            console.error(`  -> Failed to generate embedding:`, err);
        }
    }

    console.log("Ingestion Complete!");
}

seedHandbook();
