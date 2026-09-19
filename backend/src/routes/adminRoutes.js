import { Router } from 'express';
import { body } from 'express-validator';
import * as ctrl from '../controllers/adminController.js';
import { protect, restrictTo } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { ROLES } from '../config/constants.js';

const router = Router();

// كل مسارات لوحة الإدارة محصورة بدور المشرف
router.use(protect, restrictTo(ROLES.ADMIN));

router.get('/stats', ctrl.getStats);

// مصادقة العروض
router.get('/offers', ctrl.listOffers);
router.patch(
  '/offers/:id/review',
  [
    body('decision').isIn(['approve', 'reject']).withMessage('قرار غير معروف'),
    body('reason').optional({ values: 'falsy' }).isLength({ max: 500 }),
  ],
  validate,
  ctrl.reviewOffer
);
router.patch('/offers/:id/feature', ctrl.featureOffer);

// المستخدمون
router.get('/users', ctrl.listUsers);
router.patch(
  '/users/:id/status',
  [body('status').isIn(['active', 'suspended']).withMessage('حالة غير صالحة')],
  validate,
  ctrl.setUserStatus
);

// المؤسسات
router.get('/companies', ctrl.listCompaniesAdmin);
router.patch(
  '/companies/:id/verify',
  [body('decision').isIn(['approve', 'reject']).withMessage('قرار غير معروف')],
  validate,
  ctrl.verifyCompany
);
router.patch('/companies/:id/subscription', ctrl.setSubscription);

// البلاغات
router.get('/reports', ctrl.listReports);
router.patch('/reports/:id', ctrl.handleReport);

// المحتوى الترويجي
router.get('/banners', ctrl.listBanners);
router.post(
  '/banners',
  [body('title').trim().isLength({ min: 2, max: 120 }).withMessage('عنوان اللافتة مطلوب')],
  validate,
  ctrl.createBanner
);
router.patch('/banners/:id', ctrl.updateBanner);
router.delete('/banners/:id', ctrl.deleteBanner);

router.post(
  '/broadcast',
  [
    body('title').trim().isLength({ min: 2, max: 120 }).withMessage('عنوان الإشعار مطلوب'),
    body('body').optional({ values: 'falsy' }).isLength({ max: 400 }),
  ],
  validate,
  ctrl.sendBroadcast
);

export default router;
