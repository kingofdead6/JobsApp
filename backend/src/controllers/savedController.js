import SavedItem from '../models/SavedItem.js';
import JobOffer from '../models/JobOffer.js';
import { ApiError, asyncHandler } from '../utils/ApiError.js';
import { OFFER_STATUS } from '../config/constants.js';

// POST /api/saved/offers/:offerId — حفظ عرض في المفضّلة (3.4)
export const saveOffer = asyncHandler(async (req, res) => {
  const offer = await JobOffer.findById(req.params.offerId).select('_id');
  if (!offer) throw new ApiError(404, 'العرض غير موجود');

  const saved = await SavedItem.findOneAndUpdate(
    { user: req.user._id, kind: 'favorite', offer: offer._id },
    { $setOnInsert: { user: req.user._id, kind: 'favorite', offer: offer._id } },
    { new: true, upsert: true }
  );

  res.status(201).json({ success: true, message: 'تم حفظ العرض', data: { saved } });
});

// DELETE /api/saved/offers/:offerId
export const unsaveOffer = asyncHandler(async (req, res) => {
  await SavedItem.deleteOne({
    user: req.user._id,
    kind: 'favorite',
    offer: req.params.offerId,
  });
  res.json({ success: true, message: 'تم إلغاء الحفظ' });
});

// GET /api/saved/offers — «العروض المحفوظة»
export const listSavedOffers = asyncHandler(async (req, res) => {
  const items = await SavedItem.find({ user: req.user._id, kind: 'favorite' })
    .sort({ createdAt: -1 })
    .populate({
      path: 'offer',
      populate: { path: 'company', select: 'name logo verificationStatus' },
    })
    .lean();

  // تجاهل العروض المحذوفة من المصدر
  res.json({
    success: true,
    data: { items: items.filter((i) => i.offer).map((i) => ({ ...i.offer, savedAt: i.createdAt })) },
  });
});

// POST /api/saved/searches — حفظ معايير بحث مع تنبيه (3.3)
export const saveSearch = asyncHandler(async (req, res) => {
  const { label, criteria, alertEnabled = true } = req.body;

  const count = await SavedItem.countDocuments({ user: req.user._id, kind: 'search' });
  if (count >= 20) throw new ApiError(400, 'بلغت الحد الأقصى لعمليات البحث المحفوظة (20)');

  const saved = await SavedItem.create({
    user: req.user._id,
    kind: 'search',
    label,
    criteria,
    alertEnabled,
  });

  res.status(201).json({ success: true, message: 'تم حفظ البحث', data: { saved } });
});

// GET /api/saved/searches
export const listSavedSearches = asyncHandler(async (req, res) => {
  const items = await SavedItem.find({ user: req.user._id, kind: 'search' })
    .sort({ createdAt: -1 })
    .lean();

  // عدد النتائج المطابقة حاليًا لكل بحث محفوظ
  const withCounts = await Promise.all(
    items.map(async (item) => {
      const filter = { status: OFFER_STATUS.APPROVED, expiresAt: { $gt: new Date() } };
      const c = item.criteria || {};
      if (c.q) filter.$text = { $search: c.q };
      if (c.wilaya) filter.wilaya = c.wilaya;
      if (c.sector) filter.sector = c.sector;
      if (c.contractType) filter.contractType = c.contractType;
      if (c.salaryMin) filter.salaryMax = { $gte: c.salaryMin };

      return { ...item, matchCount: await JobOffer.countDocuments(filter) };
    })
  );

  res.json({ success: true, data: { items: withCounts } });
});

// PATCH /api/saved/searches/:id — تفعيل/تعطيل التنبيه
export const toggleSearchAlert = asyncHandler(async (req, res) => {
  const saved = await SavedItem.findOneAndUpdate(
    { _id: req.params.id, user: req.user._id, kind: 'search' },
    { alertEnabled: Boolean(req.body.alertEnabled) },
    { new: true }
  );
  if (!saved) throw new ApiError(404, 'البحث المحفوظ غير موجود');

  res.json({ success: true, message: 'تم تحديث التنبيه', data: { saved } });
});

// DELETE /api/saved/searches/:id
export const deleteSavedSearch = asyncHandler(async (req, res) => {
  const result = await SavedItem.deleteOne({
    _id: req.params.id,
    user: req.user._id,
    kind: 'search',
  });
  if (!result.deletedCount) throw new ApiError(404, 'البحث المحفوظ غير موجود');

  res.json({ success: true, message: 'تم حذف البحث المحفوظ' });
});
