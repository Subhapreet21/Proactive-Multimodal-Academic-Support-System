import express from 'express';
import { getAllUsers, updateUserDetails, bulkUpdateUsers } from '../controllers/adminController';

const router = express.Router();

// GET /api/admin/users
router.get('/users', getAllUsers);

// POST /api/admin/users/bulk-update
router.post('/users/bulk-update', bulkUpdateUsers);

// PUT /api/admin/users/:id
router.put('/users/:id', updateUserDetails);

export default router;
