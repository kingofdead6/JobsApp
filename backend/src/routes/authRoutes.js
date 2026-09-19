import { Router } from 'express';
import { body } from 'express-validator';
import rateLimit from 'express-rate-limit';
import * as ctrl from '../controllers/authController.js';
import { protect } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { WILAYA_NAMES, ROLES } from '../config/constants.js';

const router = Router();

// حماية من إساءة الاستعمال — الفصل 5 «الأمن» (rate limiting)
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { success: false, message: 'محاولات كثيرة، أعد المحاولة بعد قليل' },
  standardHeaders: true,
  legacyHeaders: false,
});

const otpLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 6,
  message: { success: false, message: 'طلبات كثيرة لرمز التأكيد، حاول لاحقًا' },
});

const phoneRule = body('phone')
  .matches(/^0[5-7]\d{8}$/)
  .withMessage('رقم الهاتف يجب أن يبدأ بـ 05 أو 06 أو 07 ويتكوّن من 10 أرقام');

const passwordRule = body('password')
  .isLength({ min: 6 })
  .withMessage('كلمة المرور يجب ألّا تقلّ عن 6 محارف');

router.post(
  '/register',
  authLimiter,
  [
    body('fullName').trim().isLength({ min: 3, max: 80 }).withMessage('الاسم الكامل مطلوب'),
    phoneRule,
    passwordRule,
    body('email').optional({ values: 'falsy' }).isEmail().withMessage('بريد إلكتروني غير صالح'),
    body('role').isIn([ROLES.SEEKER, ROLES.COMPANY]).withMessage('نوع الحساب غير صالح'),
    body('wilaya').optional().isIn(WILAYA_NAMES).withMessage('ولاية غير معروفة'),
  ],
  validate,
  ctrl.register
);

router.post(
  '/verify-otp',
  otpLimiter,
  [phoneRule, body('code').isLength({ min: 6, max: 6 }).withMessage('الرمز يتكوّن من 6 أرقام')],
  validate,
  ctrl.verifyOtp
);

router.post('/resend-otp', otpLimiter, [phoneRule], validate, ctrl.resendOtp);

router.post(
  '/login',
  authLimiter,
  [
    body('identifier').trim().notEmpty().withMessage('أدخل رقم الهاتف أو البريد الإلكتروني'),
    body('password').notEmpty().withMessage('أدخل كلمة المرور'),
  ],
  validate,
  ctrl.login
);

router.post('/forgot-password', otpLimiter, [phoneRule], validate, ctrl.forgotPassword);

router.post(
  '/reset-password',
  otpLimiter,
  [
    phoneRule,
    body('code').isLength({ min: 6, max: 6 }).withMessage('الرمز يتكوّن من 6 أرقام'),
    body('newPassword').isLength({ min: 6 }).withMessage('كلمة المرور يجب ألّا تقلّ عن 6 محارف'),
  ],
  validate,
  ctrl.resetPassword
);

router.get('/me', protect, ctrl.getMe);

router.patch(
  '/password',
  protect,
  [
    body('currentPassword').notEmpty().withMessage('أدخل كلمة المرور الحالية'),
    body('newPassword').isLength({ min: 6 }).withMessage('كلمة المرور يجب ألّا تقلّ عن 6 محارف'),
  ],
  validate,
  ctrl.changePassword
);

router.delete(
  '/me',
  protect,
  [body('password').notEmpty().withMessage('أدخل كلمة المرور للتأكيد')],
  validate,
  ctrl.deleteAccount
);

router.post(
  '/fcm-token',
  protect,
  [body('token').notEmpty().withMessage('الرمز مطلوب')],
  validate,
  ctrl.registerFcmToken
);

export default router;
