import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';

import { WithAuthProp } from '@clerk/clerk-sdk-node';
import { parseFile } from '../utils/csvParser';

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
            console.log('[getTimetable] Profile not found for userId:', userId);
            res.status(404).json({ error: 'Profile not found' });
            return;
        }

        console.log('[getTimetable] User profile:', {
            userId,
            role: profile.role,
            department: profile.department,
            year: profile.year,
            section: profile.section
        });

        let query = supabase.from('timetables').select('*').order('start_time', { ascending: true }).range(0, 9999);

        // 2. Apply Filters based on Role
        if (profile.role === 'student') {
            // Strict Filter: Only show my specific section
            if (!profile.department || !profile.year || !profile.section) {
                console.log('[getTimetable] Incomplete student profile');
                res.status(400).json({ error: 'Profile incomplete. Please update your profile.' });
                return;
            }
            query = query
                .eq('department', profile.department)
                .eq('year', profile.year)
                .eq('section', profile.section);
            console.log('[getTimetable] Applied student filters:', {
                department: profile.department,
                year: profile.year,
                section: profile.section
            });
        } else {
            // Admin/Faculty: Allow query params for filtering
            const { department, year, section } = req.query;

            if (department) query = query.eq('department', department);
            if (year) query = query.eq('year', year);
            if (section) query = query.eq('section', section);

            console.log('[getTimetable] Applied admin/faculty filters:', {
                department: department || 'none',
                year: year || 'none',
                section: section || 'none'
            });

            // Optional: Default to own department for Faculty if no filter?
            // Keeping it simple: If no filter provided, they might see ALL or none. 
            // Let's rely on frontend to send default filters or show "Select a Class".
        }

        const { data, error } = await query;

        if (error) {
            console.error('[getTimetable] Supabase query error:', error);
            throw error;
        }

        console.log('[getTimetable] Successfully fetched entries from Supabase:', data?.length || 0);
        console.log('[getTimetable] Returning data to frontend');

        res.json(data);
    } catch (error: any) {
        console.error('[getTimetable] Error:', error.message);
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

        // 2. Handle both String (Single Day) and Array (Recurring Days)
        let daysToInsert: string[] = [];
        if (Array.isArray(day_of_week)) {
            daysToInsert = day_of_week;
        } else {
            daysToInsert = [day_of_week];
        }

        // 3. Upsert Logic (Check Existing -> Update/Insert)
        const results = await Promise.all(daysToInsert.map(async (day) => {
            // Check for existing entry in this slot
            const { data: existing } = await supabase
                .from('timetables')
                .select('id')
                .match({
                    department,
                    year,
                    section,
                    day_of_week: day,
                    start_time
                })
                .single();

            if (existing) {
                // Update Existing
                return supabase
                    .from('timetables')
                    .update({
                        end_time,
                        course_code,
                        course_name,
                        location,
                        user_id: userId // Update last modified user
                    })
                    .eq('id', existing.id)
                    .select()
                    .single();
            } else {
                // Insert New
                return supabase
                    .from('timetables')
                    .insert({
                        user_id: userId,
                        day_of_week: day,
                        start_time,
                        end_time,
                        course_code,
                        course_name,
                        location,
                        department,
                        year,
                        section
                    })
                    .select()
                    .single();
            }
        }));

        // Check for any errors in the batch
        const errors = results.filter(r => r.error).map(r => r.error);
        if (errors.length > 0) throw errors[0];

        const data = results.map(r => r.data);
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

// Batch Update for Rescheduling
export const batchUpdateTimetable = async (req: Request, res: Response): Promise<void> => {
    try {
        const { entries } = req.body; // Expecting { entries: [ { id:..., day_of_week:... }, ... ] }

        if (!entries || !Array.isArray(entries) || entries.length === 0) {
            res.status(400).json({ error: 'No entries provided for batch update.' });
            return;
        }

        // Sanitize: We only want to update specific fields to avoid overwriting unrelated data accidentally
        // But for swapping days, updating 'day_of_week' is the key. 
        // We assume entries contain 'id' and the fields to change.

        // Upsert allows bulk update by ID
        // Two-Pass Strategy to avoid Unique Constraint Collisions (A <-> B swap)

        // 1. Phase 1: Clearance
        // CRITICAL: Fetch CURRENT day_of_week from DB first to avoid collisions
        const tempPrefix = `TEMP_${Date.now()}_`;

        // Fetch current state for all IDs
        const ids = entries.map((e: any) => e.id).filter(Boolean);
        const { data: currentEntries } = await supabase
            .from('timetables')
            .select('id, day_of_week')
            .in('id', ids);

        if (!currentEntries) {
            throw new Error('Failed to fetch current entries');
        }

        // Create map of id -> current_day
        const currentDayMap = new Map(currentEntries.map(e => [e.id, e.day_of_week]));

        // Phase 1: Move to TEMP using CURRENT day (not target day)
        for (const entry of entries) {
            if (entry.id) {
                const currentDay = currentDayMap.get(entry.id);
                if (currentDay) {
                    await supabase
                        .from('timetables')
                        .update({ day_of_week: `${tempPrefix}${currentDay}` })
                        .eq('id', entry.id);
                }
            }
        }

        // 2. Phase 2: Finalization
        // Move them to the actual target day.
        const results = [];
        for (const entry of entries) {
            const { id, day_of_week } = entry;
            if (id && day_of_week) {
                const { data, error } = await supabase
                    .from('timetables')
                    .update({ day_of_week: day_of_week })
                    .eq('id', id)
                    .select();

                if (error) {
                    console.error('Phase 2 Error:', error);
                    throw error;
                }
                if (data) results.push(data[0]);
            }
        }

        res.json({ message: 'Batch update successful', count: results.length, data: results });
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

        // COLLISION HANDLING (SWAP LOGIC):
        // If we are changing the time/day, check if the TARGET slot is already occupied.
        // If so, MOVE the occupied class to the CURRENT slot of the class being edited (SWAP).
        if (day_of_week && start_time && department && year && section) {
            // 1. Fetch Current State of the entry being moved (Source)
            const { data: currentEntry } = await supabase
                .from('timetables')
                .select('day_of_week, start_time, end_time')
                .eq('id', id)
                .single();

            if (currentEntry) {
                // 2. Check for Collision at Target
                const { data: collision } = await supabase
                    .from('timetables')
                    .select('id')
                    .match({
                        department,
                        year,
                        section,
                        day_of_week,
                        start_time
                    })
                    .neq('id', id)
                    .single();

                if (collision) {
                    console.log(`Swap: Moving collision ${collision.id} to Source ${currentEntry.start_time}`);
                    // Move the colliding entry to the Source slot
                    await supabase
                        .from('timetables')
                        .update({
                            day_of_week: currentEntry.day_of_week,
                            start_time: currentEntry.start_time,
                            end_time: currentEntry.end_time,
                            user_id: userId
                        })
                        .eq('id', collision.id);
                }
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

export const importTimetable = async (req: Request, res: Response): Promise<void> => {
    try {
        const file = (req as any).file;
        if (!file) {
            res.status(400).json({ error: 'No file uploaded' });
            return;
        }

        const userId = (req as WithAuthProp<Request>).auth.userId;
        const rows = parseFile(file.buffer);

        if (rows.length === 0) {
            res.status(400).json({ error: 'CSV file is empty or invalid' });
            return;
        }

        // Map CSV rows to Database Columns
        // Expected Headers: course_code, course_name, day, start_time, end_time, location, department, year, section
        const entries = rows.map(row => ({
            user_id: userId,
            day_of_week: row['day'] || row['day_of_week'] || 'Monday',
            start_time: row['start_time'],
            end_time: row['end_time'],
            course_code: row['course_code'],
            course_name: row['course_name'],
            location: row['location'],
            department: row['department'],
            year: row['year'],
            section: row['section']
        })).filter(e => e.day_of_week && e.course_code && e.start_time); // Basic Filter

        if (entries.length === 0) {
            res.status(400).json({ error: 'No valid entries found in CSV. Check headers.' });
            return;
        }

        // 1. Identify affected groups (Department + Year + Section)
        const groups = new Set<string>();
        entries.forEach(e => {
            if (e.department && e.year && e.section) {
                groups.add(`${e.department}|${e.year}|${e.section}`);
            }
        });

        // 2. Clear existing entries for these groups (Replacement Policy)
        // We do this serially or in parallel, but serial is safer to avoid deadlocks
        console.log(`Import: Clearing existing data for ${groups.size} groups...`);
        for (const groupKey of groups) {
            const [dept, yr, sec] = groupKey.split('|');
            const { error: deleteError } = await supabase
                .from('timetables')
                .delete()
                .eq('department', dept)
                .eq('year', yr)
                .eq('section', sec);

            if (deleteError) throw deleteError;
        }

        // 3. Insert new entries
        const { error } = await supabase
            .from('timetables')
            .insert(entries);

        if (error) throw error;

        res.status(201).json({
            message: `Successfully imported ${entries.length} entries (Replaced existing schedules).`,
            count: entries.length
        });

    } catch (error: any) {
        console.error('Import Error:', error);
        res.status(500).json({ error: error.message });
    }
};
