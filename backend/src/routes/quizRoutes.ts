import { Router } from 'express';
import {
    generateQuizFromKB,
    getQuizzes,
    submitAttempt,
    importQuizFromExcel,
    manualQuizCreation,
    updateQuiz,
    deleteQuiz,
    generateAIOverview,
    getOverviews
} from '../controllers/quizController';
import { requireAuth } from '../middleware/authMiddleware';
import { requireRole } from '../middleware/roleMiddleware';
import multer from 'multer';

// Setup multer to process multipart/form-data into memory
const upload = multer({ storage: multer.memoryStorage() });

const router = Router();

// ============================================
// Public/Student Interactive Routes
// ============================================

// GET /api/quizzes -> List all quizzes
router.get('/', requireAuth, getQuizzes);

// --- ATTEMPTS & OVERVIEWS ---
router.post('/attempts', requireAuth, submitAttempt);

// Get explicitly generated overviews
router.get('/overviews', requireAuth, getOverviews); // Should be above /:id to not conflict with ID param route

// Generate a personalized summary of a student's attempts on a specific quiz
router.post('/:id/generate-overview', requireAuth, generateAIOverview);

// ============================================
// Faculty / Admin Management Routes
// ============================================

// POST /api/quizzes/generate -> AI Generation from KB
router.post('/generate', requireAuth, requireRole(['faculty', 'admin']), generateQuizFromKB);

// POST /api/quizzes/import -> Bulk Excel Upload
router.post('/import', requireAuth, requireRole(['faculty', 'admin']), upload.single('file'), importQuizFromExcel);

// POST /api/quizzes/manual -> Standard Creation
router.post('/manual', requireAuth, requireRole(['faculty', 'admin']), manualQuizCreation);

// PUT /api/quizzes/:id -> Update quiz metadata
router.put('/:id', requireAuth, requireRole(['faculty', 'admin']), updateQuiz);

// DELETE /api/quizzes/:id -> Delete a quiz
router.delete('/:id', requireAuth, requireRole(['faculty', 'admin']), deleteQuiz);

export default router;
