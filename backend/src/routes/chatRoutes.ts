import { Router } from 'express';
import { handleTextChat, handleImageChat, getChatHistory, getConversations } from '../controllers/chatController';
import { requireAuth } from '../middleware/authMiddleware';

const router = Router();

router.post('/text', requireAuth, handleTextChat);
router.post('/image', requireAuth, handleImageChat);
router.get('/history/:conversationId', requireAuth, getChatHistory);
router.get('/conversations', requireAuth, getConversations);

export default router;
