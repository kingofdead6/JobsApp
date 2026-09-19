import { Router } from 'express';
import { body } from 'express-validator';
import * as ctrl from '../controllers/savedController.js';
import { protect } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';

const router = Router();

router.use(protect);

router.get('/offers', ctrl.listSavedOffers);
router.post('/offers/:offerId', ctrl.saveOffer);
router.delete('/offers/:offerId', ctrl.unsaveOffer);

router.get('/searches', ctrl.listSavedSearches);
router.post(
  '/searches',
  [
    body('label').trim().isLength({ min: 1, max: 80 }).withMessage('سمِّ هذا البحث'),
    body('criteria').isObject().withMessage('معايير البحث مطلوبة'),
  ],
  validate,
  ctrl.saveSearch
);
router.patch('/searches/:id', ctrl.toggleSearchAlert);
router.delete('/searches/:id', ctrl.deleteSavedSearch);

export default router;
