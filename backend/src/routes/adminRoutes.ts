import express from 'express';
import { requireAuth, requireAdmin } from '../middleware/authMiddleware';
import { getAllUsers, updateUserDetails, bulkUpdateUsers } from '../controllers/adminController';
import { generateInvite, listInvites, deleteInvite } from '../controllers/invitationController';

const router = express.Router();

// 🔒 SECURE ALL ROUTES: Must be Authenticated AND have Admin Access
router.use(requireAuth);
router.use(requireAdmin);

// GET /api/admin/users
router.get('/users', getAllUsers);

// POST /api/admin/users/bulk-update
router.post('/users/bulk-update', bulkUpdateUsers);

// PUT /api/admin/users/:id
router.put('/users/:id', updateUserDetails);

// Invitations
router.post('/invitations/generate', generateInvite);
router.get('/invitations/list', listInvites);
router.delete('/invitations/:code', deleteInvite);

export default router;
