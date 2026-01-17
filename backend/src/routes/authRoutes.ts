import express from 'express';
import { requireAuth } from '../middleware/authMiddleware';
import { updateUserRole, syncUser, resetProfile } from '../controllers/authController';

const router = express.Router();

// Protected route: User must be signed in to set their role
router.post('/role', requireAuth, updateUserRole);
router.post('/sync', requireAuth, syncUser);
router.post('/reset-profile', requireAuth, resetProfile);

export default router;
