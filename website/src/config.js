/* ──────────────────────────────────────────────────────────────
   إعدادات الموقع — عدّل هذا الملف وحده لتحديث روابط التحميل
   ────────────────────────────────────────────────────────────── */

/**
 * ⚠️ ضع هنا رابط ملف APK بعد رفعه.
 *
 * خيارات الاستضافة:
 *  • GitHub Releases  → https://github.com/<user>/<repo>/releases/download/v1.0.0/app-release.apk
 *  • Google Drive     → استعمل رابط التحميل المباشر لا رابط المعاينة:
 *                       https://drive.google.com/uc?export=download&id=<FILE_ID>
 *  • أي استضافة أخرى  → الرابط المباشر للملف
 *
 * ما دام الرابط '#' فسيعرض الموقع رسالة «سيتوفّر قريبًا» بدل رابط مكسور.
 */
export const APK_URL = '#';

/** حجم الملف كما يظهر للزائر */
export const APK_SIZE = '21 ميغابايت';

/** رقم الإصدار */
export const APP_VERSION = '1.0.0';

/** روابط المتاجر — اتركها فارغة إلى حين النشر */
export const PLAY_STORE_URL = '';
export const APP_STORE_URL = '';

/** هل رابط التحميل جاهز فعلًا؟ */
export const isDownloadReady = APK_URL !== '#' && APK_URL.length > 1;

/** معلومات التواصل */
export const CONTACT_EMAIL = 'contact@bahth-dz.example';
