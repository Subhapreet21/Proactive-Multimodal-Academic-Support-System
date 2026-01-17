import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { getEmbedding } from '../services/aiService';

export const searchKB = async (req: Request, res: Response): Promise<void> => {
    try {
        const { query } = req.query;
        if (!query) {
            res.status(400).json({ error: 'Query is required' });
            return;
        }

        const embedding = await getEmbedding(query as string);

        const { data, error } = await supabase.rpc('match_kb_articles', {
            query_embedding: embedding,
            match_threshold: 0.3, // Lowered from 0.5 to be more permissive
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
