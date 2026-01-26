import { Router } from 'express';
import multer from 'multer';
import { handleTextChat, handleImageChat, getChatHistory, getConversations } from '../controllers/chatController';
import { requireAuth } from '../middleware/authMiddleware';

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

router.post('/text', requireAuth, handleTextChat);
router.post('/image', requireAuth, upload.single('image'), handleImageChat);
router.get('/history/:conversationId', requireAuth, getChatHistory);
router.get('/conversations', requireAuth, getConversations);

export default router;
