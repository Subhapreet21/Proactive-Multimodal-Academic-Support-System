import { Request, Response, NextFunction } from 'express';
import { supabase } from '../services/supabaseClient';

import { WithAuthProp } from '@clerk/clerk-sdk-node';

export const requireRole = (allowedRoles: string[]) => {
    return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
        const userId = (req as WithAuthProp<Request>).auth.userId;

        if (!userId) {
            res.status(401).json({ error: 'Unauthorized: No user found' });
            return;
        }

        try {
            const { data: profile, error } = await supabase
                .from('profiles')
                .select('role')
                .eq('id', userId)
                .single();

            if (error || !profile) {
                // If no profile, they are a student by default or something is wrong.
                // Depending on strictness. Let's assume strict.
                console.error("Role check error:", error);
                res.status(403).json({ error: 'Forbidden: Profile not found' });
                return;
            }

            if (!allowedRoles.includes(profile.role)) {
                res.status(403).json({ error: `Forbidden: Requires one of [${allowedRoles.join(', ')}] role` });
                return;
            }

            next();
        } catch (error) {
            console.error("Role middleware error:", error);
            res.status(500).json({ error: 'Server error checking role' });
        }
    };
};
