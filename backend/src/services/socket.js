import { Server } from 'socket.io';
import jwt from 'jsonwebtoken';
import User from '../models/User.js';

let io = null;

export function getIo() {
  return io;
}

/**
 * يُنشئ خادم Socket.IO ويربط كل مستخدم بغرفة خاصة `user:<id>`
 * تُستعمل لبثّ الرسائل والإشعارات الفورية (3.7).
 */
export function initSocket(httpServer) {
  io = new Server(httpServer, {
    cors: { origin: process.env.CLIENT_ORIGIN?.split(',') || '*', credentials: true },
  });

  // المصادقة على مستوى الاتصال — لا اتصال دون رمز صالح
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (!token) return next(new Error('رمز الدخول مفقود'));

      const payload = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(payload.id).select('_id status');
      if (!user || user.status !== 'active') return next(new Error('حساب غير صالح'));

      socket.userId = String(user._id);
      next();
    } catch {
      next(new Error('رمز الدخول غير صالح'));
    }
  });

  io.on('connection', (socket) => {
    socket.join(`user:${socket.userId}`);

    // إشعار الطرف الآخر بأن المستخدم يكتب
    socket.on('typing', ({ conversationId, to }) => {
      if (to) socket.to(`user:${to}`).emit('typing', { conversationId, from: socket.userId });
    });

    socket.on('disconnect', () => {
      socket.leave(`user:${socket.userId}`);
    });
  });

  return io;
}
