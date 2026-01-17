
import express from 'express';
import { generateStudyPlan } from '../controllers/studyController';

const router = express.Router();

router.post('/generate', generateStudyPlan);

export default router;
