import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const port = process.env.PORT || 8000;

app.use(cors());
app.use(express.json());

// Request logger
app.use((req, res, next) => {
    console.log(`📡 [${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
});
// import fileUpload from 'express-fileupload';
// app.use(fileUpload()); // Removed to fix conflict with Multer

app.get('/', (req, res) => {
    res.send('Campus Assistant API is running');
});

import { supabase } from './services/supabaseClient';

app.get('/api/health', (req, res) => {
    // 1. Respond INSTANTLY to Uptime Robot (Prevent 503/Timeout)
    res.json({
        status: 'online',
        timestamp: new Date().toISOString(),
        note: 'Background DB Ping Initiated'
    });

    // 2. Fire-and-forget DB Query to wake up Supabase (Background)
    supabase.from('profiles').select('id').limit(1)
        .then(({ error }) => {
            if (error) console.error('Background DB Ping Failed:', error.message);
            else console.log('Background DB Ping Success');
        });
});

import chatRoutes from './routes/chatRoutes';
import timetableRoutes from './routes/timetableRoutes';
import remindersRoutes from './routes/remindersRoutes';
import kbRoutes from './routes/kbRoutes';
import eventsRoutes from './routes/eventsRoutes';
import dashboardRoutes from './routes/dashboardRoutes';
import profileRoutes from './routes/profileRoutes';
import authRoutes from './routes/authRoutes';
import studyRoutes from './routes/studyRoutes';
import tourAssistantRoutes from './routes/tourAssistantRoutes';
import adminRoutes from './routes/adminRoutes';

app.use('/api/chat', chatRoutes);
app.use('/api/timetable', timetableRoutes);
app.use('/api/reminders', remindersRoutes);
app.use('/api/kb', kbRoutes);
app.use('/api/events', eventsRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/study', studyRoutes);
app.use('/api/virtual-tour', tourAssistantRoutes);
app.use('/api/admin', adminRoutes);
import lectureRoutes from './routes/lectureRoutes';
app.use('/api/lectures', lectureRoutes);

// Fallback 404 handler
app.use((req, res) => {
    console.log(`🚫 [404 Not Found] ${req.method} ${req.url}`);
    res.status(404).json({ error: 'Route not found', path: req.url });
});

import os from 'os';

const server = app.listen(Number(port), '0.0.0.0', () => {
    const interfaces = os.networkInterfaces();
    const addresses: string[] = [];

    for (const k in interfaces) {
        for (const k2 in interfaces[k]!) {
            const address = interfaces[k]![k2];
            if (address.family === 'IPv4' && !address.internal) {
                addresses.push(address.address);
            }
        }
    }

    console.log(`\n🚀 Backend is running!`);
    console.log(`🏠 Local: http://localhost:${port}`);
    addresses.forEach(addr => {
        console.log(`📱 Mobile Access: http://${addr}:${port}`);
    });
    console.log(`\n⚠️  Ensure your phone is on the same Wi-Fi and use one of the "Mobile Access" URLs in your .env\n`);
});
