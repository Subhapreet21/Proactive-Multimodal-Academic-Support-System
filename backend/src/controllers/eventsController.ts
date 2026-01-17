import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';

export const getEvents = async (req: Request, res: Response): Promise<void> => {
    try {
        const { data, error } = await supabase
            .from('events_notices')
            .select('*')
            .order('event_date', { ascending: true });

        if (error) throw error;
        res.json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const addEvent = async (req: Request, res: Response): Promise<void> => {
    try {
        const { title, description, event_date, category, location, source_image_url } = req.body;
        const { data, error } = await supabase
            .from('events_notices')
            .insert([{
                title,
                description,
                event_date,
                category,
                location,
                source_image_url
            }])
            .select();

        if (error) throw error;
        res.status(201).json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const deleteEvent = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { error } = await supabase
            .from('events_notices')
            .delete()
            .eq('id', id);

        if (error) throw error;
        res.json({ message: 'Event deleted' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const updateEvent = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { title, description, event_date, category, location, source_image_url } = req.body;

        const { data, error } = await supabase
            .from('events_notices')
            .update({
                title,
                description,
                event_date,
                category,
                location,
                source_image_url
            })
            .eq('id', id)
            .select();

        if (error) throw error;
        res.json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
