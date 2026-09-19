import Report from '../models/Report.js';
import Notification from '../models/Notification.js';
import Banner from '../models/Banner.js';
import JobOffer from '../models/JobOffer.js';
import { ApiError, asyncHandler } from '../utils/ApiError.js';
import {
  WILAYAS,
  SECTORS,
  CONTRACT_TYPES,
  EDUCATION_LEVELS,
  EXPERIENCE_LEVELS,
  REPORT_REASONS,
  OFFER_STATUS,
} from '../config/constants.js';

// GET /api/reference — كل القوائم المرجعية في نداء واحد (يُخزَّن محليًا في التطبيق)
export const getReference = asyncHandler(async (_req, res) => {
  res.json({
    success: true,
    data: {
      wilayas: WILAYAS,
      sectors: SECTORS,
      contractTypes: CONTRACT_TYPES,
      educationLevels: EDUCATION_LEVELS,
      experienceLevels: EXPERIENCE_LEVELS,
      reportReasons: REPORT_REASONS,
    },
  });
});

// GET /api/banners — اللافتة الترويجية للواجهة الرئيسية (3.2)
export const getBanners = asyncHandler(async (_req, res) => {
  const now = new Date();
  const items = await Banner.find({
    active: true,
    $and: [
      { $or: [{ startsAt: { $lte: now } }, { startsAt: null }] },
      { $or: [{ endsAt: { $gte: now } }, { endsAt: null }] },
    ],
  })
    .sort({ order: 1, createdAt: -1 })
    .lean();

  res.json({ success: true, data: { items } });
});

// GET /api/home — كل ما تحتاجه الواجهة الرئيسية في نداء واحد (هدف: فتح < ثانيتين)
export const getHomeFeed = asyncHandler(async (_req, res) => {
  const live = { status: OFFER_STATUS.APPROVED, expiresAt: { $gt: new Date() } };
  const now = new Date();

  const [banners, latest, featured, totalOffers, topWilayas] = await Promise.all([
    Banner.find({ active: true }).sort({ order: 1 }).limit(5).lean(),
    JobOffer.find(live)
      .sort({ featured: -1, publishedAt: -1 })
      .limit(10)
      .populate('company', 'name logo wilaya verificationStatus')
      .lean(),
    JobOffer.find({ ...live, featured: true, featuredUntil: { $gt: now } })
      .sort({ publishedAt: -1 })
      .limit(6)
      .populate('company', 'name logo wilaya verificationStatus')
      .lean(),
    JobOffer.countDocuments(live),
    JobOffer.aggregate([
      { $match: live },
      { $group: { _id: '$wilaya', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 8 },
    ]),
  ]);

  res.json({
    success: true,
    data: {
      banners,
      latestOffers: latest,
      featuredOffers: featured,
      stats: { totalOffers },
      topWilayas: topWilayas.map((w) => ({ wilaya: w._id, count: w.count })),
    },
  });
});

// POST /api/reports — الإبلاغ عن عرض أو حساب مشبوه (3.4)
export const createReport = asyncHandler(async (req, res) => {
  const { targetType, targetId, reason, details } = req.body;

  const existing = await Report.findOne({
    reporter: req.user._id,
    targetType,
    targetId,
  });
  if (existing) throw new ApiError(409, 'سبق أن أبلغت عن هذا العنصر');

  const report = await Report.create({
    reporter: req.user._id,
    targetType,
    targetId,
    reason,
    details,
  });

  res.status(201).json({
    success: true,
    message: 'تم استلام بلاغك، شكرًا لمساهمتك في حماية المنصّة',
    data: { report },
  });
});

// GET /api/notifications
export const listNotifications = asyncHandler(async (req, res) => {
  const { page = 1, limit = 20 } = req.query;
  const perPage = Math.min(Number(limit) || 20, 50);

  const [items, unread] = await Promise.all([
    Notification.find({ user: req.user._id })
      .sort({ createdAt: -1 })
      .skip((Math.max(Number(page) || 1, 1) - 1) * perPage)
      .limit(perPage)
      .lean(),
    Notification.countDocuments({ user: req.user._id, readAt: null }),
  ]);

  res.json({ success: true, data: { items, unreadCount: unread } });
});

// PATCH /api/notifications/read — تعليم إشعار أو الكل كمقروء
export const markNotificationsRead = asyncHandler(async (req, res) => {
  const { id } = req.body;
  const filter = { user: req.user._id, readAt: null };
  if (id) filter._id = id;

  await Notification.updateMany(filter, { readAt: new Date() });
  res.json({ success: true, message: 'تم التعليم كمقروء' });
});

// DELETE /api/notifications/:id
export const deleteNotification = asyncHandler(async (req, res) => {
  await Notification.deleteOne({ _id: req.params.id, user: req.user._id });
  res.json({ success: true, message: 'تم حذف الإشعار' });
});
