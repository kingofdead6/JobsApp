import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import { WILAYA_NAMES, ROLES } from '../config/constants.js';

// كيان «المستخدم User» — الفصل 7 من دفتر الشروط
const userSchema = new mongoose.Schema(
  {
    fullName: { type: String, required: true, trim: true, maxlength: 80 },

    // رقم الهاتف الجزائري بصيغة موحّدة 0XXXXXXXXX
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
      match: [/^0[5-7]\d{8}$/, 'رقم هاتف جزائري غير صالح'],
    },

    email: {
      type: String,
      trim: true,
      lowercase: true,
      sparse: true,
      unique: true,
      match: [/^\S+@\S+\.\S+$/, 'بريد إلكتروني غير صالح'],
    },

    password: { type: String, required: true, minlength: 6, select: false },

    role: {
      type: String,
      enum: Object.values(ROLES),
      required: true,
      default: ROLES.SEEKER,
    },

    wilaya: { type: String, enum: WILAYA_NAMES },
    avatar: { type: String },

    // تأكيد الهوية برمز OTP
    phoneVerified: { type: Boolean, default: false },
    otpCode: { type: String, select: false },
    otpExpiresAt: { type: Date, select: false },
    otpAttempts: { type: Number, default: 0, select: false },

    // تسجيل الدخول عبر مزوّد خارجي
    provider: { type: String, enum: ['local', 'google', 'facebook'], default: 'local' },
    providerId: { type: String, sparse: true },

    // الحالة — يديرها المشرف (تعليق/حذف)
    status: {
      type: String,
      enum: ['active', 'suspended', 'deleted'],
      default: 'active',
    },
    suspensionReason: { type: String },

    // الإشعارات الفورية
    fcmTokens: [{ type: String }],
    notificationPrefs: {
      matchingOffers: { type: Boolean, default: true },
      applicationStatus: { type: Boolean, default: true },
      messages: { type: Boolean, default: true },
    },

    // اللغة المفضّلة — 3.9 واجهة متعدّدة اللغات
    locale: { type: String, enum: ['ar', 'fr', 'ber'], default: 'ar' },

    lastLoginAt: { type: Date },
  },
  { timestamps: true }
);

userSchema.index({ role: 1, status: 1 });

// تخزين كلمات المرور مجزّأة (bcrypt) — الفصل 5 «الأمن»
userSchema.pre('save', async function hashPassword(next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

userSchema.methods.comparePassword = function comparePassword(candidate) {
  return bcrypt.compare(candidate, this.password);
};

// لا تُعاد الحقول الحسّاسة إلى العميل أبدًا
userSchema.methods.toJSON = function toJSON() {
  const obj = this.toObject();
  delete obj.password;
  delete obj.otpCode;
  delete obj.otpExpiresAt;
  delete obj.otpAttempts;
  delete obj.fcmTokens;
  return obj;
};

export default mongoose.model('User', userSchema);
