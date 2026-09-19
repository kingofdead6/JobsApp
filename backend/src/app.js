import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import rateLimit from 'express-rate-limit';
import path from 'node:path';

import authRoutes from './routes/authRoutes.js';
import jobRoutes from './routes/jobRoutes.js';
import applicationRoutes from './routes/applicationRoutes.js';
import profileRoutes from './routes/profileRoutes.js';
import companyRoutes from './routes/companyRoutes.js';
import savedRoutes from './routes/savedRoutes.js';
import messageRoutes from './routes/messageRoutes.js';
import miscRoutes from './routes/miscRoutes.js';
import adminRoutes from './routes/adminRoutes.js';
import { notFound, errorHandler } from './middleware/errorHandler.js';

const app = express();

app.set('trust proxy', 1);

// الملفات المرفوعة تُقدَّم من نطاق مختلف عن التطبيق
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

app.use(
  cors({
    origin: process.env.CLIENT_ORIGIN?.split(',') || '*',
    credentials: true,
  })
);

app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// حدّ عام لإساءة الاستعمال — الفصل 5
app.use(
  '/api',
  rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 600,
    message: { success: false, message: 'طلبات كثيرة جدًا، أعد المحاولة بعد قليل' },
    standardHeaders: true,
    legacyHeaders: false,
  })
);

// الملفات الثابتة (السير الذاتية، الشعارات، الصور)
app.use('/uploads', express.static(path.resolve('uploads'), { maxAge: '7d' }));

app.get('/api/health', (_req, res) =>
  res.json({ success: true, message: 'الخادم يعمل', timestamp: new Date().toISOString() })
);

app.use('/api/auth', authRoutes);
app.use('/api/jobs', jobRoutes);
app.use('/api/applications', applicationRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/companies', companyRoutes);
app.use('/api/saved', savedRoutes);
app.use('/api/messages', messageRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api', miscRoutes);

app.use(notFound);
app.use(errorHandler);

export default app;
