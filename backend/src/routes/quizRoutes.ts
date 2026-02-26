import { Router } from 'express';
import {
    generateQuizFromKB,
    getQuizzes,
    submitAttempt,
    importQuizFromExcel,
    manualQuizCreation,
    updateQuiz,
    deleteQuiz
} from '../controllers/quizController';
import { requireAuth } from '../middleware/authMiddleware';
import { requireRole } from '../middleware/roleMiddleware';

const router = Router();

// ============================================
// Public/Student Interactive Routes
// ============================================

// GET /api/quizzes -> List all quizzes
router.get('/', requireAuth, getQuizzes);

// POST /api/quizzes/attempt -> Submit a quiz and get AI Feedback
router.post('/attempt', requireAuth, requireRole(['student']), submitAttempt);

// ============================================
// Faculty / Admin Management Routes
// ============================================

// POST /api/quizzes/generate -> AI Generation from KB
router.post('/generate', requireAuth, requireRole(['faculty', 'admin']), generateQuizFromKB);

// POST /api/quizzes/import -> Bulk Excel Upload
// Note: In a real app this would use multer for file parsing before hitting the controller
router.post('/import', requireAuth, requireRole(['faculty', 'admin']), importQuizFromExcel);

// POST /api/quizzes/manual -> Standard Creation
router.post('/manual', requireAuth, requireRole(['faculty', 'admin']), manualQuizCreation);

// PUT /api/quizzes/:id -> Update quiz metadata
router.put('/:id', requireAuth, requireRole(['faculty', 'admin']), updateQuiz);

// DELETE /api/quizzes/:id -> Delete a quiz
router.delete('/:id', requireAuth, requireRole(['faculty', 'admin']), deleteQuiz);

export default router;
