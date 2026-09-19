import { Router } from 'express';
import { body } from 'express-validator';
import * as ctrl from '../controllers/profileController.js';
import { protect, restrictTo } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { uploadCv, uploadAvatar } from '../middleware/upload.js';
import { ROLES, WILAYA_NAMES, SECTOR_KEYS, EDUCATION_KEYS } from '../config/constants.js';

const router = Router();

router.use(protect);

// قاعدة السير الذاتية — للمؤسسات المشتركة فقط
router.get('/cv-database', restrictTo(ROLES.COMPANY), ctrl.searchCvDatabase);

router.get('/me', ctrl.getMyProfile);

router.patch(
  '/me',
  [
    body('fullName').optional().trim().isLength({ min: 3, max: 80 }),
    body('wilaya').optional({ values: 'falsy' }).isIn(WILAYA_NAMES).withMessage('ولاية غير معروفة'),
    body('email').optional({ values: 'falsy' }).isEmail().withMessage('بريد إلكتروني غير صالح'),
    body('sector').optional({ values: 'falsy' }).isIn(SECTOR_KEYS),
    body('educationLevel').optional({ values: 'falsy' }).isIn(EDUCATION_KEYS),
    body('yearsOfExperience').optional().isInt({ min: 0, max: 60 }),
    body('skills').optional().isArray({ max: 40 }),
  ],
  validate,
  ctrl.updateMyProfile
);

router.post(
  '/experiences',
  [
    body('title').trim().notEmpty().withMessage('المسمى الوظيفي مطلوب'),
    body('startDate').isISO8601().withMessage('تاريخ البداية غير صالح'),
  ],
  validate,
  ctrl.addExperience
);
router.delete('/experiences/:expId', ctrl.removeExperience);

router.post(
  '/educations',
  [body('degree').trim().notEmpty().withMessage('اسم الشهادة مطلوب')],
  validate,
  ctrl.addEducation
);
router.delete('/educations/:eduId', ctrl.removeEducation);

router.post('/cv', uploadCv.single('cv'), ctrl.uploadCvFile);
router.post('/avatar', uploadAvatar.single('avatar'), ctrl.uploadAvatarFile);

export default router;
