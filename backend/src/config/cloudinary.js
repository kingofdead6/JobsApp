import { v2 as cloudinary } from 'cloudinary';

/**
 * تخزين الملفات على Cloudinary — خدمة تخزين كائنات للصور وملفات PDF
 * (الفصل 6 من دفتر الشروط: فصل الملفات عن القاعدة وتخفيف الحمل).
 *
 * ضروري على Render: نظام الملفات هناك مؤقّت، وكل إعادة نشر تمحو
 * ما رُفع محليًا، فلا يصلح تخزين الملفات بجانب التطبيق.
 */

const { CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET } =
  process.env;

export const cloudinaryEnabled = Boolean(
  CLOUDINARY_CLOUD_NAME && CLOUDINARY_API_KEY && CLOUDINARY_API_SECRET
);

if (cloudinaryEnabled) {
  cloudinary.config({
    cloud_name: CLOUDINARY_CLOUD_NAME,
    api_key: CLOUDINARY_API_KEY,
    api_secret: CLOUDINARY_API_SECRET,
    secure: true,
  });
  console.log('[cloudinary] التخزين السحابي مفعّل');
} else {
  console.warn(
    '[cloudinary] المفاتيح غير مضبوطة — سيُستعمل التخزين المحلي (للتطوير فقط)'
  );
}

/** المجلّدات على Cloudinary، مطابقة لتقسيم الملفات محليًا */
export const FOLDERS = {
  cv: 'bahth-dz/cv',
  logos: 'bahth-dz/logos',
  avatars: 'bahth-dz/avatars',
};

/**
 * يرفع محتوى الملف من الذاكرة إلى Cloudinary.
 *
 * ملفات PDF تُرفع بنوع `raw` لأن Cloudinary يعالج `image` كصورة
 * ويرفض الملفات غير المصوّرة.
 */
export function uploadBuffer(buffer, { folder, mimetype, filename }) {
  const isPdf = mimetype === 'application/pdf';

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: isPdf ? 'raw' : 'image',
        // اسم عشوائي من Cloudinary: لا نثق باسم الملف الأصلي
        use_filename: false,
        unique_filename: true,
        overwrite: false,
        // ضغط الصور وتحديد أبعادها القصوى — «صور مضغوطة» (الفصل 5)
        ...(isPdf
          ? {}
          : {
              transformation: [
                { width: 1200, height: 1200, crop: 'limit' },
                { quality: 'auto:good', fetch_format: 'auto' },
              ],
            }),
      },
      (error, result) => {
        if (error) return reject(error);
        resolve({
          url: result.secure_url,
          publicId: result.public_id,
          resourceType: result.resource_type,
          originalName: filename,
        });
      }
    );

    stream.end(buffer);
  });
}

/** يحذف ملفًا سبق رفعه (عند استبدال شعار أو سيرة ذاتية) */
export async function destroyAsset(publicId, resourceType = 'image') {
  if (!cloudinaryEnabled || !publicId) return;
  try {
    await cloudinary.uploader.destroy(publicId, { resource_type: resourceType });
  } catch (err) {
    // حذف الملف القديم ليس حرجًا: نسجّل الخطأ ونتابع
    console.error('[cloudinary] تعذّر حذف الملف:', err.message);
  }
}

export default cloudinary;
