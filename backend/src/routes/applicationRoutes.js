import { Router } from 'express';
import { body } from 'express-validator';
import * as ctrl from '../controllers/applicationController.js';
import { protect, restrictTo } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';
import { ROLES, APPLICATION_STATUS } from '../config/constants.js';

const router = Router();

router.use(protect);

router.post(
  '/',
  restrictTo(ROLES.SEEKER),
  [
    body('offerId').isMongoId().withMessage('معرّف العرض غير صالح'),
    body('coverLetter').optional({ values: 'falsy' }).isLength({ max: 2000 }),
  ],
  validate,
  ctrl.apply
);

router.get('/mine', restrictTo(ROLES.SEEKER), ctrl.myApplications);
router.get('/offer/:offerId', restrictTo(ROLES.COMPANY), ctrl.applicationsForOffer);
router.get('/:id', ctrl.getApplication);

router.patch(
  '/:id/status',
  restrictTo(ROLES.COMPANY),
  [
    body('status')
      .isIn([APPLICATION_STATUS.ACCEPTED, APPLICATION_STATUS.REJECTED])
      .withMessage('حالة غير صالحة'),
    body('note').optional({ values: 'falsy' }).isLength({ max: 500 }),
  ],
  validate,
  ctrl.updateApplicationStatus
);

router.delete('/:id', restrictTo(ROLES.SEEKER), ctrl.withdrawApplication);

export default router;
