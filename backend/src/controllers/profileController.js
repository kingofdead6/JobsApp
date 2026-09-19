import Profile from '../models/Profile.js';
import User from '../models/User.js';
import { ApiError, asyncHandler } from '../utils/ApiError.js';
import { storeFile, removeFile } from '../middleware/upload.js';

// GET /api/profile/me — السيرة الذاتية الرقمية (3.5)
export const getMyProfile = asyncHandler(async (req, res) => {
  let profile = await Profile.findOne({ user: req.user._id });
  if (!profile) profile = await Profile.create({ user: req.user._id });

  res.json({ success: true, data: { profile, user: req.user } });
});

// PATCH /api/profile/me — تحديث المعلومات الشخصية والمهنية
export const updateMyProfile = asyncHandler(async (req, res) => {
  const { fullName, wilaya, email, ...profileFields } = req.body;

  // الحقول التي تعود لكيان المستخدم لا للملف المهني
  const userUpdate = {};
  if (fullName) userUpdate.fullName = fullName;
  if (wilaya) userUpdate.wilaya = wilaya;
  if (email !== undefined) userUpdate.email = email || undefined;
  if (Object.keys(userUpdate).length) {
    await User.updateOne({ _id: req.user._id }, userUpdate, { runValidators: true });
  }

  delete profileFields.user;

  const profile = await Profile.findOneAndUpdate(
    { user: req.user._id },
    { $set: profileFields },
    { new: true, upsert: true, runValidators: true }
  );

  const user = await User.findById(req.user._id);
  res.json({ success: true, message: 'تم حفظ التعديلات', data: { profile, user } });
});

// POST /api/profile/experiences — إضافة خبرة مهنية
export const addExperience = asyncHandler(async (req, res) => {
  const profile = await Profile.findOneAndUpdate(
    { user: req.user._id },
    { $push: { experiences: req.body } },
    { new: true, upsert: true, runValidators: true }
  );
  res.status(201).json({ success: true, message: 'تمت إضافة الخبرة', data: { profile } });
});

// DELETE /api/profile/experiences/:expId
export const removeExperience = asyncHandler(async (req, res) => {
  const profile = await Profile.findOneAndUpdate(
    { user: req.user._id },
    { $pull: { experiences: { _id: req.params.expId } } },
    { new: true }
  );
  if (!profile) throw new ApiError(404, 'الملف غير موجود');
  res.json({ success: true, message: 'تم حذف الخبرة', data: { profile } });
});

// POST /api/profile/educations
export const addEducation = asyncHandler(async (req, res) => {
  const profile = await Profile.findOneAndUpdate(
    { user: req.user._id },
    { $push: { educations: req.body } },
    { new: true, upsert: true, runValidators: true }
  );
  res.status(201).json({ success: true, message: 'تمت إضافة الشهادة', data: { profile } });
});

// DELETE /api/profile/educations/:eduId
export const removeEducation = asyncHandler(async (req, res) => {
  const profile = await Profile.findOneAndUpdate(
    { user: req.user._id },
    { $pull: { educations: { _id: req.params.eduId } } },
    { new: true }
  );
  if (!profile) throw new ApiError(404, 'الملف غير موجود');
  res.json({ success: true, message: 'تم حذف الشهادة', data: { profile } });
});

// POST /api/profile/cv — رفع ملف PDF (3.5)
export const uploadCvFile = asyncHandler(async (req, res) => {
  const stored = await storeFile(req.file, 'cv');

  // نحتفظ بمعرّف النسخة السابقة لحذفها بعد نجاح الاستبدال
  const previous = await Profile.findOne({ user: req.user._id }).select('cvPublicId');

  const profile = await Profile.findOneAndUpdate(
    { user: req.user._id },
    {
      $set: {
        cvFile: stored.url,
        cvPublicId: stored.publicId,
        cvFileName: req.file.originalname.slice(0, 120),
      },
    },
    { new: true, upsert: true }
  );

  if (previous?.cvPublicId) await removeFile(previous.cvPublicId, 'raw');

  res.json({ success: true, message: 'تم رفع السيرة الذاتية', data: { profile } });
});

// POST /api/profile/avatar — الصورة الشخصية
export const uploadAvatarFile = asyncHandler(async (req, res) => {
  const stored = await storeFile(req.file, 'avatars');

  const previous = await User.findById(req.user._id).select('+avatarPublicId');

  const user = await User.findByIdAndUpdate(
    req.user._id,
    { avatar: stored.url, avatarPublicId: stored.publicId },
    { new: true }
  );

  if (previous?.avatarPublicId) await removeFile(previous.avatarPublicId, 'image');

  res.json({ success: true, message: 'تم تحديث الصورة', data: { user } });
});

/**
 * GET /api/profile/cv-database — البحث في قاعدة السير الذاتية
 * ميزة مدفوعة ضمن اشتراك المؤسسات (الفصل 8).
 */
export const searchCvDatabase = asyncHandler(async (req, res) => {
  const Company = (await import('../models/Company.js')).default;
  const company = await Company.findOne({ owner: req.user._id });

  if (!company) throw new ApiError(400, 'ملف المؤسسة غير موجود');
  if (!company.subscription?.cvDatabaseAccess) {
    throw new ApiError(403, 'الوصول إلى قاعدة السير الذاتية يتطلّب اشتراكًا فعّالًا');
  }

  const { q, sector, educationLevel, wilaya, page = 1, limit = 20 } = req.query;

  const filter = { visibleToCompanies: true };
  if (q) filter.$text = { $search: q };
  if (sector) filter.sector = sector;
  if (educationLevel) filter.educationLevel = educationLevel;

  const perPage = Math.min(Number(limit) || 20, 50);
  const skip = (Math.max(Number(page) || 1, 1) - 1) * perPage;

  let items = await Profile.find(filter)
    .skip(skip)
    .limit(perPage)
    .populate('user', 'fullName avatar wilaya')
    .lean();

  // التصفية بالولاية تتم على كيان المستخدم
  if (wilaya) items = items.filter((p) => p.user?.wilaya === wilaya);

  res.json({ success: true, data: { items } });
});
