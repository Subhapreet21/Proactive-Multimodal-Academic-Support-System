import { Router } from 'express';
import { getReminders, addReminder, updateReminderStatus, updateReminderDetails, deleteReminder } from '../controllers/remindersController';
import { requireAuth } from '../middleware/authMiddleware';

const router = Router();

router.get('/', requireAuth, getReminders);
router.post('/', requireAuth, addReminder);
router.patch('/:id', requireAuth, updateReminderStatus);
router.put('/:id', requireAuth, updateReminderDetails); // New endpoint for full updates
router.delete('/:id', requireAuth, deleteReminder);

export default router;
