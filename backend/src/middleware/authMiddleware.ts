// import { ClerkExpressRequireAuth } from '@clerk/clerk-sdk-node';
import { Request, Response, NextFunction } from 'express';

// Middleware to strictly require authentication
// const clerkAuth = ClerkExpressRequireAuth();

import { supabase } from '../services/supabaseClient';

export const requireAuth = async (req: Request, res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;

    // 1. ALLOW MOCK TOKENS FOR EASY DEVELOPMENT
    if (authHeader?.startsWith('Bearer mock_token_')) {
        const mockSuffix = authHeader.replace('Bearer mock_token_', '');
        (req as any).auth = {
            userId: `user_mock_${mockSuffix}`,
            sessionId: `sess_mock_${mockSuffix}`
        };
        return next();
    }

    // 2. CHECK SUPABASE AUTH
    if (authHeader) {
        const token = authHeader.replace('Bearer ', '');
        // console.log('🔍 [AuthMiddleware] Verifying token:', token.substring(0, 10) + '...');

        const { data: { user }, error } = await supabase.auth.getUser(token);

        if (error) {
            console.log('❌ [AuthMiddleware] Supabase Auth Error:', error.message);
        } else if (user) {
            // console.log('✅ [AuthMiddleware] User verified:', user.email);
            (req as any).auth = {
                userId: user.id,
                sessionId: 'supabase_session'
            };
            return next();
        }
    }

    // 3. IF NO VALID TOKEN -> 401 UNAUTHORIZED
    // We are migrating away from Clerk, so if Supabase text fails, we deny access.
    // return clerkAuth(req, res, next);

    console.log('❌ [AuthMiddleware] Unauthorized access attempt');
    return res.status(401).json({ error: 'Unauthorized: Invalid or missing token' });
};

// Optional: Helper to log or debug auth
export const debugAuth = (req: Request, res: Response, next: NextFunction) => {
    console.log("Auth Status:", (req as any).auth);
    next();
};

export const requireAdmin = async (req: Request, res: Response, next: NextFunction) => {
    // 1. Ensure User is Authenticated
    if (!(req as any).auth?.userId) {
        return res.status(401).json({ error: 'Unauthorized: Authentication required' });
    }

    const userId = (req as any).auth.userId;

    // 2. Allow Mock Admin for testing (if applicable)
    if (userId.startsWith('user_mock_admin')) {
        return next();
    }

    // 3. Check Role in Database
    try {
        const { data: profile, error } = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();

        if (error || !profile || profile.role !== 'admin') {
            console.warn(`⛔ [AuthMiddleware] Access denied for user ${userId}. Required: Admin, Found: ${profile?.role}`);
            return res.status(403).json({ error: 'Forbidden: Admin access required' });
        }

        next();
    } catch (err) {
        console.error('Error verifying admin role:', err);
        return res.status(500).json({ error: 'Internal Server Error' });
    }
};
