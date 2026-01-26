import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';
import { WithAuthProp } from '@clerk/clerk-sdk-node';

export const getDashboardStats = async (req: Request, res: Response): Promise<void> => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;

        if (!userId) {
            res.status(401).json({ error: 'Unauthorized' });
            return;
        }

        // 0. Get User Profile to determine Role & Filter
        const { data: profile } = await supabase
            .from('profiles')
            .select('role, department, year, section')
            .eq('id', userId)
            .single();

        if (!profile) {
            res.status(404).json({ error: 'Profile not found' });
            return;
        }

        const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const now = new Date();
        const today = days[now.getDay()];
        // Format time as HH:MM:00 for comparison
        const currentTime = now.toTimeString().split(' ')[0];

        // Helper to build base query based on Role
        const getBaseTimetableQuery = () => {
            let query = supabase.from('timetables').select('*');

            if (profile.role === 'student') {
                // Students see classes for their Group
                if (!profile.department || !profile.year || !profile.section) {
                    // Incomplete profile, return empty builder that yields nothing? 
                    // Or manage error. For now, strict filter.
                    return query.eq('id', '00000000-0000-0000-0000-000000000000'); // Dummy UUID to force empty
                }
                return query
                    .eq('department', profile.department)
                    .eq('year', profile.year)
                    .eq('section', profile.section);
            } else if (profile.role === 'faculty') {
                // Faculty see all classes in their department
                if (!profile.department) {
                    return query.eq('id', '00000000-0000-0000-0000-000000000000');
                }
                return query.eq('department', profile.department);
            } else {
                // Admin sees ALL classes (God Mode)
                return query;
            }
        };

        // 1. Next Class Logic (Look ahead)
        // First try to find a class later today
        let { data: todaysClasses } = await getBaseTimetableQuery()
            .eq('day_of_week', today)
            .gt('start_time', currentTime)
            .order('start_time', { ascending: true })
            .limit(1);

        let nextClass = todaysClasses?.[0] || null;

        // If no class later today, look for the next available class in the coming days
        if (!nextClass) {
            const dayOrder = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
            const currentDayIndex = now.getDay();

            for (let i = 1; i <= 7; i++) {
                const nextDayIndex = (currentDayIndex + i) % 7;
                const nextDayName = dayOrder[nextDayIndex];

                const { data: upcomingClasses } = await getBaseTimetableQuery()
                    .eq('day_of_week', nextDayName)
                    .order('start_time', { ascending: true })
                    .limit(1);

                if (upcomingClasses && upcomingClasses.length > 0) {
                    nextClass = upcomingClasses[0];
                    // Add a formatted flag to indicate it's not today (optional, for frontend)
                    (nextClass as any).isToday = false;
                    (nextClass as any).nextDay = nextDayName;
                    break;
                }
            }
        } else {
            (nextClass as any).isToday = true;
        }

        // 2. Pending Reminders (Top 3 due soon)
        const { data: reminders } = await supabase
            .from('reminders')
            .select('*')
            .eq('user_id', userId)
            .eq('is_completed', false)
            .order('due_at', { ascending: true })
            .limit(3);

        // 3. Recent Notices (Top 3)
        const { data: events } = await supabase
            .from('events_notices')
            .select('*')
            .order('created_at', { ascending: false })
            .limit(3);

        res.json({
            nextClass,
            reminders: reminders || [],
            events: events || []
        });

    } catch (error: any) {
        console.error("Dashboard Error:", error);
        res.status(500).json({ error: error.message });
    }
};
