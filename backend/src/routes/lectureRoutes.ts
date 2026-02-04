
import express from 'express';
import { getFacultySubjects, generateLecturePlan } from '../controllers/lecturesController';

const router = express.Router();

router.get('/subjects', getFacultySubjects);
router.post('/generate', generateLecturePlan);

export default router;
