import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';

export const getAllUsers = async (req: Request, res: Response): Promise<void> => {
    try {
        const { role, search, department, year, section } = req.query;

        let query = supabase
            .from('profiles')
            .select('id, full_name, email, role, department, year, section, created_at, avatar_url')
            .order('created_at', { ascending: false });

        if (role && role !== 'All') {
            query = query.eq('role', role);
        }

        if (department && department !== 'All') {
            query = query.eq('department', department);
        }

        if (year && year !== 'All') {
            query = query.eq('year', year);
        }

        if (section && section !== 'All') {
            query = query.eq('section', section);
        }

        if (search) {
            query = query.ilike('full_name', `%${search}%`);
        }

        const { data, error } = await query;

        if (error) throw error;

        res.json(data);
    } catch (error: any) {
        console.error('Error fetching users:', error);
        res.status(500).json({ error: 'Failed to fetch users' });
    }
};

// Renamed and expanded from updateUserRole
export const updateUserDetails = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { role, full_name, department, year, section } = req.body;

        if (!role && !full_name && !department && !year && !section) {
            res.status(400).json({ error: 'No fields to update' });
            return;
        }

        const updates: any = {};
        if (role) updates.role = role;
        if (full_name !== undefined) updates.full_name = full_name;
        if (department !== undefined) updates.department = department;
        if (year !== undefined) updates.year = year;
        if (section !== undefined) updates.section = section;

        // 🛡️ SECURITY: Prevent demoting the last admin
        if (role && role !== 'admin') {
            // Check if target is currently an admin
            const { data: targetUser } = await supabase
                .from('profiles')
                .select('role')
                .eq('id', id)
                .single();

            if (targetUser?.role === 'admin') {
                // Check if there are other admins
                const { count } = await supabase
                    .from('profiles')
                    .select('*', { count: 'exact', head: true })
                    .eq('role', 'admin');

                if (count !== null && count <= 1) {
                    res.status(403).json({ error: 'Security: Cannot demote the last administrator.' });
                    return;
                }
            }
        }

        const { data, error } = await supabase
            .from('profiles')
            .update(updates)
            .eq('id', id)
            .select()
            .single();

        if (error) throw error;

        res.json(data);
    } catch (error: any) {
        console.error('Error updating user:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
};

export const bulkUpdateUsers = async (req: Request, res: Response): Promise<void> => {
    try {
        const { userIds, action, updates, preserveData } = req.body;

        if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
            res.status(400).json({ error: 'Invalid userIds' });
            return;
        }

        if (action === 'delete') {
            // Delete related data (GDPR/Clean-up) unless trying to preserve history (e.g. for admins)
            if (!preserveData) {
                await supabase.from('kb_articles').delete().in('author_id', userIds);
                await supabase.from('reminders').delete().in('user_id', userIds);
                await supabase.from('conversations').delete().in('user_id', userIds);
            } else {
                // Admin Deletion: Preserve KB Articles (Unlink them)
                await supabase.from('kb_articles').update({ author_id: null }).in('author_id', userIds);

                // Still need to delete personal data that would block profile deletion
                await supabase.from('reminders').delete().in('user_id', userIds);
                await supabase.from('conversations').delete().in('user_id', userIds);
            }

            // Delete from Auth (requires Service Role)
            const deletePromises = userIds.map((id: string) => supabase.auth.admin.deleteUser(id));
            await Promise.all(deletePromises);

            // Delete from Profiles
            await supabase.from('profiles').delete().in('id', userIds);

            res.json({ message: `Successfully deleted ${userIds.length} users` });
        } else if (action === 'update') {
            if (updates?.year_increment) {
                // Fetch current years
                const { data: users, error: fetchError } = await supabase
                    .from('profiles')
                    .select('id, year')
                    .in('id', userIds);

                if (fetchError) throw fetchError;

                // Prepare upserts
                const upserts = users?.map((user: any) => {
                    const currentYear = parseInt(user.year || '0');
                    const nextYear = currentYear < 4 ? currentYear + 1 : 4;
                    return {
                        id: user.id,
                        year: nextYear.toString()
                    };
                });

                if (upserts && upserts.length > 0) {
                    const { error: updateError } = await supabase
                        .from('profiles')
                        .upsert(upserts);

                    if (updateError) throw updateError;
                }
            }

            // Standard update (if year_increment was true, we might still have other updates? Assuming exclusive or sequential for now)
            // Actually, let's allow both. If updates has other fields, apply them too.
            const { year_increment, ...cleanUpdates } = updates || {};

            if (Object.keys(cleanUpdates).length > 0) {
                const { error } = await supabase
                    .from('profiles')
                    .update(cleanUpdates)
                    .in('id', userIds);

                if (error) throw error;
            }

            res.json({ message: `Successfully updated ${userIds.length} users` });
        } else {
            res.status(400).json({ error: 'Invalid action' });
        }
    } catch (error: any) {
        console.error('Error in bulk update:', error);
        res.status(500).json({ error: 'Bulk operation failed' });
    }
};
