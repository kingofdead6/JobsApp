import { Router } from 'express';
import { body } from 'express-validator';
import * as ctrl from '../controllers/miscController.js';
import { protect } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { REPORT_REASONS } from '../config/constants.js';

const router = Router();

// مسارات عمومية
router.get('/reference', ctrl.getReference);
router.get('/banners', ctrl.getBanners);
router.get('/home', ctrl.getHomeFeed);

// البلاغات
router.post(
  '/reports',
  protect,
  [
    body('targetType').isIn(['offer', 'user', 'company']).withMessage('نوع الهدف غير صالح'),
    body('targetId').isMongoId().withMessage('معرّف غير صالح'),
    body('reason')
      .isIn(REPORT_REASONS.map((r) => r.key))
      .withMessage('سبب البلاغ غير صالح'),
    body('details').optional({ values: 'falsy' }).isLength({ max: 1000 }),
  ],
  validate,
  ctrl.createReport
);

// الإشعارات
router.get('/notifications', protect, ctrl.listNotifications);
router.patch('/notifications/read', protect, ctrl.markNotificationsRead);
router.delete('/notifications/:id', protect, ctrl.deleteNotification);

export default router;
