import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';

import { WithAuthProp } from '@clerk/clerk-sdk-node';

export const getReminders = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { data, error } = await supabase
            .from('reminders')
            .select('*')
            .eq('user_id', userId)
            .order('due_at', { ascending: true });

        if (error) throw error;
        res.json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const addReminder = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { title, description, due_at, category } = req.body;
        const { data, error } = await supabase
            .from('reminders')
            .insert([{
                user_id: userId,
                title,
                description,
                due_at,
                category,
                is_completed: false
            }])
            .select();

        if (error) throw error;
        res.status(201).json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const updateReminderStatus = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { is_completed } = req.body;
        const { error } = await supabase
            .from('reminders')
            .update({ is_completed })
            .eq('id', id);

        if (error) throw error;
        res.json({ message: 'Reminder status updated' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const updateReminderDetails = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { title, description, due_at, category, is_completed } = req.body;

        const updates: any = {};
        if (title) updates.title = title;
        if (description !== undefined) updates.description = description;
        if (due_at) updates.due_at = due_at;
        if (category) updates.category = category;
        if (is_completed !== undefined) updates.is_completed = is_completed;

        const { error } = await supabase
            .from('reminders')
            .update(updates)
            .eq('id', id);

        if (error) throw error;
        res.json({ message: 'Reminder details updated' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const deleteReminder = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { error } = await supabase
            .from('reminders')
            .delete()
            .eq('id', id);

        if (error) throw error;
        res.json({ message: 'Reminder deleted' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
