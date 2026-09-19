import multer from 'multer';
import path from 'node:path';
import crypto from 'node:crypto';
import fs from 'node:fs/promises';
import { ApiError } from '../utils/ApiError.js';
import {
  cloudinaryEnabled,
  uploadBuffer,
  destroyAsset,
  FOLDERS,
} from '../config/cloudinary.js';

const UPLOAD_ROOT = path.resolve('uploads');

/**
 * الملفات تُستقبل في الذاكرة ثم تُرفع إلى Cloudinary.
 * عند غياب مفاتيح Cloudinary (تطوير محلي) تُكتب على القرص.
 */
function makeUploader({ allowed, maxSize, messageAr }) {
  return multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: maxSize, files: 1 },
    fileFilter: (_req, file, cb) => {
      if (allowed.includes(file.mimetype)) return cb(null, true);
      cb(new ApiError(400, messageAr));
    },
  });
}

const IMAGE_MIMES = ['image/jpeg', 'image/png', 'image/webp'];
const MB = 1024 * 1024;

// السيرة الذاتية: PDF فقط، 5 ميغابايت
export const uploadCv = makeUploader({
  allowed: ['application/pdf'],
  maxSize: 5 * MB,
  messageAr: 'يُقبل ملف PDF فقط للسيرة الذاتية',
});

// شعار المؤسسة: صورة، 2 ميغابايت
export const uploadLogo = makeUploader({
  allowed: IMAGE_MIMES,
  maxSize: 2 * MB,
  messageAr: 'يُقبل ملف صورة فقط (JPEG أو PNG أو WebP)',
});

// الصورة الشخصية: صورة، 2 ميغابايت
export const uploadAvatar = makeUploader({
  allowed: IMAGE_MIMES,
  maxSize: 2 * MB,
  messageAr: 'يُقبل ملف صورة فقط (JPEG أو PNG أو WebP)',
});

// وثيقة السجل التجاري: PDF أو صورة، 5 ميغابايت
export const uploadRegisterDoc = makeUploader({
  allowed: ['application/pdf', ...IMAGE_MIMES],
  maxSize: 5 * MB,
  messageAr: 'يُقبل ملف PDF أو صورة فقط',
});

/**
 * يخزّن الملف المستلم ويعيد `{ url, publicId, resourceType }`.
 * `kind` أحد: 'cv' | 'logos' | 'avatars'
 *
 * تُحفظ `publicId` في قاعدة البيانات لنتمكّن من حذف الملف القديم
 * عند استبداله، فلا تتراكم ملفات يتيمة على Cloudinary.
 */
export async function storeFile(file, kind) {
  if (!file) throw new ApiError(400, 'لم يتم إرفاق أي ملف');

  if (cloudinaryEnabled) {
    try {
      return await uploadBuffer(file.buffer, {
        folder: FOLDERS[kind],
        mimetype: file.mimetype,
        filename: file.originalname,
      });
    } catch (err) {
      console.error('[upload] فشل الرفع إلى Cloudinary:', err.message);
      throw new ApiError(502, 'تعذّر رفع الملف، حاول مرّة أخرى');
    }
  }

  // بديل التطوير المحلي: كتابة على القرص باسم عشوائي
  const ext = path.extname(file.originalname).toLowerCase().slice(0, 10);
  const name = `${Date.now()}-${crypto.randomBytes(8).toString('hex')}${ext}`;
  const dir = path.join(UPLOAD_ROOT, kind);

  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(path.join(dir, name), file.buffer);

  return {
    url: `/uploads/${kind}/${name}`,
    publicId: null,
    resourceType: file.mimetype === 'application/pdf' ? 'raw' : 'image',
    originalName: file.originalname,
  };
}

/** يحذف الملف السابق بعد نجاح رفع البديل */
export async function removeFile(publicId, resourceType) {
  await destroyAsset(publicId, resourceType);
}
