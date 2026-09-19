import Company from '../models/Company.js';
import JobOffer from '../models/JobOffer.js';
import { ApiError, asyncHandler } from '../utils/ApiError.js';
import { publicPath } from '../middleware/upload.js';
import { OFFER_STATUS } from '../config/constants.js';

// GET /api/companies — دليل المؤسسات (3.8)
export const listCompanies = asyncHandler(async (req, res) => {
  const { q, sector, wilaya, verified, page = 1, limit = 20 } = req.query;

  const filter = {};
  if (q) filter.$text = { $search: q };
  if (sector) filter.sector = sector;
  if (wilaya) filter.wilaya = wilaya;
  if (verified === 'true') filter.verificationStatus = 'verified';

  const perPage = Math.min(Number(limit) || 20, 50);
  const skip = (Math.max(Number(page) || 1, 1) - 1) * perPage;

  const [items, total] = await Promise.all([
    Company.find(filter)
      .sort({ verificationStatus: -1, createdAt: -1 })
      .skip(skip)
      .limit(perPage)
      .lean(),
    Company.countDocuments(filter),
  ]);

  // عدد العروض النشطة لكل مؤسسة
  const counts = await JobOffer.aggregate([
    {
      $match: {
        company: { $in: items.map((c) => c._id) },
        status: OFFER_STATUS.APPROVED,
        expiresAt: { $gt: new Date() },
      },
    },
    { $group: { _id: '$company', count: { $sum: 1 } } },
  ]);
  const countMap = Object.fromEntries(counts.map((c) => [String(c._id), c.count]));

  res.json({
    success: true,
    data: {
      items: items.map((c) => ({ ...c, activeOffers: countMap[String(c._id)] || 0 })),
      pagination: { page: Number(page), limit: perPage, total, pages: Math.ceil(total / perPage) },
    },
  });
});

// GET /api/companies/:id — صفحة تعريف المؤسسة مع عروضها النشطة (3.8)
export const getCompany = asyncHandler(async (req, res) => {
  const company = await Company.findById(req.params.id).lean();
  if (!company) throw new ApiError(404, 'المؤسسة غير موجودة');

  const offers = await JobOffer.find({
    company: company._id,
    status: OFFER_STATUS.APPROVED,
    expiresAt: { $gt: new Date() },
  })
    .sort({ featured: -1, publishedAt: -1 })
    .limit(20)
    .lean();

  res.json({ success: true, data: { company, offers } });
});

// GET /api/companies/me
export const getMyCompany = asyncHandler(async (req, res) => {
  const company = await Company.findOne({ owner: req.user._id });
  if (!company) throw new ApiError(404, 'لم تُنشئ ملف المؤسسة بعد');
  res.json({ success: true, data: { company } });
});

// POST /api/companies — إنشاء ملف المؤسسة
export const createCompany = asyncHandler(async (req, res) => {
  const existing = await Company.findOne({ owner: req.user._id });
  if (existing) throw new ApiError(409, 'لديك ملف مؤسسة بالفعل');

  const company = await Company.create({
    ...req.body,
    owner: req.user._id,
    // التوثيق والاشتراك يمنحهما المشرف فقط
    verificationStatus: 'unverified',
    subscription: { plan: 'free', cvDatabaseAccess: false },
  });

  res.status(201).json({ success: true, message: 'تم إنشاء ملف المؤسسة', data: { company } });
});

// PATCH /api/companies/me
export const updateMyCompany = asyncHandler(async (req, res) => {
  const blocked = ['owner', 'verificationStatus', 'verifiedAt', 'subscription', 'rating'];
  blocked.forEach((f) => delete req.body[f]);

  const company = await Company.findOneAndUpdate(
    { owner: req.user._id },
    { $set: req.body },
    { new: true, runValidators: true }
  );
  if (!company) throw new ApiError(404, 'ملف المؤسسة غير موجود');

  res.json({ success: true, message: 'تم حفظ التعديلات', data: { company } });
});

// POST /api/companies/me/logo
export const uploadCompanyLogo = asyncHandler(async (req, res) => {
  if (!req.file) throw new ApiError(400, 'لم يتم إرفاق أي ملف');

  const company = await Company.findOneAndUpdate(
    { owner: req.user._id },
    { logo: publicPath(req.file, 'logos') },
    { new: true }
  );
  if (!company) throw new ApiError(404, 'ملف المؤسسة غير موجود');

  res.json({ success: true, message: 'تم تحديث الشعار', data: { company } });
});

// POST /api/companies/me/verification — طلب شارة «مؤسسة موثّقة» (3.8)
export const requestVerification = asyncHandler(async (req, res) => {
  const company = await Company.findOne({ owner: req.user._id });
  if (!company) throw new ApiError(404, 'ملف المؤسسة غير موجود');
  if (company.verificationStatus === 'verified') {
    throw new ApiError(400, 'المؤسسة موثّقة بالفعل');
  }

  if (req.body.commercialRegister) company.commercialRegister = req.body.commercialRegister;
  if (req.file) company.registerDocument = publicPath(req.file, 'logos');

  if (!company.commercialRegister) {
    throw new ApiError(400, 'رقم السجل التجاري مطلوب');
  }

  company.verificationStatus = 'pending';
  company.verificationNote = undefined;
  await company.save();

  res.json({
    success: true,
    message: 'تم إرسال طلب التوثيق، سيراجعه المشرف',
    data: { company },
  });
});

// GET /api/companies/me/stats — إحصائيات لوحة المؤسسة
export const myCompanyStats = asyncHandler(async (req, res) => {
  const company = await Company.findOne({ owner: req.user._id });
  if (!company) throw new ApiError(404, 'ملف المؤسسة غير موجود');

  const [byStatus, totals] = await Promise.all([
    JobOffer.aggregate([
      { $match: { company: company._id } },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]),
    JobOffer.aggregate([
      { $match: { company: company._id } },
      {
        $group: {
          _id: null,
          views: { $sum: '$viewsCount' },
          applications: { $sum: '$applicationsCount' },
        },
      },
    ]),
  ]);

  res.json({
    success: true,
    data: {
      offersByStatus: Object.fromEntries(byStatus.map((s) => [s._id, s.count])),
      totalViews: totals[0]?.views || 0,
      totalApplications: totals[0]?.applications || 0,
      subscription: company.subscription,
      verificationStatus: company.verificationStatus,
    },
  });
});
