import { Router } from 'express';
import multer from 'multer';
import { getTimetable, addTimetableEntry, deleteTimetableEntry, updateTimetableEntry, importTimetable, batchUpdateTimetable } from '../controllers/timetableController';
import { getStructure, updateStructure } from '../controllers/configController';
import { requireAuth } from '../middleware/authMiddleware';
import { requireRole } from '../middleware/roleMiddleware';

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

router.get('/', requireAuth, getTimetable);
router.post('/', requireAuth, requireRole(['admin']), addTimetableEntry);
router.post('/batch_update', requireAuth, requireRole(['admin']), batchUpdateTimetable);
router.post('/import', requireAuth, requireRole(['admin']), upload.single('file'), importTimetable);
router.put('/:id', requireAuth, requireRole(['admin']), updateTimetableEntry);
router.delete('/:id', requireAuth, requireRole(['admin']), deleteTimetableEntry);

// Structure Configuration Routes
router.get('/structure', requireAuth, getStructure);
router.post('/structure', requireAuth, requireRole(['admin']), updateStructure);

export default router;
