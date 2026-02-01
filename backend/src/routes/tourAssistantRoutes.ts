import { Router } from 'express';
import { askTourAssistant } from '../controllers/tourAssistantController';
import { requireAuth } from '../middleware/authMiddleware';

const router = Router();

router.post('/ask', requireAuth, askTourAssistant);

export default router;
