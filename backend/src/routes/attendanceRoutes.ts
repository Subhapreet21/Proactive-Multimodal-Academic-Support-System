import express from 'express';
import { requireAuth } from '../middleware/authMiddleware';
import { getClassAttendance, markAttendance, getStudentAttendance, getAdminStats, getFilteredStudentAttendance, getStudentHistory } from '../controllers/attendanceController';
import { getStudentForecast, getDepartmentForecast, forceRefreshAudit } from '../controllers/aiForecastController';

const router = express.Router();

router.use(requireAuth);

router.get('/class', getClassAttendance);
router.post('/mark', markAttendance);
router.get('/student', getStudentAttendance);
router.get('/student/history', getStudentHistory);
router.get('/admin/stats', getAdminStats);
router.get('/filtered-students', getFilteredStudentAttendance);

// AI Forecast Routes
router.get('/ai/forecast-student/:id', getStudentForecast);
router.get('/ai/forecast-department', getDepartmentForecast);
router.post('/ai/refresh-audit', forceRefreshAudit);

export default router;
