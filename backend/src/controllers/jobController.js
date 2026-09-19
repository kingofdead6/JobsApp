import mongoose from 'mongoose';
import JobOffer from '../models/JobOffer.js';
import Company from '../models/Company.js';
import SavedItem from '../models/SavedItem.js';
import Application from '../models/Application.js';
import { ApiError, asyncHandler } from '../utils/ApiError.js';
import { OFFER_STATUS, ROLES } from '../config/constants.js';

// الشرط الأساسي لأي عرض ظاهر للعموم: مُصادق عليه وغير منتهٍ
function liveFilter() {
  return { status: OFFER_STATUS.APPROVED, expiresAt: { $gt: new Date() } };
}

/**
 * GET /api/jobs — البحث والتصفية (3.3)
 * يدعم: q, wilaya, sector, contractType, salaryMin, educationLevel,
 * experienceLevel, postedWithin, sort, near, page, limit
 */
export const listJobs = asyncHandler(async (req, res) => {
  const {
    q,
    wilaya,
    sector,
    contractType,
    salaryMin,
    educationLevel,
    experienceLevel,
    postedWithin,
    company,
    sort = 'recent',
    near,
    page = 1,
    limit = 20,
  } = req.query;

  const filter = liveFilter();

  if (q) filter.$text = { $search: q };
  if (wilaya) filter.wilaya = { $in: String(wilaya).split(',') };
  if (sector) filter.sector = { $in: String(sector).split(',') };
  if (contractType) filter.contractType = { $in: String(contractType).split(',') };
  if (educationLevel) filter.educationLevel = educationLevel;
  if (experienceLevel) filter.experienceLevel = experienceLevel;
  if (company) filter.company = company;

  // مجال الراتب: نقبل العرض إذا كان سقفه يبلغ الحد المطلوب
  if (salaryMin) filter.salaryMax = { $gte: Number(salaryMin) };

  // تاريخ النشر: آخر N يومًا
  if (postedWithin) {
    const days = Number(postedWithin);
    if (Number.isFinite(days) && days > 0) {
      filter.publishedAt = { $gte: new Date(Date.now() - days * 864e5) };
    }
  }

  const perPage = Math.min(Number(limit) || 20, 50);
  const skip = (Math.max(Number(page) || 1, 1) - 1) * perPage;

  // الترتيب — العروض المميّزة تتصدّر النتائج دائمًا (3.8)
  const sortMap = {
    recent: { featured: -1, publishedAt: -1 },
    salary: { featured: -1, salaryMax: -1, publishedAt: -1 },
    relevance: q ? { score: { $meta: 'textScore' } } : { featured: -1, publishedAt: -1 },
  };

  // الترتيب «الأقرب جغرافيًا» يحتاج استعلامًا هندسيًا منفصلًا
  let query;
  if (sort === 'nearest' && near) {
    const [lng, lat] = String(near).split(',').map(Number);
    if (!Number.isFinite(lng) || !Number.isFinite(lat)) {
      throw new ApiError(400, 'إحداثيات غير صالحة');
    }
    filter.location = {
      $near: { $geometry: { type: 'Point', coordinates: [lng, lat] }, $maxDistance: 200000 },
    };
    query = JobOffer.find(filter);
  } else {
    query = JobOffer.find(filter, q ? { score: { $meta: 'textScore' } } : {}).sort(
      sortMap[sort] || sortMap.recent
    );
  }

  const [items, total] = await Promise.all([
    query
      .skip(skip)
      .limit(perPage)
      .populate('company', 'name logo wilaya verificationStatus')
      .lean(),
    JobOffer.countDocuments(filter),
  ]);

  // تعليم العروض المحفوظة لدى المستخدم الحالي
  let savedIds = new Set();
  if (req.user) {
    const saved = await SavedItem.find({
      user: req.user._id,
      kind: 'favorite',
      offer: { $in: items.map((i) => i._id) },
    }).select('offer');
    savedIds = new Set(saved.map((s) => String(s.offer)));
  }

  res.json({
    success: true,
    data: {
      items: items.map((i) => ({ ...i, isSaved: savedIds.has(String(i._id)) })),
      pagination: {
        page: Number(page),
        limit: perPage,
        total,
        pages: Math.ceil(total / perPage),
      },
    },
  });
});

// GET /api/jobs/latest — «أحدث عروض العمل» للواجهة الرئيسية (3.2)
export const latestJobs = asyncHandler(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 10, 30);
  const items = await JobOffer.find(liveFilter())
    .sort({ featured: -1, publishedAt: -1 })
    .limit(limit)
    .populate('company', 'name logo wilaya verificationStatus')
    .lean();

  res.json({ success: true, data: { items } });
});

// GET /api/jobs/featured — العروض المميّزة (3.8)
export const featuredJobs = asyncHandler(async (req, res) => {
  const limit = Math.min(Number(req.query.limit) || 10, 30);
  const items = await JobOffer.find({
    ...liveFilter(),
    featured: true,
    featuredUntil: { $gt: new Date() },
  })
    .sort({ publishedAt: -1 })
    .limit(limit)
    .populate('company', 'name logo wilaya verificationStatus')
    .lean();

  res.json({ success: true, data: { items } });
});

// GET /api/jobs/by-wilaya — عدد العروض لكل ولاية («وظائف حسب الولاية»، 3.2)
export const jobsByWilaya = asyncHandler(async (_req, res) => {
  const counts = await JobOffer.aggregate([
    { $match: liveFilter() },
    { $group: { _id: '$wilaya', count: { $sum: 1 } } },
    { $sort: { count: -1 } },
  ]);

  res.json({
    success: true,
    data: { items: counts.map((c) => ({ wilaya: c._id, count: c.count })) },
  });
});

// GET /api/jobs/:id — تفاصيل العرض (3.4)
export const getJob = asyncHandler(async (req, res) => {
  const offer = await JobOffer.findById(req.params.id).populate(
    'company',
    'name logo wilaya sector description verificationStatus website employeesRange'
  );
  if (!offer) throw new ApiError(404, 'العرض غير موجود');

  // العرض غير المنشور لا يراه إلا صاحبه أو المشرف
  const isOwner =
    req.user &&
    (String(offer.postedBy) === String(req.user._id) || req.user.role === ROLES.ADMIN);
  if (offer.status !== OFFER_STATUS.APPROVED && !isOwner) {
    throw new ApiError(404, 'العرض غير موجود');
  }

  // عدّاد المشاهدات لا يُحتسب لصاحب العرض
  if (!isOwner) {
    await JobOffer.updateOne({ _id: offer._id }, { $inc: { viewsCount: 1 } });
  }

  let isSaved = false;
  let hasApplied = false;
  if (req.user) {
    const [saved, application] = await Promise.all([
      SavedItem.exists({ user: req.user._id, kind: 'favorite', offer: offer._id }),
      Application.exists({ applicant: req.user._id, offer: offer._id }),
    ]);
    isSaved = Boolean(saved);
    hasApplied = Boolean(application);
  }

  res.json({ success: true, data: { offer, isSaved, hasApplied } });
});

// POST /api/jobs — نشر عرض عمل (3.6)، يُحفظ بحالة «قيد المراجعة»
export const createJob = asyncHandler(async (req, res) => {
  const company = await Company.findOne({ owner: req.user._id });
  if (!company) throw new ApiError(400, 'يجب إنشاء ملف المؤسسة قبل نشر العروض');

  const offer = await JobOffer.create({
    ...req.body,
    company: company._id,
    postedBy: req.user._id,
    status: OFFER_STATUS.PENDING,
    // لا يمكن للمؤسسة أن تمنح عرضها صفة «مميّز» بنفسها
    featured: false,
    featuredUntil: undefined,
  });

  res.status(201).json({
    success: true,
    message: 'تم إرسال العرض للمراجعة، سيظهر بعد مصادقة المشرف',
    data: { offer },
  });
});

// PATCH /api/jobs/:id — تعديل العرض، يُعاد إلى المراجعة
export const updateJob = asyncHandler(async (req, res) => {
  const offer = await JobOffer.findById(req.params.id);
  if (!offer) throw new ApiError(404, 'العرض غير موجود');
  if (String(offer.postedBy) !== String(req.user._id)) {
    throw new ApiError(403, 'لا يمكنك تعديل عرض لا يخصّك');
  }

  const protectedFields = ['company', 'postedBy', 'status', 'featured', 'featuredUntil',
    'viewsCount', 'applicationsCount', 'reviewedBy', 'reviewedAt'];
  protectedFields.forEach((f) => delete req.body[f]);

  Object.assign(offer, req.body);
  // أي تعديل جوهري يُعيد العرض إلى قائمة المراجعة
  offer.status = OFFER_STATUS.PENDING;
  offer.rejectionReason = undefined;
  await offer.save();

  res.json({
    success: true,
    message: 'تم حفظ التعديلات، العرض قيد المراجعة من جديد',
    data: { offer },
  });
});

// PATCH /api/jobs/:id/status — إيقاف / إعادة نشر / تمديد (3.6)
export const changeJobState = asyncHandler(async (req, res) => {
  const { action, days } = req.body;
  const offer = await JobOffer.findById(req.params.id);
  if (!offer) throw new ApiError(404, 'العرض غير موجود');
  if (String(offer.postedBy) !== String(req.user._id)) {
    throw new ApiError(403, 'لا يمكنك تسيير عرض لا يخصّك');
  }

  if (action === 'pause') {
    if (offer.status !== OFFER_STATUS.APPROVED) {
      throw new ApiError(400, 'لا يمكن إيقاف عرض غير منشور');
    }
    offer.status = OFFER_STATUS.PAUSED;
  } else if (action === 'resume') {
    if (offer.status !== OFFER_STATUS.PAUSED) {
      throw new ApiError(400, 'العرض ليس موقوفًا');
    }
    offer.status =
      offer.expiresAt > new Date() ? OFFER_STATUS.APPROVED : OFFER_STATUS.EXPIRED;
  } else if (action === 'extend') {
    const addDays = Math.min(Math.max(Number(days) || 30, 1), 90);
    const base = offer.expiresAt > new Date() ? offer.expiresAt : new Date();
    offer.expiresAt = new Date(base.getTime() + addDays * 864e5);
    if (offer.status === OFFER_STATUS.EXPIRED) offer.status = OFFER_STATUS.APPROVED;
  } else if (action === 'republish') {
    offer.expiresAt = new Date(Date.now() + 30 * 864e5);
    offer.status = OFFER_STATUS.PENDING;
  } else {
    throw new ApiError(400, 'إجراء غير معروف');
  }

  await offer.save();
  res.json({ success: true, message: 'تم تحديث حالة العرض', data: { offer } });
});

// DELETE /api/jobs/:id
export const deleteJob = asyncHandler(async (req, res) => {
  const offer = await JobOffer.findById(req.params.id);
  if (!offer) throw new ApiError(404, 'العرض غير موجود');
  if (
    String(offer.postedBy) !== String(req.user._id) &&
    req.user.role !== ROLES.ADMIN
  ) {
    throw new ApiError(403, 'لا يمكنك حذف عرض لا يخصّك');
  }

  await offer.deleteOne();
  res.json({ success: true, message: 'تم حذف العرض' });
});

// GET /api/jobs/mine/list — عروض المؤسسة الحالية بكل حالاتها
export const myJobs = asyncHandler(async (req, res) => {
  const { status } = req.query;
  const filter = { postedBy: req.user._id };
  if (status) filter.status = status;

  const items = await JobOffer.find(filter)
    .sort({ createdAt: -1 })
    .populate('company', 'name logo')
    .lean();

  res.json({ success: true, data: { items } });
});

/**
 * GET /api/jobs/recommended — توصية بالعروض حسب الملف الشخصي (3.9)
 * ترجيح بسيط: تطابق المهنة/القطاع/الولاية/المهارات.
 */
export const recommendedJobs = asyncHandler(async (req, res) => {
  const Profile = mongoose.model('Profile');
  const profile = await Profile.findOne({ user: req.user._id }).lean();

  if (!profile) {
    const items = await JobOffer.find(liveFilter())
      .sort({ featured: -1, publishedAt: -1 })
      .limit(10)
      .populate('company', 'name logo wilaya verificationStatus')
      .lean();
    return res.json({ success: true, data: { items } });
  }

  const items = await JobOffer.aggregate([
    { $match: liveFilter() },
    {
      $addFields: {
        matchScore: {
          $add: [
            { $cond: [{ $eq: ['$sector', profile.sector] }, 3, 0] },
            { $cond: [{ $eq: ['$wilaya', req.user.wilaya] }, 2, 0] },
            { $cond: [{ $eq: ['$educationLevel', profile.educationLevel] }, 1, 0] },
            {
              $size: {
                $setIntersection: ['$skills', profile.skills || []],
              },
            },
            { $cond: ['$featured', 1, 0] },
          ],
        },
      },
    },
    { $sort: { matchScore: -1, publishedAt: -1 } },
    { $limit: 15 },
    {
      $lookup: {
        from: 'companies',
        localField: 'company',
        foreignField: '_id',
        as: 'company',
        pipeline: [{ $project: { name: 1, logo: 1, wilaya: 1, verificationStatus: 1 } }],
      },
    },
    { $unwind: '$company' },
  ]);

  res.json({ success: true, data: { items } });
});
