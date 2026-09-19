import { validationResult } from 'express-validator';
import { ApiError } from '../utils/ApiError.js';

// يُوضع بعد سلسلة قواعد express-validator في تعريف المسار
export function validate(req, _res, next) {
  const result = validationResult(req);
  if (result.isEmpty()) return next();

  const details = result.array().map((e) => ({ field: e.path, message: e.msg }));
  next(new ApiError(400, details[0]?.message || 'البيانات المُدخلة غير صالحة', details));
}
