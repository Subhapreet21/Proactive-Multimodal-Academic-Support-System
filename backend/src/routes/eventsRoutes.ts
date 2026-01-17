import { Router } from 'express';
import { getEvents, addEvent, deleteEvent, updateEvent } from '../controllers/eventsController';
import { requireAuth } from '../middleware/authMiddleware';
import { requireRole } from '../middleware/roleMiddleware';

const router = Router();

router.get('/', requireAuth, getEvents);
router.post('/', requireAuth, requireRole(['admin']), addEvent);
router.put('/:id', requireAuth, requireRole(['admin']), updateEvent);
router.delete('/:id', requireAuth, requireRole(['admin']), deleteEvent);

export default router;
