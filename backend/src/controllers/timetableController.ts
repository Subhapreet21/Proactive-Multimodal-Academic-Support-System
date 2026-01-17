import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';

import { WithAuthProp } from '@clerk/clerk-sdk-node';

export const getTimetable = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;

        // 1. Get User Profile to check role and group
        const { data: profile, error: profileError } = await supabase
            .from('profiles')
            .select('role, department, year, section')
            .eq('id', userId)
            .single();

        if (profileError || !profile) {
            res.status(404).json({ error: 'Profile not found' });
            return;
        }

        let query = supabase.from('timetables').select('*').order('start_time', { ascending: true });

        // 2. Apply Filters based on Role
        if (profile.role === 'student') {
            // Strict Filter: Only show my specific section
            if (!profile.department || !profile.year || !profile.section) {
                res.status(400).json({ error: 'Profile incomplete. Please update your profile.' });
                return;
            }
            query = query
                .eq('department', profile.department)
                .eq('year', profile.year)
                .eq('section', profile.section);
        } else {
            // Admin/Faculty: Allow query params for filtering
            const { department, year, section } = req.query;

            if (department) query = query.eq('department', department);
            if (year) query = query.eq('year', year);
            if (section) query = query.eq('section', section);

            // Optional: Default to own department for Faculty if no filter?
            // Keeping it simple: If no filter provided, they might see ALL or none. 
            // Let's rely on frontend to send default filters or show "Select a Class".
        }

        const { data, error } = await query;

        if (error) throw error;
        res.json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const addTimetableEntry = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { day_of_week, start_time, end_time, course_code, course_name, location, department, year, section } = req.body;

        // 1. Get User Profile for Validation
        const { data: profile } = await supabase.from('profiles').select('role, department').eq('id', userId).single();

        if (profile?.role === 'faculty') {
            if (profile.department !== department) {
                res.status(403).json({ error: `Faculty can only manage timetable for ${profile.department} department.` });
                return;
            }
        }

        // Validate required group fields
        if (!department || !year || !section) {
            res.status(400).json({ error: 'Department, Year, and Section are required.' });
            return;
        }

        const { data, error } = await supabase
            .from('timetables')
            .insert([{
                user_id: userId, // Keep distinct creator ID
                day_of_week,
                start_time,
                end_time,
                course_code,
                course_name,
                location,
                department,
                year,
                section
            }])
            .select();

        if (error) throw error;
        res.status(201).json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const deleteTimetableEntry = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const userId = (req as WithAuthProp<Request>).auth.userId;

        // Check if Faculty is trying to delete from another department
        const { data: profile } = await supabase.from('profiles').select('role, department').eq('id', userId).single();

        if (profile?.role === 'faculty') {
            const { data: entry } = await supabase.from('timetables').select('department').eq('id', id).single();
            if (entry && entry.department !== profile.department) {
                res.status(403).json({ error: `Faculty can only delete entries for ${profile.department} department.` });
                return;
            }
        }

        const { error } = await supabase
            .from('timetables')
            .delete()
            .eq('id', id);

        if (error) throw error;
        res.json({ message: 'Entry deleted' });
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};

export const updateTimetableEntry = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { day_of_week, start_time, end_time, course_code, course_name, location, department, year, section } = req.body;

        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { data: profile } = await supabase.from('profiles').select('role, department').eq('id', userId).single();

        if (profile?.role === 'faculty') {
            // For simplicity, just ensure the NEW data is for their dept.
            if (department && profile.department !== department) {
                res.status(403).json({ error: `Faculty can only manage timetable for ${profile.department} department.` });
                return;
            }
        }

        const { data, error } = await supabase
            .from('timetables')
            .update({
                day_of_week,
                start_time,
                end_time,
                course_code,
                course_name,
                location,
                department,
                year,
                section
            })
            .eq('id', id)
            .select();

        if (error) throw error;
        res.json(data);
    } catch (error: any) {
        res.status(500).json({ error: error.message });
    }
};
