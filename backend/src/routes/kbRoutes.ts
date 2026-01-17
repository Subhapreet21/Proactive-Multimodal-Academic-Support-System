import { Router } from 'express';
import { searchKB, addArticle, getAllArticles, updateArticle, deleteArticle } from '../controllers/kbController';

import { requireAuth } from '../middleware/authMiddleware';
import { requireRole } from '../middleware/roleMiddleware';

const router = Router();

router.get('/search', requireAuth, searchKB); // Search is public or auth?
router.get('/', requireAuth, getAllArticles);
router.post('/', requireAuth, requireRole(['admin', 'faculty']), addArticle);
router.put('/:id', requireAuth, requireRole(['admin', 'faculty']), updateArticle);
router.delete('/:id', requireAuth, requireRole(['admin', 'faculty']), deleteArticle);

export default router;
