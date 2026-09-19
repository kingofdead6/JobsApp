import User from '../models/User.js';
import Company from '../models/Company.js';
import JobOffer from '../models/JobOffer.js';
import Application from '../models/Application.js';
import Report from '../models/Report.js';
import Banner from '../models/Banner.js';
import { ApiError, asyncHandler } from '../utils/ApiError.js';
import { notify, broadcast } from '../services/notificationService.js';
import { OFFER_STATUS, ROLES } from '../config/constants.js';

/* ───────── مصادقة العروض (الفصل 4) ───────── */

// GET /api/admin/offers — كل العروض مع تصفية بالحالة
export const listOffers = asyncHandler(async (req, res) => {
  const { status = OFFER_STATUS.PENDING, q, page = 1, limit = 20 } = req.query;

  const filter = {};
  if (status !== 'all') filter.status = status;
  if (q) filter.$text = { $search: q };

  const perPage = Math.min(Number(limit) || 20, 50);
  const skip = (Math.max(Number(page) || 1, 1) - 1) * perPage;

  const [items, total] = await Promise.all([
    JobOffer.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(perPage)
      .populate('company', 'name logo verificationStatus')
      .populate('postedBy', 'fullName phone')
      .lean(),
    JobOffer.countDocuments(filter),
  ]);

  res.json({
    success: true,
    data: {
      items,
      pagination: { page: Number(page), limit: perPage, total, pages: Math.ceil(total / perPage) },
    },
  });
});

// PATCH /api/admin/offers/:id/review — قبول أو رفض مع سبب الرفض
export const reviewOffer = asyncHandler(async (req, res) => {
  const { decision, reason } = req.body;

  const offer = await JobOffer.findById(req.params.id);
  if (!offer) throw new ApiError(404, 'العرض غير موجود');

  if (decision === 'approve') {
    offer.status = OFFER_STATUS.APPROVED;
    offer.publishedAt = offer.publishedAt || new Date();
    offer.rejectionReason = undefined;
  } else if (decision === 'reject') {
    if (!reason?.trim()) throw new ApiError(400, 'سبب الرفض مطلوب');
    offer.status = OFFER_STATUS.REJECTED;
    offer.rejectionReason = reason.trim();
  } else {
    throw new ApiError(400, 'قرار غير معروف');
  }

  offer.reviewedBy = req.user._id;
  offer.reviewedAt = new Date();
  await offer.save();

  await notify({
    user: offer.postedBy,
    type: decision === 'approve' ? 'offer_approved' : 'offer_rejected',
    title: decision === 'approve' ? 'تمت المصادقة على عرضك' : 'تم رفض عرضك',
    body:
      decision === 'approve'
        ? `عرض «${offer.title}» أصبح منشورًا الآن`
        : `سبب الرفض: ${offer.rejectionReason}`,
    data: { offerId: offer._id },
  });

  res.json({ success: true, message: 'تم تسجيل القرار', data: { offer } });
});

// PATCH /api/admin/offers/:id/feature — إبراز عرض مدفوع (3.8)
export const featureOffer = asyncHandler(async (req, res) => {
  const { featured, days = 15 } = req.body;

  const offer = await JobOffer.findById(req.params.id);
  if (!offer) throw new ApiError(404, 'العرض غير موجود');

  offer.featured = Boolean(featured);
  offer.featuredUntil = featured
    ? new Date(Date.now() + Math.min(Math.max(Number(days), 1), 90) * 864e5)
    : undefined;
  await offer.save();

  res.json({ success: true, message: 'تم تحديث حالة الإبراز', data: { offer } });
});

/* ───────── تسيير المستخدمين ───────── */

// GET /api/admin/users
export const listUsers = asyncHandler(async (req, res) => {
  const { q, role, status, page = 1, limit = 20 } = req.query;

  const filter = {};
  if (role) filter.role = role;
  if (status) filter.status = status;
  if (q) {
    filter.$or = [
      { fullName: new RegExp(q, 'i') },
      { phone: new RegExp(q, 'i') },
      { email: new RegExp(q, 'i') },
    ];
  }

  const perPage = Math.min(Number(limit) || 20, 50);
  const [items, total] = await Promise.all([
    User.find(filter)
      .sort({ createdAt: -1 })
      .skip((Math.max(Number(page) || 1, 1) - 1) * perPage)
      .limit(perPage)
      .lean(),
    User.countDocuments(filter),
  ]);

  res.json({
    success: true,
    data: {
      items,
      pagination: { page: Number(page), limit: perPage, total, pages: Math.ceil(total / perPage) },
    },
  });
});

// PATCH /api/admin/users/:id/status — تعليق أو إعادة تفعيل
export const setUserStatus = asyncHandler(async (req, res) => {
  const { status, reason } = req.body;
  if (!['active', 'suspended'].includes(status)) throw new ApiError(400, 'حالة غير صالحة');

  const user = await User.findById(req.params.id);
  if (!user) throw new ApiError(404, 'المستخدم غير موجود');
  if (user.role === ROLES.ADMIN) throw new ApiError(403, 'لا يمكن تعليق حساب مشرف');

  user.status = status;
  user.suspensionReason = status === 'suspended' ? reason : undefined;
  await user.save({ validateBeforeSave: false });

  // تعليق الحساب يُخفي عروضه من النتائج
  if (status === 'suspended') {
    await JobOffer.updateMany(
      { postedBy: user._id, status: OFFER_STATUS.APPROVED },
      { status: OFFER_STATUS.PAUSED }
    );
  }

  res.json({ success: true, message: 'تم تحديث حالة الحساب', data: { user } });
});

/* ───────── توثيق المؤسسات ───────── */

// GET /api/admin/companies
export const listCompaniesAdmin = asyncHandler(async (req, res) => {
  const { verificationStatus, q, page = 1, limit = 20 } = req.query;

  const filter = {};
  if (verificationStatus) filter.verificationStatus = verificationStatus;
  if (q) filter.name = new RegExp(q, 'i');

  const perPage = Math.min(Number(limit) || 20, 50);
  const [items, total] = await Promise.all([
    Company.find(filter)
      .sort({ createdAt: -1 })
      .skip((Math.max(Number(page) || 1, 1) - 1) * perPage)
      .limit(perPage)
      .populate('owner', 'fullName phone email')
      .lean(),
    Company.countDocuments(filter),
  ]);

  res.json({
    success: true,
    data: {
      items,
      pagination: { page: Number(page), limit: perPage, total, pages: Math.ceil(total / perPage) },
    },
  });
});

// PATCH /api/admin/companies/:id/verify
export const verifyCompany = asyncHandler(async (req, res) => {
  const { decision, note } = req.body;

  const company = await Company.findById(req.params.id);
  if (!company) throw new ApiError(404, 'المؤسسة غير موجودة');

  if (decision === 'approve') {
    company.verificationStatus = 'verified';
    company.verifiedAt = new Date();
    company.verificationNote = undefined;
  } else if (decision === 'reject') {
    company.verificationStatus = 'rejected';
    company.verificationNote = note;
  } else {
    throw new ApiError(400, 'قرار غير معروف');
  }
  await company.save();

  await notify({
    user: company.owner,
    type: 'company_verified',
    title: decision === 'approve' ? 'تم توثيق مؤسستك' : 'طلب التوثيق مرفوض',
    body:
      decision === 'approve'
        ? 'أصبحت مؤسستك تحمل شارة «مؤسسة موثّقة»'
        : `السبب: ${note || 'غير محدّد'}`,
    data: { companyId: company._id },
  });

  res.json({ success: true, message: 'تم تسجيل القرار', data: { company } });
});

// PATCH /api/admin/companies/:id/subscription — تفعيل اشتراك (الفصل 8)
export const setSubscription = asyncHandler(async (req, res) => {
  const { plan, months = 1, cvDatabaseAccess } = req.body;
  if (!['free', 'monthly', 'yearly'].includes(plan)) throw new ApiError(400, 'خطة غير صالحة');

  const company = await Company.findById(req.params.id);
  if (!company) throw new ApiError(404, 'المؤسسة غير موجودة');

  company.subscription = {
    plan,
    expiresAt:
      plan === 'free'
        ? undefined
        : new Date(Date.now() + Math.min(Math.max(Number(months), 1), 24) * 30 * 864e5),
    cvDatabaseAccess: plan === 'free' ? false : Boolean(cvDatabaseAccess),
  };
  await company.save();

  res.json({ success: true, message: 'تم تحديث الاشتراك', data: { company } });
});

/* ───────── البلاغات ───────── */

// GET /api/admin/reports
export const listReports = asyncHandler(async (req, res) => {
  const { status = 'open', page = 1, limit = 20 } = req.query;

  const filter = {};
  if (status !== 'all') filter.status = status;

  const perPage = Math.min(Number(limit) || 20, 50);
  const [items, total] = await Promise.all([
    Report.find(filter)
      .sort({ createdAt: -1 })
      .skip((Math.max(Number(page) || 1, 1) - 1) * perPage)
      .limit(perPage)
      .populate('reporter', 'fullName phone')
      .lean(),
    Report.countDocuments(filter),
  ]);

  // جلب ملخّص الهدف المُبلَّغ عنه لعرضه في اللوحة
  const enriched = await Promise.all(
    items.map(async (r) => {
      let target = null;
      if (r.targetType === 'offer') {
        target = await JobOffer.findById(r.targetId).select('title status company').lean();
      } else if (r.targetType === 'user') {
        target = await User.findById(r.targetId).select('fullName phone status').lean();
      } else if (r.targetType === 'company') {
        target = await Company.findById(r.targetId).select('name verificationStatus').lean();
      }
      return { ...r, target };
    })
  );

  res.json({
    success: true,
    data: {
      items: enriched,
      pagination: { page: Number(page), limit: perPage, total, pages: Math.ceil(total / perPage) },
    },
  });
});

// PATCH /api/admin/reports/:id — معالجة البلاغ
export const handleReport = asyncHandler(async (req, res) => {
  const { status, resolution, action } = req.body;
  if (!['reviewing', 'resolved', 'dismissed'].includes(status)) {
    throw new ApiError(400, 'حالة غير صالحة');
  }

  const report = await Report.findById(req.params.id);
  if (!report) throw new ApiError(404, 'البلاغ غير موجود');

  // إجراء مباشر على الهدف عند تأكيد البلاغ
  if (action === 'remove_offer' && report.targetType === 'offer') {
    await JobOffer.updateOne(
      { _id: report.targetId },
      { status: OFFER_STATUS.REJECTED, rejectionReason: 'أُزيل إثر بلاغ مؤكَّد' }
    );
  } else if (action === 'suspend_user' && report.targetType === 'user') {
    await User.updateOne(
      { _id: report.targetId, role: { $ne: ROLES.ADMIN } },
      { status: 'suspended', suspensionReason: 'تعليق إثر بلاغ مؤكَّد' }
    );
  }

  report.status = status;
  report.resolution = resolution;
  report.handledBy = req.user._id;
  report.handledAt = new Date();
  await report.save();

  res.json({ success: true, message: 'تمت معالجة البلاغ', data: { report } });
});

/* ───────── الإحصائيات ───────── */

// GET /api/admin/stats — عدد المستخدمين، العروض، الترشّحات، أكثر الولايات والمهن نشاطًا
export const getStats = asyncHandler(async (_req, res) => {
  const [
    usersByRole,
    offersByStatus,
    applicationsTotal,
    topWilayas,
    topSectors,
    pendingReports,
    pendingVerifications,
    recentSignups,
  ] = await Promise.all([
    User.aggregate([
      { $match: { status: { $ne: 'deleted' } } },
      { $group: { _id: '$role', count: { $sum: 1 } } },
    ]),
    JobOffer.aggregate([{ $group: { _id: '$status', count: { $sum: 1 } } }]),
    Application.countDocuments(),
    JobOffer.aggregate([
      { $match: { status: OFFER_STATUS.APPROVED } },
      { $group: { _id: '$wilaya', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 },
    ]),
    JobOffer.aggregate([
      { $match: { status: OFFER_STATUS.APPROVED } },
      { $group: { _id: '$sector', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 },
    ]),
    Report.countDocuments({ status: 'open' }),
    Company.countDocuments({ verificationStatus: 'pending' }),
    User.countDocuments({ createdAt: { $gte: new Date(Date.now() - 7 * 864e5) } }),
  ]);

  res.json({
    success: true,
    data: {
      users: Object.fromEntries(usersByRole.map((u) => [u._id, u.count])),
      offers: Object.fromEntries(offersByStatus.map((o) => [o._id, o.count])),
      applicationsTotal,
      topWilayas: topWilayas.map((w) => ({ wilaya: w._id, count: w.count })),
      topSectors: topSectors.map((s) => ({ sector: s._id, count: s.count })),
      queue: { pendingReports, pendingVerifications },
      recentSignups,
    },
  });
});

/* ───────── المحتوى الترويجي ───────── */

// GET /api/admin/banners
export const listBanners = asyncHandler(async (_req, res) => {
  const items = await Banner.find().sort({ order: 1, createdAt: -1 }).lean();
  res.json({ success: true, data: { items } });
});

// POST /api/admin/banners
export const createBanner = asyncHandler(async (req, res) => {
  const banner = await Banner.create(req.body);
  res.status(201).json({ success: true, message: 'تمت إضافة اللافتة', data: { banner } });
});

// PATCH /api/admin/banners/:id
export const updateBanner = asyncHandler(async (req, res) => {
  const banner = await Banner.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true,
  });
  if (!banner) throw new ApiError(404, 'اللافتة غير موجودة');
  res.json({ success: true, message: 'تم تحديث اللافتة', data: { banner } });
});

// DELETE /api/admin/banners/:id
export const deleteBanner = asyncHandler(async (req, res) => {
  await Banner.findByIdAndDelete(req.params.id);
  res.json({ success: true, message: 'تم حذف اللافتة' });
});

// POST /api/admin/broadcast — إشعار جماعي
export const sendBroadcast = asyncHandler(async (req, res) => {
  const { title, body, role } = req.body;
  const count = await broadcast({ title, body, role });
  res.json({ success: true, message: `تم إرسال الإشعار إلى ${count} مستخدم` });
});
