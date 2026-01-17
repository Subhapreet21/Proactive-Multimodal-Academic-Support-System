import { Router } from 'express';
import { getTimetable, addTimetableEntry, deleteTimetableEntry, updateTimetableEntry } from '../controllers/timetableController';
import { requireAuth } from '../middleware/authMiddleware';
import { requireRole } from '../middleware/roleMiddleware';

const router = Router();

router.get('/', requireAuth, getTimetable);
router.post('/', requireAuth, requireRole(['admin', 'faculty']), addTimetableEntry);
router.put('/:id', requireAuth, requireRole(['admin', 'faculty']), updateTimetableEntry);
router.delete('/:id', requireAuth, requireRole(['admin', 'faculty']), deleteTimetableEntry);

export default router;
