import User from '../models/User.js';
import Profile from '../models/Profile.js';
import Company from '../models/Company.js';
import { ApiError, asyncHandler } from '../utils/ApiError.js';
import { signToken } from '../middleware/auth.js';
import { generateOtp, sendOtpSms, OTP_TTL_MS, OTP_MAX_ATTEMPTS } from '../services/smsService.js';
import { ROLES } from '../config/constants.js';

// POST /api/auth/register — إنشاء حساب برقم الهاتف (3.1)
export const register = asyncHandler(async (req, res) => {
  const { fullName, phone, email, password, role, wilaya } = req.body;

  if (role === ROLES.ADMIN) {
    throw new ApiError(403, 'لا يمكن إنشاء حساب مشرف عبر التسجيل');
  }

  const existing = await User.findOne({ phone });
  if (existing) throw new ApiError(409, 'رقم الهاتف مستعمل من قبل');

  const code = generateOtp();
  const user = await User.create({
    fullName,
    phone,
    email: email || undefined,
    password,
    role,
    wilaya,
    otpCode: code,
    otpExpiresAt: new Date(Date.now() + OTP_TTL_MS),
  });

  // إنشاء السجل المرافق حسب نوع الحساب
  if (role === ROLES.SEEKER) {
    await Profile.create({ user: user._id });
  }

  const sms = await sendOtpSms(phone, code);

  res.status(201).json({
    success: true,
    message: 'تم إنشاء الحساب. أدخل رمز التأكيد المُرسل إلى هاتفك.',
    data: {
      userId: user._id,
      phone: user.phone,
      // في وضع التطوير فقط نُعيد الرمز لتسهيل الاختبار
      ...(sms.devMode ? { devOtp: code } : {}),
    },
  });
});

// POST /api/auth/verify-otp — تأكيد رقم الهاتف
export const verifyOtp = asyncHandler(async (req, res) => {
  const { phone, code } = req.body;

  const user = await User.findOne({ phone }).select('+otpCode +otpExpiresAt +otpAttempts');
  if (!user) throw new ApiError(404, 'لا يوجد حساب بهذا الرقم');
  if (user.phoneVerified) throw new ApiError(400, 'الرقم مؤكَّد مسبقًا');

  if (user.otpAttempts >= OTP_MAX_ATTEMPTS) {
    throw new ApiError(429, 'تجاوزت عدد المحاولات المسموح بها. اطلب رمزًا جديدًا.');
  }
  if (!user.otpExpiresAt || user.otpExpiresAt < new Date()) {
    throw new ApiError(400, 'انتهت صلاحية الرمز. اطلب رمزًا جديدًا.');
  }
  if (user.otpCode !== code) {
    user.otpAttempts += 1;
    await user.save();
    throw new ApiError(400, 'رمز التأكيد غير صحيح');
  }

  user.phoneVerified = true;
  user.otpCode = undefined;
  user.otpExpiresAt = undefined;
  user.otpAttempts = 0;
  user.lastLoginAt = new Date();
  await user.save();

  res.json({
    success: true,
    message: 'تم تأكيد رقم الهاتف بنجاح',
    data: { token: signToken(user), user },
  });
});

// POST /api/auth/resend-otp
export const resendOtp = asyncHandler(async (req, res) => {
  const { phone } = req.body;

  const user = await User.findOne({ phone }).select('+otpCode +otpExpiresAt +otpAttempts');
  if (!user) throw new ApiError(404, 'لا يوجد حساب بهذا الرقم');
  if (user.phoneVerified) throw new ApiError(400, 'الرقم مؤكَّد مسبقًا');

  const code = generateOtp();
  user.otpCode = code;
  user.otpExpiresAt = new Date(Date.now() + OTP_TTL_MS);
  user.otpAttempts = 0;
  await user.save();

  const sms = await sendOtpSms(phone, code);

  res.json({
    success: true,
    message: 'تم إرسال رمز جديد',
    data: sms.devMode ? { devOtp: code } : {},
  });
});

// POST /api/auth/login — بالهاتف أو البريد الإلكتروني
export const login = asyncHandler(async (req, res) => {
  const { identifier, password } = req.body;

  const query = /^0[5-7]\d{8}$/.test(identifier)
    ? { phone: identifier }
    : { email: String(identifier).toLowerCase() };

  const user = await User.findOne(query).select('+password');
  // رسالة واحدة للحالتين حتى لا نكشف أي الحسابات موجودة
  if (!user || !(await user.comparePassword(password))) {
    throw new ApiError(401, 'بيانات الدخول غير صحيحة');
  }
  if (user.status === 'suspended') {
    throw new ApiError(403, `الحساب معلّق. ${user.suspensionReason || ''}`.trim());
  }
  if (user.status === 'deleted') throw new ApiError(401, 'بيانات الدخول غير صحيحة');

  if (!user.phoneVerified) {
    throw new ApiError(403, 'يجب تأكيد رقم الهاتف قبل الدخول', { needsVerification: true });
  }

  user.lastLoginAt = new Date();
  await user.save({ validateBeforeSave: false });

  res.json({
    success: true,
    message: 'مرحبًا بك',
    data: { token: signToken(user), user },
  });
});

// GET /api/auth/me — المستخدم الحالي مع سجلّه المرافق
export const getMe = asyncHandler(async (req, res) => {
  const payload = { user: req.user };

  if (req.user.role === ROLES.SEEKER) {
    payload.profile = await Profile.findOne({ user: req.user._id });
  } else if (req.user.role === ROLES.COMPANY) {
    payload.company = await Company.findOne({ owner: req.user._id });
  }

  res.json({ success: true, data: payload });
});

// PATCH /api/auth/password — تغيير كلمة المرور
export const changePassword = asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  const user = await User.findById(req.user._id).select('+password');
  if (!(await user.comparePassword(currentPassword))) {
    throw new ApiError(400, 'كلمة المرور الحالية غير صحيحة');
  }

  user.password = newPassword;
  await user.save();

  res.json({ success: true, message: 'تم تغيير كلمة المرور' });
});

// POST /api/auth/forgot-password — إرسال رمز الاسترجاع
export const forgotPassword = asyncHandler(async (req, res) => {
  const { phone } = req.body;
  const user = await User.findOne({ phone }).select('+otpCode +otpExpiresAt +otpAttempts');

  // نُعيد النجاح دائمًا حتى لا نكشف الأرقام المسجّلة
  if (!user) {
    return res.json({ success: true, message: 'إن كان الرقم مسجّلًا فسيصلك رمز الاسترجاع' });
  }

  const code = generateOtp();
  user.otpCode = code;
  user.otpExpiresAt = new Date(Date.now() + OTP_TTL_MS);
  user.otpAttempts = 0;
  await user.save();

  const sms = await sendOtpSms(phone, code);

  res.json({
    success: true,
    message: 'إن كان الرقم مسجّلًا فسيصلك رمز الاسترجاع',
    data: sms.devMode ? { devOtp: code } : {},
  });
});

// POST /api/auth/reset-password — بالرمز المُرسل
export const resetPassword = asyncHandler(async (req, res) => {
  const { phone, code, newPassword } = req.body;

  const user = await User.findOne({ phone }).select('+otpCode +otpExpiresAt +otpAttempts');
  if (!user) throw new ApiError(400, 'الرمز غير صحيح');

  if (user.otpAttempts >= OTP_MAX_ATTEMPTS) {
    throw new ApiError(429, 'تجاوزت عدد المحاولات المسموح بها');
  }
  if (!user.otpExpiresAt || user.otpExpiresAt < new Date()) {
    throw new ApiError(400, 'انتهت صلاحية الرمز');
  }
  if (user.otpCode !== code) {
    user.otpAttempts += 1;
    await user.save();
    throw new ApiError(400, 'الرمز غير صحيح');
  }

  user.password = newPassword;
  user.otpCode = undefined;
  user.otpExpiresAt = undefined;
  user.otpAttempts = 0;
  user.phoneVerified = true;
  await user.save();

  res.json({ success: true, message: 'تم تغيير كلمة المرور، يمكنك الدخول الآن' });
});

// DELETE /api/auth/me — حذف الحساب نهائيًا (3.1 + القانون 18-07)
export const deleteAccount = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user._id).select('+password');
  if (!(await user.comparePassword(req.body.password))) {
    throw new ApiError(400, 'كلمة المرور غير صحيحة');
  }

  // حذف البيانات الشخصية المرافقة، مع إبقاء الحساب مُعلَّمًا كمحذوف
  await Profile.deleteOne({ user: user._id });
  user.status = 'deleted';
  user.fullName = 'حساب محذوف';
  user.email = undefined;
  user.phone = `deleted-${user._id}`;
  user.avatar = undefined;
  user.fcmTokens = [];
  await user.save({ validateBeforeSave: false });

  res.json({ success: true, message: 'تم حذف الحساب نهائيًا' });
});

// POST /api/auth/fcm-token — تسجيل رمز الجهاز للإشعارات
export const registerFcmToken = asyncHandler(async (req, res) => {
  const { token } = req.body;
  await User.updateOne({ _id: req.user._id }, { $addToSet: { fcmTokens: token } });
  res.json({ success: true, message: 'تم تسجيل الجهاز' });
});
