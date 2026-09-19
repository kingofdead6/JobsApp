import mongoose from 'mongoose';
import { SECTOR_KEYS, WILAYA_NAMES } from '../config/constants.js';

// كيان «المؤسسة Company» — صفحة تعريف وتوثيق (3.8)
const companySchema = new mongoose.Schema(
  {
    owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },

    name: { type: String, required: true, trim: true, maxlength: 120 },
    logo: { type: String },
    sector: { type: String, enum: SECTOR_KEYS, required: true },
    description: { type: String, maxlength: 2000 },

    wilaya: { type: String, enum: WILAYA_NAMES, required: true },
    address: { type: String, maxlength: 200 },
    website: { type: String, trim: true },
    contactPhone: { type: String, match: [/^0[5-7]\d{8}$/, 'رقم هاتف غير صالح'] },
    contactEmail: { type: String, lowercase: true, trim: true },

    employeesRange: {
      type: String,
      enum: ['1-10', '11-50', '51-200', '201-500', '500+'],
    },
    foundedYear: { type: Number, min: 1900, max: 2100 },

    // شارة «مؤسسة موثّقة» بعد التحقّق من السجل التجاري — 3.8
    commercialRegister: { type: String, trim: true },
    registerDocument: { type: String },
    verificationStatus: {
      type: String,
      enum: ['unverified', 'pending', 'verified', 'rejected'],
      default: 'unverified',
    },
    verificationNote: { type: String },
    verifiedAt: { type: Date },

    // اشتراك المؤسسة — الفصل 8 «نموذج الأعمال»
    subscription: {
      plan: { type: String, enum: ['free', 'monthly', 'yearly'], default: 'free' },
      expiresAt: { type: Date },
      cvDatabaseAccess: { type: Boolean, default: false },
    },

    // تقييم متبادل — 3.9
    rating: {
      average: { type: Number, default: 0, min: 0, max: 5 },
      count: { type: Number, default: 0 },
    },
  },
  { timestamps: true }
);

companySchema.index({ name: 'text', description: 'text' });
companySchema.index({ wilaya: 1, sector: 1 });

companySchema.virtual('isVerified').get(function isVerified() {
  return this.verificationStatus === 'verified';
});

// هل الاشتراك ساري المفعول الآن
companySchema.virtual('subscriptionActive').get(function subscriptionActive() {
  if (this.subscription?.plan === 'free') return false;
  return Boolean(this.subscription?.expiresAt && this.subscription.expiresAt > new Date());
});

companySchema.set('toJSON', { virtuals: true });
companySchema.set('toObject', { virtuals: true });

export default mongoose.model('Company', companySchema);
