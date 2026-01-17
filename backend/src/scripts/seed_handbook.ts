import fs from 'fs';
import path from 'path';
import { supabase } from '../services/supabaseClient';
import { getEmbedding } from '../services/aiService';

const HANDBOOK_PATH = path.resolve(__dirname, '../../../knowledge_base/university_handbook.md.resolved');

async function seedHandbook() {
    console.log(`📖 Reading handbook from: ${HANDBOOK_PATH}`);

    if (!fs.existsSync(HANDBOOK_PATH)) {
        console.error('❌ Handbook file not found!');
        return;
    }

    const content = fs.readFileSync(HANDBOOK_PATH, 'utf-8');

    // Split content by headers (Simple chunking strategy)
    const sections = content.split(/^## /gm).slice(1); // Skip preamble if any

    console.log(`🧩 Found ${sections.length} main sections. Processing...`);

    for (const section of sections) {
        // Extract title and body
        const [titleLine, ...bodyLines] = section.split('\n');
        const title = titleLine.trim();
        const body = bodyLines.join('\n').trim();

        if (body.length < 50) {
            console.log(`⚠️ Skipping short section: ${title}`);
            continue;
        }

        console.log(`✨ Processing: ${title}`);

        // 1. Insert Article
        const { data: article, error: articleError } = await supabase
            .from('kb_articles')
            .upsert({
                title: title,
                slug: title.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
                content: body,
                category: 'handbook'
            }, { onConflict: 'slug' })
            .select()
            .single();

        if (articleError) {
            console.error(`❌ Error inserting article ${title}:`, articleError.message);
            continue;
        }

        // 2. Generate Embedding for the whole section (or chunk further if needed)
        // For now, we embed the title + body to get good semantic context.
        // Truncate if too long (Gemini has decent context window but let's be safe)
        const chunkContent = `Title: ${title}\n\n${body}`.substring(0, 8000);

        try {
            const embedding = await getEmbedding(chunkContent);

            // 3. Insert Embedding
            const { error: embedError } = await supabase
                .from('kb_embeddings')
                .insert({
                    article_id: article.id,
                    chunk_content: chunkContent, // We store the text we embedded for the RAG result
                    embedding: embedding
                });

            if (embedError) {
                console.error(`❌ Error inserting embedding for ${title}:`, embedError.message);
            } else {
                console.log(`✅ Indexed: ${title}`);
            }

        } catch (e: any) {
            console.error(`❌ AI Error for ${title}:`, e.message);
        }
    }

    console.log('🎉 Seeding complete!');
}

seedHandbook();
