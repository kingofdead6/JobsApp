import multer from 'multer';
import path from 'node:path';
import crypto from 'node:crypto';
import { ApiError } from '../utils/ApiError.js';

const UPLOAD_ROOT = path.resolve('uploads');

// اسم ملف عشوائي: لا نثق أبدًا بالاسم الأصلي (منع اجتياز المسارات)
function makeStorage(folder) {
  return multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, path.join(UPLOAD_ROOT, folder)),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase().slice(0, 10);
      cb(null, `${Date.now()}-${crypto.randomBytes(8).toString('hex')}${ext}`);
    },
  });
}

function filterByMime(allowed, messageAr) {
  return (_req, file, cb) => {
    if (allowed.includes(file.mimetype)) return cb(null, true);
    cb(new ApiError(400, messageAr));
  };
}

const IMAGE_MIMES = ['image/jpeg', 'image/png', 'image/webp'];

// السيرة الذاتية: PDF فقط، 5 ميغابايت كحد أقصى
export const uploadCv = multer({
  storage: makeStorage('cv'),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
  fileFilter: filterByMime(['application/pdf'], 'يُقبل ملف PDF فقط للسيرة الذاتية'),
});

// شعار المؤسسة: صورة، 2 ميغابايت
export const uploadLogo = multer({
  storage: makeStorage('logos'),
  limits: { fileSize: 2 * 1024 * 1024, files: 1 },
  fileFilter: filterByMime(IMAGE_MIMES, 'يُقبل ملف صورة فقط (JPEG أو PNG أو WebP)'),
});

// الصورة الشخصية: صورة، 2 ميغابايت
export const uploadAvatar = multer({
  storage: makeStorage('avatars'),
  limits: { fileSize: 2 * 1024 * 1024, files: 1 },
  fileFilter: filterByMime(IMAGE_MIMES, 'يُقبل ملف صورة فقط (JPEG أو PNG أو WebP)'),
});

// وثيقة السجل التجاري: PDF أو صورة، 5 ميغابايت
export const uploadRegisterDoc = multer({
  storage: makeStorage('logos'),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
  fileFilter: filterByMime(
    ['application/pdf', ...IMAGE_MIMES],
    'يُقبل ملف PDF أو صورة فقط'
  ),
});

// المسار العمومي الذي يُخزَّن في قاعدة البيانات
export function publicPath(file, folder) {
  return file ? `/uploads/${folder}/${file.filename}` : undefined;
}
