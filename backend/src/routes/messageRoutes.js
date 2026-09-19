import { Router } from 'express';
import { body } from 'express-validator';
import * as ctrl from '../controllers/messageController.js';
import { protect } from '../middleware/auth.js';
import { validate } from '../middleware/validate.js';

const router = Router();

router.use(protect);

router.get('/conversations', ctrl.listConversations);
router.get('/unread-count', ctrl.unreadCount);
router.get('/conversations/:id', ctrl.getMessages);

router.post(
  '/',
  [body('body').trim().isLength({ min: 1, max: 2000 }).withMessage('نص الرسالة مطلوب')],
  validate,
  ctrl.sendMessage
);

export default router;
