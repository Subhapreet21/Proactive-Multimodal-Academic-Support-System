import express from 'express';
import { requireAuth } from '../middleware/authMiddleware';
import { getClassAttendance, markAttendance, getStudentAttendance, getAdminStats, getFilteredStudentAttendance } from '../controllers/attendanceController';

const router = express.Router();

router.use(requireAuth);

router.get('/class', getClassAttendance);
router.post('/mark', markAttendance);
router.get('/student', getStudentAttendance);
router.get('/admin/stats', getAdminStats);
router.get('/filtered-students', getFilteredStudentAttendance);

export default router;
