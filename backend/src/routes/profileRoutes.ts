import { Router } from 'express';
import { getProfile, updateProfile } from '../controllers/profileController';
import { requireAuth } from '../middleware/authMiddleware';

const router = Router();

router.get('/', requireAuth, getProfile);
router.post('/', requireAuth, updateProfile); // Using POST for upsert

export default router;
