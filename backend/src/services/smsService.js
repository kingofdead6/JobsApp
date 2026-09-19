import crypto from 'node:crypto';

// توليد رمز OTP من 6 أرقام بمولّد عشوائي آمن
export function generateOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

/**
 * إرسال رمز التأكيد عبر مزوّد SMS محلّي.
 * في بيئة التطوير (بدون مفتاح) يُطبع الرمز في السجلّ بدل إرساله،
 * وهو ما يقلّل تكلفة الرسائل المذكورة في الفصل 13 «المخاطر».
 */
export async function sendOtpSms(phone, code) {
  const apiKey = process.env.SMS_PROVIDER_KEY;

  if (!apiKey) {
    console.log(`[sms:dev] رمز التأكيد للرقم ${phone} هو: ${code}`);
    return { delivered: false, devMode: true };
  }

  // نقطة الإدماج مع المزوّد الجزائري المختار عند الانتقال للإنتاج.
  // تُترك دون تنفيذ فعلي إلى حين التعاقد مع المزوّد وتحديد واجهته.
  throw new Error('مزوّد الرسائل القصيرة غير مُدمج بعد — أزل SMS_PROVIDER_KEY للعمل في وضع التطوير');
}

// صلاحية الرمز: 10 دقائق
export const OTP_TTL_MS = 10 * 60 * 1000;
export const OTP_MAX_ATTEMPTS = 5;
