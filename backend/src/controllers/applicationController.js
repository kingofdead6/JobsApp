import JobOffer from '../models/JobOffer.js';
import Application from '../models/Application.js';
import Profile from '../models/Profile.js';
import Conversation from '../models/Conversation.js';
import { ApiError, asyncHandler } from '../utils/ApiError.js';
import { notify } from '../services/notificationService.js';
import { OFFER_STATUS, APPLICATION_STATUS } from '../config/constants.js';

// POST /api/applications — «تقديم الطلب» (3.4)
export const apply = asyncHandler(async (req, res) => {
  const { offerId, coverLetter } = req.body;

  const offer = await JobOffer.findById(offerId).populate('company', 'name owner');
  if (!offer) throw new ApiError(404, 'العرض غير موجود');
  if (offer.status !== OFFER_STATUS.APPROVED || offer.expiresAt < new Date()) {
    throw new ApiError(400, 'هذا العرض لم يعد متاحًا للترشّح');
  }

  const already = await Application.findOne({ offer: offer._id, applicant: req.user._id });
  if (already) throw new ApiError(409, 'لقد ترشّحت لهذا العرض من قبل');

  // السيرة الذاتية تُرسل مباشرة مع الطلب — 3.4
  const profile = await Profile.findOne({ user: req.user._id }).lean();
  if (!profile) throw new ApiError(400, 'أنشئ سيرتك الذاتية قبل الترشّح');

  const application = await Application.create({
    offer: offer._id,
    applicant: req.user._id,
    company: offer.company._id,
    coverLetter,
    cvSnapshot: {
      fullName: req.user.fullName,
      phone: req.user.phone,
      email: req.user.email,
      wilaya: req.user.wilaya,
      headline: profile.headline,
      profession: profile.profession,
      sector: profile.sector,
      educationLevel: profile.educationLevel,
      yearsOfExperience: profile.yearsOfExperience,
      skills: profile.skills,
      languages: profile.languages,
      experiences: profile.experiences,
      educations: profile.educations,
      cvFile: profile.cvFile,
    },
  });

  await JobOffer.updateOne({ _id: offer._id }, { $inc: { applicationsCount: 1 } });

  // إشعار المؤسسة بالترشّح الجديد
  await notify({
    user: offer.postedBy,
    type: 'new_application',
    title: 'ترشّح جديد',
    body: `${req.user.fullName} ترشّح لعرض «${offer.title}»`,
    data: { applicationId: application._id, offerId: offer._id },
  });

  res.status(201).json({
    success: true,
    message: 'تم إرسال طلبك بنجاح',
    data: { application },
  });
});

// GET /api/applications/mine — «طلبات التوظيف» وحالتها للباحث (3.7)
export const myApplications = asyncHandler(async (req, res) => {
  const { status } = req.query;
  const filter = { applicant: req.user._id };
  if (status) filter.status = status;

  const items = await Application.find(filter)
    .sort({ createdAt: -1 })
    .populate({
      path: 'offer',
      select: 'title wilaya contractType status expiresAt',
      populate: { path: 'company', select: 'name logo verificationStatus' },
    })
    .lean();

  res.json({ success: true, data: { items } });
});

// GET /api/applications/offer/:offerId — الترشّحات المستلمة على عرض (3.6)
export const applicationsForOffer = asyncHandler(async (req, res) => {
  const offer = await JobOffer.findById(req.params.offerId);
  if (!offer) throw new ApiError(404, 'العرض غير موجود');
  if (String(offer.postedBy) !== String(req.user._id)) {
    throw new ApiError(403, 'لا يمكنك الاطّلاع على ترشّحات عرض لا يخصّك');
  }

  const { status } = req.query;
  const filter = { offer: offer._id };
  if (status) filter.status = status;

  const items = await Application.find(filter)
    .sort({ createdAt: -1 })
    .populate('applicant', 'fullName avatar wilaya phone')
    .lean();

  res.json({ success: true, data: { items } });
});

// GET /api/applications/:id — تفاصيل ترشّح واحد
export const getApplication = asyncHandler(async (req, res) => {
  const application = await Application.findById(req.params.id)
    .populate('applicant', 'fullName avatar wilaya phone email')
    .populate({ path: 'offer', select: 'title postedBy wilaya contractType' });
  if (!application) throw new ApiError(404, 'الترشّح غير موجود');

  const isApplicant = String(application.applicant._id) === String(req.user._id);
  const isCompany = String(application.offer.postedBy) === String(req.user._id);
  if (!isApplicant && !isCompany) throw new ApiError(403, 'ليست لديك صلاحية');

  // تعليم الترشّح كمقروء من طرف المؤسسة
  if (isCompany && !application.viewedByCompany) {
    application.viewedByCompany = true;
    await application.save();
  }

  res.json({ success: true, data: { application } });
});

// PATCH /api/applications/:id/status — قبول أو رفض (3.7)
export const updateApplicationStatus = asyncHandler(async (req, res) => {
  const { status, note } = req.body;

  if (![APPLICATION_STATUS.ACCEPTED, APPLICATION_STATUS.REJECTED].includes(status)) {
    throw new ApiError(400, 'حالة غير صالحة');
  }

  const application = await Application.findById(req.params.id).populate('offer', 'title postedBy');
  if (!application) throw new ApiError(404, 'الترشّح غير موجود');
  if (String(application.offer.postedBy) !== String(req.user._id)) {
    throw new ApiError(403, 'ليست لديك صلاحية');
  }

  application.status = status;
  application.statusNote = note;
  application.statusChangedAt = new Date();
  await application.save();

  await notify({
    user: application.applicant,
    type: 'application_status',
    title: status === APPLICATION_STATUS.ACCEPTED ? 'تم قبول طلبك' : 'تحديث بخصوص طلبك',
    body:
      status === APPLICATION_STATUS.ACCEPTED
        ? `تهانينا! تم قبول ترشّحك لعرض «${application.offer.title}»`
        : `لم يُقبل ترشّحك لعرض «${application.offer.title}» هذه المرّة`,
    data: { applicationId: application._id, offerId: application.offer._id },
  });

  res.json({ success: true, message: 'تم تحديث حالة الطلب', data: { application } });
});

// DELETE /api/applications/:id — سحب الترشّح
export const withdrawApplication = asyncHandler(async (req, res) => {
  const application = await Application.findById(req.params.id);
  if (!application) throw new ApiError(404, 'الترشّح غير موجود');
  if (String(application.applicant) !== String(req.user._id)) {
    throw new ApiError(403, 'ليست لديك صلاحية');
  }

  await JobOffer.updateOne({ _id: application.offer }, { $inc: { applicationsCount: -1 } });
  await application.deleteOne();

  res.json({ success: true, message: 'تم سحب الترشّح' });
});
