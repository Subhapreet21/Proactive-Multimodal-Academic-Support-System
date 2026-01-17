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
