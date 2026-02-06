import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { randomBytes } from 'crypto';

// Generate a random code (e.g., FAC-7V9X2K)
const generateCode = (role: string): string => {
    const prefix = role === 'admin' ? 'ADM' : 'FAC';
    const random = randomBytes(3).toString('hex').toUpperCase();
    return `${prefix}-${random}`;
};

export const generateInvite = async (req: Request, res: Response) => {
    console.log('📝 [generateInvite] Hit!', req.body);
    try {
        const { role, usage_limit } = req.body;
        const creatorId = (req as any).auth?.userId;

        if (!['admin', 'faculty'].includes(role)) {
            return res.status(400).json({ error: 'Invalid role' });
        }

        const code = generateCode(role);

        const { data, error } = await supabase
            .from('invitation_codes')
            .insert({
                code,
                role,
                usage_limit: usage_limit || 1,
                created_by: creatorId
            })
            .select()
            .single();

        if (error) throw error;

        res.json(data);
    } catch (error: any) {
        console.error('Error generating invite:', error);
        res.status(500).json({ error: 'Failed to generate invite' });
    }
};

export const listInvites = async (req: Request, res: Response) => {
    try {
        const { data, error } = await supabase
            .from('invitation_codes')
            .select('*')
            .order('created_at', { ascending: false });

        if (error) throw error;

        res.json(data);
    } catch (error: any) {
        console.error('Error listing invites:', error);
        res.status(500).json({ error: 'Failed to list invites' });
    }
};

export const deleteInvite = async (req: Request, res: Response) => {
    try {
        const { code } = req.params;

        const { error } = await supabase
            .from('invitation_codes')
            .delete()
            .eq('code', code);

        if (error) throw error;

        res.json({ message: 'Invite deleted' });
    } catch (error: any) {
        console.error('Error deleting invite:', error);
        res.status(500).json({ error: 'Failed to delete invite' });
    }
};
