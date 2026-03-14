import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { getEmbedding } from '../services/aiService';
import { parseFile } from '../utils/csvParser';
import { WithAuthProp } from '@clerk/clerk-sdk-node';

export const searchKB = async (req: Request, res: Response): Promise<void> => {
    try {
        const { query } = req.query;
        if (!query) {
            res.status(400).json({ error: 'Query is required' });
            return;
        }

        const embedding = await getEmbedding(query as string);

        const { data, error } = await supabase.rpc('hybrid_search_kb', {
            query_text: query,
            query_embedding: embedding,
            match_threshold: 0.3, // Still use threshold for semantic fallback
            match_count: 5
        });

        if (error) throw error;
        console.log(`Search query: "${query}" -> Found ${data?.length || 0} matches`);
        res.json(data);
    } catch (error: any) {
        console.error("Search KB Error:", error);
        res.status(500).json({ error: error.message });
    }
};

export const addArticle = async (req: Request, res: Response): Promise<void> => {
    try {
        const { title, content, category } = req.body;
        const userId = (req as any).auth.userId;
        const slug = title.toLowerCase().replace(/ /g, '-').replace(/[^\w-]+/g, '');

        // 1. Insert Article with author_id
        const { data: article, error: articleError } = await supabase
            .from('kb_articles')
            .insert([{ title, slug, content, category, author_id: userId }])
            .select()
            .single();

        if (articleError) throw articleError;

        // 2. Generate Embedding and Insert
        const embedding = await getEmbedding(`${title}: ${content}`);

        const { error: embedError } = await supabase
            .from('kb_embeddings')
            .insert([{
                article_id: article.id,
                chunk_index: 0,
                chunk_content: content,
                embedding
            }]);

        if (embedError) console.error("Embedding Save Error:", embedError);

        res.status(201).json(article);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const getAllArticles = async (req: Request, res: Response): Promise<void> => {
    try {
        const { data, error } = await supabase
            .from('kb_articles')
            .select('*')
            .order('updated_at', { ascending: false });

        if (error) throw error;
        res.json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const updateArticle = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { title, content, category } = req.body;
        const userId = (req as any).auth.userId;

        // Check ownership/role
        const { data: profile } = await supabase.from('profiles').select('role').eq('id', userId).single();
        const { data: article } = await supabase.from('kb_articles').select('author_id').eq('id', id).single();

        if (!article) {
            res.status(404).json({ error: 'Article not found' });
            return;
        }

        const isAdmin = profile?.role === 'admin';
        const isAuthor = article.author_id === userId;

        if (!isAdmin && !isAuthor) {
            res.status(403).json({ error: 'Forbidden: You can only edit your own articles' });
            return;
        }

        const { error } = await supabase
            .from('kb_articles')
            .update({ title, content, category, updated_at: new Date().toISOString() })
            .eq('id', id);

        if (error) throw error;

        // Regenerate embedding if content changed
        if (title || content) {
            try {
                const validTitle = title;
                const validContent = content;

                if (validTitle && validContent) {
                    const embedding = await getEmbedding(`${validTitle}: ${validContent}`);
                    await supabase.from('kb_embeddings').delete().eq('article_id', id);
                    await supabase.from('kb_embeddings').insert([{
                        article_id: id,
                        chunk_index: 0,
                        chunk_content: validContent,
                        embedding
                    }]);
                }
            } catch (embedError) {
                console.error("Failed to update embedding:", embedError);
            }
        }

        res.json({ message: 'Article updated successfully' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const deleteArticle = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const userId = (req as any).auth.userId;

        // Check ownership/role
        const { data: profile } = await supabase.from('profiles').select('role').eq('id', userId).single();
        const { data: article } = await supabase.from('kb_articles').select('author_id').eq('id', id).single();

        if (!article) {
            res.status(404).json({ error: 'Article not found' });
            return;
        }

        const isAdmin = profile?.role === 'admin';
        const isAuthor = article.author_id === userId;

        if (!isAdmin && !isAuthor) {
            res.status(403).json({ error: 'Forbidden: You can only delete your own articles' });
            return;
        }

        // Delete associated embeddings first to prevent foreign key constraint errors and orphaned data
        await supabase.from('kb_embeddings').delete().eq('article_id', id);

        const { error } = await supabase
            .from('kb_articles')
            .delete()
            .eq('id', id);

        if (error) throw error;
        res.json({ message: 'Article deleted successfully' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const importArticles = async (req: Request, res: Response): Promise<void> => {
    try {
        const file = (req as any).file;
        if (!file) {
            res.status(400).json({ error: 'No file uploaded' });
            return;
        }

        const userId = (req as any).auth.userId;
        const rows = parseFile(file.buffer);

        if (rows.length === 0) {
            res.status(400).json({ error: 'Excel/CSV file is empty or invalid' });
            return;
        }

        // 1. Filter and Map valid rows
        const validCategories = ['General', 'Policy', 'Academic', 'Facilities', 'Handbook'];
        
        const validRows = rows.map(row => {
            const title = row['title']?.toString().trim();
            const content = row['content']?.toString().trim();
            let category = row['category']?.toString().trim() || 'General';
            
            // Default to General if category is invalid or misspelled
            if (!validCategories.includes(category)) {
                category = 'General';
            }

            return { title, content, category };
        }).filter(row => row.title && row.content); // Must have both title and content

        if (validRows.length === 0) {
            res.status(400).json({ error: 'No valid articles found in file. Ensure headers: title, content, category' });
            return;
        }

        console.log(`[importArticles] Parsed ${validRows.length} valid articles. Starting import...`);

        // 2. Sequential Processing to avoid Rate Limits (especially with Gemini AI)
        let successCount = 0;
        let failCount = 0;

        for (const row of validRows) {
            try {
                // Generate slug
                const slug = row.title.toLowerCase().replace(/ /g, '-').replace(/[^\w-]+/g, '') + '-' + Date.now().toString().slice(-4);

                // Insert into kb_articles
                const { data: article, error: articleError } = await supabase
                    .from('kb_articles')
                    .insert([{ 
                        title: row.title, 
                        slug, 
                        content: row.content, 
                        category: row.category, 
                        author_id: userId 
                    }])
                    .select()
                    .single();

                if (articleError) {
                    console.error(`[importArticles] DB Insert Error for "${row.title}":`, articleError.message);
                    failCount++;
                    continue; // Skip embedding if DB insert fails
                }

                // Generate Embedding and Insert
                const embedding = await getEmbedding(`${row.title}: ${row.content}`);

                const { error: embedError } = await supabase
                    .from('kb_embeddings')
                    .insert([{
                        article_id: article.id,
                        chunk_index: 0,
                        chunk_content: row.content,
                        embedding
                    }]);

                if (embedError) {
                    console.error(`[importArticles] Embedding Save Error for "${row.title}":`, embedError.message);
                    failCount++; // Technically article exists, but search will fail. Counting as fail for clarity.
                } else {
                    successCount++;
                }
            } catch (err: any) {
                console.error(`[importArticles] Loop Exception for "${row.title}":`, err.message);
                failCount++;
            }
        }

        console.log(`[importArticles] Import Complete. Success: ${successCount}. Failed: ${failCount}.`);
        res.status(201).json({
            message: `Successfully imported ${successCount} articles. Failed: ${failCount}.`,
            count: successCount
        });

    } catch (error: any) {
        console.error('Import Article Error:', error);
        res.status(500).json({ error: error.message });
    }
};
