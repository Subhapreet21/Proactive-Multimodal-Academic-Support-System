import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';

import { WithAuthProp } from '@clerk/clerk-sdk-node';

export const getProfile = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        if (!userId) {
            res.status(401).json({ error: 'Unauthorized' });
            return;
        }

        const { data, error } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .single();

        if (error) {
            // If profile doesn't exist, we might return a default empty one or 404
            // For now, let's return null data if not found, or basic info
            if (error.code === 'PGRST116') { // JSON code for no rows found
                res.json({ message: 'Profile not found' });
                return;
            }
            throw error;
        }
        res.json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const updateProfile = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { full_name, email, department, year, section } = req.body;

        // Upsert allows creating if not exists
        const { data, error } = await supabase
            .from('profiles')
            .upsert({
                id: userId,
                email,
                full_name,
                department,
                year,
                section
            })
            .select()
            .single();

        if (error) throw error;
        res.json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
