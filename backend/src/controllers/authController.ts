import { Request, Response } from 'express';
import { clerkClient } from '@clerk/clerk-sdk-node';
import { supabase } from '../services/supabaseClient';
import { WithAuthProp } from '@clerk/clerk-sdk-node';

export const updateUserRole = async (req: Request, res: Response) => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { role, code, department, year, section } = req.body;

        console.log(`[updateUserRole] Request for userId: ${userId}, role: ${role}`);

        if (!userId) {
            return res.status(401).json({ error: "Unauthorized" });
        }

        if (!['student', 'faculty', 'admin'].includes(role)) {
            return res.status(400).json({ error: "Invalid role" });
        }

        // Verify Access Codes for Privileged Roles
        if (role === 'admin') {
            if (code !== process.env.ADMIN_SECRET) {
                return res.status(403).json({ error: "Invalid Admin Access Code" });
            }
        }

        if (role === 'faculty') {
            if (code !== process.env.FACULTY_SECRET) {
                return res.status(403).json({ error: "Invalid Faculty Access Code" });
            }
        }

        // Update Clerk Metadata (Skip for mock users)
        if (!userId.startsWith('user_mock_')) {
            try {
                await clerkClient.users.updateUser(userId, {
                    publicMetadata: { role: role }
                });
            } catch (clerkError) {
                console.warn("[updateUserRole] Clerk update failed (ignoring):", clerkError);
            }
        }

        // Sync with Supabase Profile
        const profileUpdate: any = { role };
        if (department) profileUpdate.department = department;
        if (year) profileUpdate.year = year;
        if (section) profileUpdate.section = section;

        console.log(`[updateUserRole] Syncing to Supabase Profile:`, profileUpdate);

        const { data: updatedProfile, error: updateError } = await supabase
            .from('profiles')
            .update(profileUpdate)
            .eq('id', userId)
            .select()
            .single();

        if (updateError) {
            console.error('[updateUserRole] Supabase Update Error:', JSON.stringify(updateError, null, 2));
            throw updateError;
        }

        console.log(`[updateUserRole] Success:`, updatedProfile);
        res.status(200).json(updatedProfile);
    } catch (error) {
        console.error("Error updating role:", error);
        res.status(500).json({ error: "Failed to update role", details: error });
    }
};

export const syncUser = async (req: Request, res: Response) => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;
        const { email, fullName, avatarUrl } = req.body;

        console.log(`[syncUser] Request for userId: ${userId}, email: ${email}`);

        if (!userId) {
            return res.status(401).json({ error: "Unauthorized" });
        }

        // Check if profile exists
        const { data: profile, error: fetchError } = await supabase
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .single();

        if (profile) {
            // Profile exists
            return res.json({ ...profile, is_new_user: false });
        }

        // Profile doesn't exist (First Login)
        // No default role - user must complete onboarding
        console.log(`[syncUser] Creating new profile for ${userId}`);
        const newProfile = {
            id: userId,
            email,
            full_name: fullName,
            avatar_url: avatarUrl,
            role: null, // Force role selection by overriding DB default
        };

        const { data: createdProfile, error: insertError } = await supabase
            .from('profiles')
            .insert([newProfile])
            .select()
            .single();

        if (insertError) {
            console.error(`[syncUser] Supabase Insert Error for userId: ${userId}:`, insertError);
            throw insertError;
        }

        res.status(201).json({ ...createdProfile, is_new_user: true });

    } catch (error) {
        console.error(`[syncUser] Error syncing user for userId: ${(req as WithAuthProp<Request>).auth?.userId}:`, error);
        res.status(500).json({ error: "Failed to sync user", details: error });
    }
};

export const resetProfile = async (req: Request, res: Response) => {
    try {
        const userId = (req as WithAuthProp<Request>).auth.userId;

        if (!userId) {
            return res.status(401).json({ error: "Unauthorized" });
        }

        const { error } = await supabase
            .from('profiles')
            .update({
                role: null,
                department: null,
                year: null,
                section: null
            })
            .eq('id', userId);

        if (error) {
            console.error(`[resetProfile] Supabase Error for userId: ${userId}:`, error);
            throw error;
        }

        res.status(200).json({ message: "Profile reset successfully" });
    } catch (error) {
        console.error(`[resetProfile] Error resetting profile for userId: ${(req as WithAuthProp<Request>).auth?.userId}:`, error);
        res.status(500).json({ error: "Failed to reset profile", details: error });
    }
};
