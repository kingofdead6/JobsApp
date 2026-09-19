import 'dotenv/config';
import http from 'node:http';
import app from './src/app.js';
import { connectDB } from './src/config/db.js';
import { initSocket } from './src/services/socket.js';
import { startScheduler } from './src/services/scheduler.js';

const PORT = process.env.PORT || 5006;

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
