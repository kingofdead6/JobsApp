import Notification from '../models/Notification.js';
import User from '../models/User.js';
import { getIo } from './socket.js';

/**
 * ينشئ إشعارًا في قاعدة البيانات ويدفعه آنيًا عبر Socket.IO.
 * دفع Firebase (FCM) يُضاف هنا عند توفّر مفاتيح المشروع.
 */
export async function notify({ user, type, title, body, data }) {
  const prefs = await User.findById(user).select('notificationPrefs');
  if (!prefs) return null;

  // احترام تفضيلات المستخدم
  const gate = {
    matching_offer: prefs.notificationPrefs?.matchingOffers,
    application_status: prefs.notificationPrefs?.applicationStatus,
    new_message: prefs.notificationPrefs?.messages,
  }[type];
  if (gate === false) return null;

  const notification = await Notification.create({ user, type, title, body, data });

  const io = getIo();
  if (io) {
    io.to(`user:${user}`).emit('notification', {
      _id: notification._id,
      type,
      title,
      body,
      data,
      createdAt: notification.createdAt,
    });
  }

  return notification;
}

// إشعار جماعي من لوحة الإدارة (الفصل 4 — المحتوى الترويجي)
export async function broadcast({ title, body, role }) {
  const filter = { status: 'active' };
  if (role) filter.role = role;

  const users = await User.find(filter).select('_id');
  if (!users.length) return 0;

  await Notification.insertMany(
    users.map((u) => ({ user: u._id, type: 'broadcast', title, body }))
  );

  const io = getIo();
  if (io) {
    users.forEach((u) =>
      io.to(`user:${u._id}`).emit('notification', { type: 'broadcast', title, body })
    );
  }

  return users.length;
}
