import { Router } from 'express';
import { body } from 'express-validator';
import * as ctrl from '../controllers/companyController.js';
import { protect, restrictTo } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { uploadLogo, uploadRegisterDoc } from '../middleware/upload.js';
import { ROLES, WILAYA_NAMES, SECTOR_KEYS } from '../config/constants.js';

const router = Router();

// المسارات الخاصة بالمؤسسة الحالية تسبق /:id
router.get('/me', protect, restrictTo(ROLES.COMPANY), ctrl.getMyCompany);
router.get('/me/stats', protect, restrictTo(ROLES.COMPANY), ctrl.myCompanyStats);

router.patch('/me', protect, restrictTo(ROLES.COMPANY), ctrl.updateMyCompany);

router.post(
  '/me/logo',
  protect,
  restrictTo(ROLES.COMPANY),
  uploadLogo.single('logo'),
  ctrl.uploadCompanyLogo
);

router.post(
  '/me/verification',
  protect,
  restrictTo(ROLES.COMPANY),
  uploadRegisterDoc.single('document'),
  ctrl.requestVerification
);

router.post(
  '/',
  protect,
  restrictTo(ROLES.COMPANY),
  [
    body('name').trim().isLength({ min: 2, max: 120 }).withMessage('اسم المؤسسة مطلوب'),
    body('sector').isIn(SECTOR_KEYS).withMessage('القطاع غير صالح'),
    body('wilaya').isIn(WILAYA_NAMES).withMessage('الولاية غير صالحة'),
    body('contactPhone').optional({ values: 'falsy' }).matches(/^0[5-7]\d{8}$/),
    body('contactEmail').optional({ values: 'falsy' }).isEmail(),
  ],
  validate,
  ctrl.createCompany
);

// مسارات عمومية
router.get('/', ctrl.listCompanies);
router.get('/:id', ctrl.getCompany);

export default router;
