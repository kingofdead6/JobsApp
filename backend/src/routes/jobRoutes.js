import { Router } from 'express';
import { body } from 'express-validator';
import * as ctrl from '../controllers/jobController.js';
import { protect, restrictTo, optionalAuth } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import {
  WILAYA_NAMES,
  SECTOR_KEYS,
  CONTRACT_KEYS,
  EDUCATION_KEYS,
  EXPERIENCE_KEYS,
  ROLES,
} from '../config/constants.js';

const router = Router();

// المسارات الثابتة تسبق المسار المتغيّر /:id
router.get('/latest', ctrl.latestJobs);
router.get('/featured', ctrl.featuredJobs);
router.get('/by-wilaya', ctrl.jobsByWilaya);
router.get('/recommended', protect, ctrl.recommendedJobs);
router.get('/mine/list', protect, restrictTo(ROLES.COMPANY), ctrl.myJobs);

router.get('/', optionalAuth, ctrl.listJobs);
router.get('/:id', optionalAuth, ctrl.getJob);

// حقول العرض الإجبارية — 3.6
const offerRules = [
  body('title').trim().isLength({ min: 3, max: 120 }).withMessage('عنوان الوظيفة مطلوب'),
  body('profession').trim().notEmpty().withMessage('المهنة مطلوبة'),
  body('sector').isIn(SECTOR_KEYS).withMessage('القطاع غير صالح'),
  body('wilaya').isIn(WILAYA_NAMES).withMessage('الولاية غير صالحة'),
  body('contractType').isIn(CONTRACT_KEYS).withMessage('نوع العقد غير صالح'),
  body('description').trim().isLength({ min: 20, max: 5000 }).withMessage('وصف الوظيفة مطلوب (20 محرفًا على الأقل)'),
  body('salaryMin').optional({ values: 'null' }).isInt({ min: 0 }).withMessage('راتب غير صالح'),
  body('salaryMax').optional({ values: 'null' }).isInt({ min: 0 }).withMessage('راتب غير صالح'),
  body('educationLevel').optional({ values: 'falsy' }).isIn(EDUCATION_KEYS),
  body('experienceLevel').optional({ values: 'falsy' }).isIn(EXPERIENCE_KEYS),
  body('positions').optional().isInt({ min: 1, max: 999 }),
];

router.post('/', protect, restrictTo(ROLES.COMPANY), offerRules, validate, ctrl.createJob);
router.patch('/:id', protect, restrictTo(ROLES.COMPANY), ctrl.updateJob);
router.patch(
  '/:id/status',
  protect,
  restrictTo(ROLES.COMPANY),
  [body('action').isIn(['pause', 'resume', 'extend', 'republish']).withMessage('إجراء غير معروف')],
  validate,
  ctrl.changeJobState
);
router.delete('/:id', protect, ctrl.deleteJob);

export default router;
