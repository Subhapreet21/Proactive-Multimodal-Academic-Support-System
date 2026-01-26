import { Request, Response } from 'express';
import { supabase } from '../services/supabaseClient';

const DEFAULT_STRUCTURE = [
    { "start": "09:00", "end": "10:00", "type": "class" },
    { "start": "10:00", "end": "11:00", "type": "class" },
    { "start": "11:00", "end": "11:10", "type": "break", "label": "Short Break" },
    { "start": "11:10", "end": "12:10", "type": "class" },
    { "start": "12:10", "end": "13:00", "type": "break", "label": "Lunch Break" },
    { "start": "13:00", "end": "14:00", "type": "class" },
    { "start": "14:00", "end": "15:00", "type": "class" }
];

export const getStructure = async (req: Request, res: Response) => {
    try {
        const { department } = req.query;

        // Build key: department-specific or global
        const key = department
            ? `timetable_structure_${department}`
            : 'timetable_structure';

        console.log(`📖 Fetching structure: ${key}`);

        const { data, error } = await supabase
            .from('timetable_metadata')
            .select('value')
            .eq('key', key)
            .single();

        if (error) {
            if (error.code === 'PGRST116') {
                // Not found: Try global fallback if department-specific was requested
                if (department) {
                    console.log(`⚠️ Department structure not found, trying global fallback...`);
                    const { data: fallbackData, error: fallbackError } = await supabase
                        .from('timetable_metadata')
                        .select('value')
                        .eq('key', 'timetable_structure')
                        .single();

                    if (!fallbackError && fallbackData) {
                        console.log(`✅ Using global fallback structure`);
                        return res.json(fallbackData.value);
                    }
                }

                // Return default structure
                console.log(`✅ Using default structure`);
                return res.json(DEFAULT_STRUCTURE);
            }
            throw error;
        }

        console.log(`✅ Structure found: ${key}`);
        res.json(data.value);
    } catch (error) {
        console.error('❌ Error fetching structure:', error);
        res.status(500).json({ error: 'Failed to fetch timetable structure' });
    }
};

export const updateStructure = async (req: Request, res: Response) => {
    try {
        const structure = req.body; // Expects JSON array of slots
        const { department } = req.query;

        if (!Array.isArray(structure)) {
            return res.status(400).json({ error: 'Invalid format. Expected array of slots.' });
        }

        // Build key: department-specific or global
        const key = department
            ? `timetable_structure_${department}`
            : 'timetable_structure';

        console.log(`🔄 Updating structure: ${key}`);

        // 1. Fetch OLD structure BEFORE updating
        const { data: oldData } = await supabase
            .from('timetable_metadata')
            .select('value')
            .eq('key', key)
            .single();


        // If department-specific not found, try global fallback
        let oldStructure = oldData?.value || [];
        if (!oldData && department) {
            console.log(`⚠️ Department structure not found, trying global fallback...`);
            const { data: fallbackData } = await supabase
                .from('timetable_metadata')
                .select('value')
                .eq('key', 'timetable_structure')
                .single();
            oldStructure = fallbackData?.value || [];
        }

        // 2. Perform Smart Migration (Shift Class Times)
        // We only care about moving 'class' slots. Breaks don't hold data.
        const oldClassSlots = oldStructure.filter((s: any) => s.type === 'class');
        const newClassSlots = structure.filter((s: any) => s.type === 'class');

        console.log(`🔄 Migrating Data${department ? ` for ${department}` : ''}: ${oldClassSlots.length} old slots -> ${newClassSlots.length} new slots`);
        console.log('   Old Class Slots:', JSON.stringify(oldClassSlots));
        console.log('   New Class Slots:', JSON.stringify(newClassSlots));

        // Identify Moves needed
        const moves: { oldStart: string, oldEnd: string, newStart: string, newEnd: string }[] = [];
        const toDelete: { start: string, end: string }[] = [];

        // Strategy: Use 'original_start' from client to identify content swaps.
        const hasIdentity = newClassSlots.some((s: any) => s.original_start);

        if (hasIdentity) {
            console.log('✅ Detected Identity-Based Update (Robust Swap)');
            // Track which old slots successfully matched to new slots
            const claimedMatchingOldStarts = new Set<string>();
            const claimedNewSlots = new Set<string>(); // New slots that found a home

            // 1. Primary Strategy: Identity & Position Matching
            for (const newSlot of newClassSlots) {
                if (newSlot.original_start && newSlot.start !== newSlot.original_start) {
                    // Match by original_start identity
                    let matchingOld = oldClassSlots.find((s: any) =>
                        (s.original_start || s.start) === newSlot.original_start
                    );

                    // Fallback: Check if the start time matches (Stayed in place)
                    if (!matchingOld) {
                        const potentialMatch = oldClassSlots.find((s: any) => s.start === newSlot.start);
                        if (potentialMatch && !claimedMatchingOldStarts.has(potentialMatch.start)) {
                            console.log(`   ℹ️ Fallback Match: Preserving slot at ${newSlot.start} despite identity mismatch.`);
                            matchingOld = potentialMatch;
                        }
                    }

                    if (matchingOld) {
                        claimedMatchingOldStarts.add(matchingOld.start);
                        claimedNewSlots.add(newSlot.start); // Using start as distinct key for new slot

                        if (matchingOld.start !== newSlot.start) {
                            moves.push({
                                oldStart: matchingOld.start, oldEnd: matchingOld.end,
                                newStart: newSlot.start, newEnd: newSlot.end
                            });
                            console.log(`   📝 Move: ${matchingOld.start} → ${newSlot.start} (identity: ${newSlot.original_start})`);
                        }
                    } else {
                        console.log(`   ⚠️ No match found for identity: ${newSlot.original_start}`);
                    }
                } else {
                    // Start == Original Start (It didn't move, or it's new)
                    const existing = oldClassSlots.find((s: any) => s.start === newSlot.start);
                    if (existing) {
                        claimedMatchingOldStarts.add(existing.start);
                        claimedNewSlots.add(newSlot.start);
                    }
                }
            }

            // 2. Secondary Strategy: Orphan Matching (Legacy Fallback)
            // If identity was reset, we might have orphans on both sides. Pair them up.
            const unmatchedOld = oldClassSlots.filter((s: any) => !claimedMatchingOldStarts.has(s.start));
            const unmatchedNew = newClassSlots.filter((s: any) => !claimedNewSlots.has(s.start));

            if (unmatchedOld.length > 0 && unmatchedNew.length > 0) {
                console.log(`   🔄 Attempting Orphan Matching: ${unmatchedOld.length} old vs ${unmatchedNew.length} new`);
                // Pair by index
                const limit = Math.min(unmatchedOld.length, unmatchedNew.length);
                for (let i = 0; i < limit; i++) {
                    const oldS = unmatchedOld[i];
                    const newS = unmatchedNew[i];

                    claimedMatchingOldStarts.add(oldS.start);
                    moves.push({
                        oldStart: oldS.start, oldEnd: oldS.end,
                        newStart: newS.start, newEnd: newS.end
                    });
                    console.log(`   📝 Rescue Move (Orphan): ${oldS.start} → ${newS.start}`);
                }
            }

            // Refined Deletion Logic: Only delete if STILL NOT claimed
            for (const old of oldClassSlots) {
                if (!claimedMatchingOldStarts.has(old.start)) {
                    toDelete.push({ start: old.start, end: old.end });
                    console.log(`   🗑️ Delete: ${old.start} (Not matched in new structure)`);
                }
            }
        } else {
            console.log('⚠️ Legacy Update (Index Matching)');
            for (let i = 0; i < oldClassSlots.length; i++) {
                const oldSlot = oldClassSlots[i];
                if (i < newClassSlots.length) {
                    const newSlot = newClassSlots[i];
                    if (oldSlot.start !== newSlot.start || oldSlot.end !== newSlot.end) {
                        moves.push({
                            oldStart: oldSlot.start, oldEnd: oldSlot.end,
                            newStart: newSlot.start, newEnd: newSlot.end
                        });
                    }
                } else {
                    toDelete.push({ start: oldSlot.start, end: oldSlot.end });
                }
            }
        }

        // Phase 1: Fetch IDs to move (Parallel) - WITH DEPARTMENT FILTER
        console.log('   Phase 1: Fetching Row IDs (Parallel)...');

        const movesWithIds = (await Promise.all(moves.map(async (move) => {
            let ids: string[] = [];

            // Build query with department filter
            let query1 = supabase.from('timetables').select('id').eq('start_time', move.oldStart);
            if (department) {
                query1 = query1.eq('department', department);
            }

            const res1 = await query1;
            if (res1.data && res1.data.length > 0) {
                ids = res1.data.map(r => r.id);
            } else {
                // Attempt 2: Try Format HH:MM:SS
                let query2 = supabase.from('timetables').select('id').eq('start_time', `${move.oldStart}:00`);
                if (department) {
                    query2 = query2.eq('department', department);
                }

                const res2 = await query2;
                if (res2.data && res2.data.length > 0) {
                    ids = res2.data.map(r => r.id);
                }
            }

            if (ids.length > 0) {
                console.log(`      Found ${ids.length} rows for ${move.oldStart}${department ? ` in ${department}` : ''}`);
                return { ids, newStart: move.newStart, newEnd: move.newEnd };
            } else {
                console.log(`      No rows found for ${move.oldStart}${department ? ` in ${department}` : ''}`);
                return null;
            }
        }))).filter((m): m is { ids: string[], newStart: string, newEnd: string } => m !== null);

        // Phase 2: Move to Safe Temporary Time (Parallel)
        console.log(`   Phase 2: Shifting ${movesWithIds.length} groups to Temp (Parallel)...`);
        await Promise.all(movesWithIds.map(async (move, i) => {
            const tempStart = `00:00:${(i + 10).toString().padStart(2, '0')}`;
            const tempEnd = `00:01:${(i + 10).toString().padStart(2, '0')}`;
            await supabase.from('timetables').update({ start_time: tempStart, end_time: tempEnd }).in('id', move.ids);
        }));

        // Phase 3: Move to Final Time (Parallel)
        console.log(`   Phase 3: Shifting to Final Destinations (Parallel)...`);
        await Promise.all(movesWithIds.map(async (move) => {
            await supabase.from('timetables').update({ start_time: move.newStart, end_time: move.newEnd }).in('id', move.ids);
        }));

        // Cleanup Deletions (Parallel) - WITH DEPARTMENT FILTER
        console.log(`   Final: Cleanup Deletions (Parallel)...`);
        await Promise.all(toDelete.map(async (del) => {
            let query1 = supabase.from('timetables').select('id').eq('start_time', del.start);
            if (department) {
                query1 = query1.eq('department', department);
            }

            const res1 = await query1;
            let ids = res1.data?.map(r => r.id) || [];

            if (ids.length === 0) {
                let query2 = supabase.from('timetables').select('id').eq('start_time', `${del.start}:00`);
                if (department) {
                    query2 = query2.eq('department', department);
                }

                const res2 = await query2;
                ids = res2.data?.map(r => r.id) || [];
            }

            if (ids.length > 0) {
                await supabase.from('timetables').delete().in('id', ids);
            }
        }));

        // 3. Save NEW structure with department-specific key
        const { error } = await supabase
            .from('timetable_metadata')
            .upsert({
                key: key,
                value: structure,
                updated_at: new Date()
            }, { onConflict: 'key' });

        if (error) throw error;

        console.log(`✅ Structure updated: ${key}`);
        res.json({
            message: 'Structure updated and data migrated successfully',
            department: department || 'global',
            key: key
        });
    } catch (error) {
        console.error('❌ Error updating structure:', error);
        res.status(500).json({ error: 'Failed to update timetable structure' });
    }
};
