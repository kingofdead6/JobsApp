import 'dotenv/config';
import http from 'node:http';
import app from './app.js';
import { connectDB } from './config/db.js';
import { initSocket } from './services/socket.js';
import { startScheduler } from './services/scheduler.js';

const PORT = process.env.PORT || 5000;

async function start() {
  await connectDB();

  const server = http.createServer(app);
  initSocket(server);
  startScheduler();

  server.listen(PORT, () => {
    console.log(`[api] الخادم يعمل على المنفذ ${PORT} — الوضع: ${process.env.NODE_ENV}`);
  });

  // إيقاف نظيف حتى لا تُقطع الطلبات الجارية
  const shutdown = (signal) => {
    console.log(`\n[api] استلام ${signal}، جاري الإيقاف...`);
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(1), 10000).unref();
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));
}

start().catch((err) => {
  console.error('[api] فشل إقلاع الخادم:', err.message);
  process.exit(1);
});
