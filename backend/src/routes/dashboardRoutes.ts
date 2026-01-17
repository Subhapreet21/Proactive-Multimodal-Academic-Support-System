import { Router } from 'express';
import { getDashboardStats } from '../controllers/dashboardController';
import { requireAuth } from '../middleware/authMiddleware';

const router = Router();

router.get('/', requireAuth, getDashboardStats);

export default router;
