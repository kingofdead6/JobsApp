import { ApiError } from '../utils/ApiError.js';

export function notFound(req, _res, next) {
  next(new ApiError(404, `المسار غير موجود: ${req.method} ${req.originalUrl}`));
}

// معالج الأخطاء المركزي — يعيد دائمًا { success, message } برسالة عربية
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, _req, res, _next) {
  let statusCode = err.statusCode || 500;
  let message = err.message || 'حدث خطأ غير متوقّع في الخادم';
  let details = err.details;

  // أخطاء التحقّق من Mongoose
  if (err.name === 'ValidationError') {
    statusCode = 400;
    details = Object.values(err.errors).map((e) => ({ field: e.path, message: e.message }));
    message = 'البيانات المُدخلة غير صالحة';
  }

  // معرّف ObjectId غير صالح
  if (err.name === 'CastError') {
    statusCode = 400;
    message = 'معرّف غير صالح';
  }

  // تكرار حقل فريد (هاتف، بريد، ترشّح مزدوج…)
  if (err.code === 11000) {
    statusCode = 409;
    const field = Object.keys(err.keyValue || {})[0];
    const labels = {
      phone: 'رقم الهاتف مستعمل من قبل',
      email: 'البريد الإلكتروني مستعمل من قبل',
      owner: 'لديك ملف مؤسسة بالفعل',
      user: 'لديك ملف شخصي بالفعل',
    };
    message = labels[field] || 'هذا السجل موجود مسبقًا';
  }

  // تجاوز حجم الملف المرفوع (multer)
  if (err.code === 'LIMIT_FILE_SIZE') {
    statusCode = 413;
    message = 'حجم الملف كبير جدًا';
  }

  if (statusCode >= 500) {
    console.error('[error]', err);
  }

  res.status(statusCode).json({
    success: false,
    message,
    ...(details ? { details } : {}),
    ...(process.env.NODE_ENV === 'development' && statusCode >= 500
      ? { stack: err.stack }
      : {}),
  });
}
