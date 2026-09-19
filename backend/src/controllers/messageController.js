import Conversation from '../models/Conversation.js';
import Message from '../models/Message.js';
import Application from '../models/Application.js';
import { ApiError, asyncHandler } from '../utils/ApiError.js';
import { notify } from '../services/notificationService.js';
import { getIo } from '../services/socket.js';

// GET /api/messages/conversations — قائمة المحادثات (3.7)
export const listConversations = asyncHandler(async (req, res) => {
  const items = await Conversation.find({ participants: req.user._id })
    .sort({ lastMessageAt: -1 })
    .populate('participants', 'fullName avatar role')
    .populate('offer', 'title')
    .lean();

  // إظهار الطرف الآخر وعدد غير المقروء لهذا المستخدم
  const shaped = items.map((c) => ({
    ...c,
    otherParty: c.participants.find((p) => String(p._id) !== String(req.user._id)) || null,
    unreadCount: c.unread?.[String(req.user._id)] || 0,
  }));

  res.json({ success: true, data: { items: shaped } });
});

// GET /api/messages/conversations/:id — رسائل محادثة مع ترقيم الصفحات
export const getMessages = asyncHandler(async (req, res) => {
  const { page = 1, limit = 30 } = req.query;

  const conversation = await Conversation.findById(req.params.id)
    .populate('participants', 'fullName avatar role')
    .populate('offer', 'title');
  if (!conversation) throw new ApiError(404, 'المحادثة غير موجودة');

  const isMember = conversation.participants.some(
    (p) => String(p._id) === String(req.user._id)
  );
  if (!isMember) throw new ApiError(403, 'ليست لديك صلاحية');

  const perPage = Math.min(Number(limit) || 30, 60);
  const messages = await Message.find({ conversation: conversation._id })
    .sort({ createdAt: -1 })
    .skip((Math.max(Number(page) || 1, 1) - 1) * perPage)
    .limit(perPage)
    .lean();

  // تعليم رسائل الطرف الآخر كمقروءة
  await Message.updateMany(
    { conversation: conversation._id, sender: { $ne: req.user._id }, readAt: null },
    { readAt: new Date() }
  );
  conversation.unread.set(String(req.user._id), 0);
  await conversation.save();

  res.json({
    success: true,
    data: { conversation, messages: messages.reverse() },
  });
});

// POST /api/messages — إرسال رسالة (تُنشئ المحادثة إن لم تكن موجودة)
export const sendMessage = asyncHandler(async (req, res) => {
  const { conversationId, applicationId, body } = req.body;

  let conversation;

  if (conversationId) {
    conversation = await Conversation.findById(conversationId);
    if (!conversation) throw new ApiError(404, 'المحادثة غير موجودة');
    if (!conversation.participants.some((p) => String(p) === String(req.user._id))) {
      throw new ApiError(403, 'ليست لديك صلاحية');
    }
  } else if (applicationId) {
    // المحادثة تُفتح بعد تقديم الطلب فقط — 3.7
    const application = await Application.findById(applicationId).populate('offer', 'postedBy title');
    if (!application) throw new ApiError(404, 'الترشّح غير موجود');

    const seeker = String(application.applicant);
    const employer = String(application.offer.postedBy);
    const me = String(req.user._id);
    if (me !== seeker && me !== employer) throw new ApiError(403, 'ليست لديك صلاحية');

    conversation = await Conversation.findOne({ application: application._id });
    if (!conversation) {
      conversation = await Conversation.create({
        participants: [application.applicant, application.offer.postedBy],
        offer: application.offer._id,
        application: application._id,
      });
      application.conversation = conversation._id;
      await application.save();
    }
  } else {
    throw new ApiError(400, 'يجب تحديد المحادثة أو الترشّح');
  }

  const message = await Message.create({
    conversation: conversation._id,
    sender: req.user._id,
    body,
  });

  const recipient = conversation.participants.find(
    (p) => String(p) !== String(req.user._id)
  );

  conversation.lastMessage = body.slice(0, 200);
  conversation.lastMessageAt = message.createdAt;
  conversation.lastSender = req.user._id;
  conversation.unread.set(
    String(recipient),
    (conversation.unread.get(String(recipient)) || 0) + 1
  );
  await conversation.save();

  // بثّ آني للطرف الآخر
  const io = getIo();
  if (io) {
    io.to(`user:${recipient}`).emit('message:new', {
      conversationId: conversation._id,
      message: {
        _id: message._id,
        sender: req.user._id,
        body: message.body,
        createdAt: message.createdAt,
      },
    });
  }

  await notify({
    user: recipient,
    type: 'new_message',
    title: 'رسالة جديدة',
    body: `${req.user.fullName}: ${body.slice(0, 60)}`,
    data: { conversationId: conversation._id },
  });

  res.status(201).json({ success: true, data: { message, conversationId: conversation._id } });
});

// GET /api/messages/unread-count — للشارة في شريط التنقّل
export const unreadCount = asyncHandler(async (req, res) => {
  const conversations = await Conversation.find({ participants: req.user._id })
    .select('unread')
    .lean();

  const total = conversations.reduce(
    (sum, c) => sum + (c.unread?.[String(req.user._id)] || 0),
    0
  );

  res.json({ success: true, data: { count: total } });
});
