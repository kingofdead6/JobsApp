import jwt from 'jsonwebtoken';
import User from '../models/User.js';
import { ROLES } from '../config/constants.js';
import { ApiError } from '../utils/ApiError.js';

export function signToken(user) {
  return jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  });
}

// يتطلّب مستخدمًا مسجّل الدخول وحسابًا نشطًا
export async function protect(req, _res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) throw new ApiError(401, 'يجب تسجيل الدخول للوصول إلى هذه الخدمة');

    let payload;
    try {
      payload = jwt.verify(token, process.env.JWT_SECRET);
    } catch {
      throw new ApiError(401, 'الجلسة غير صالحة أو منتهية، يرجى إعادة تسجيل الدخول');
    }

    const user = await User.findById(payload.id);
    if (!user) throw new ApiError(401, 'الحساب غير موجود');
    if (user.status === 'suspended') {
      throw new ApiError(403, `الحساب معلّق. ${user.suspensionReason || ''}`.trim());
    }
    if (user.status === 'deleted') throw new ApiError(401, 'الحساب محذوف');

    req.user = user;
    next();
  } catch (err) {
    next(err);
  }
}

// صلاحيات حسب الدور — الفصل 5 «الأمن»
export function restrictTo(...roles) {
  return (req, _res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return next(new ApiError(403, 'ليست لديك صلاحية للقيام بهذا الإجراء'));
    }
    next();
  };
}

// بعض المسارات تتصرّف تصرّفًا مختلفًا إذا كان المستخدم مسجّلًا (مثل إظهار «محفوظ»)
export async function optionalAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next();

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.id);
    if (user && user.status === 'active') req.user = user;
  } catch {
    // تجاهل الرمز غير الصالح ونتابع كزائر
  }
  next();
}

// المؤسسة يجب أن تكون قد أنشأت ملفها قبل نشر العروض
export function requireVerifiedPhone(req, _res, next) {
  if (!req.user.phoneVerified) {
    return next(new ApiError(403, 'يجب تأكيد رقم الهاتف أولًا'));
  }
  next();
}

export { ROLES };
