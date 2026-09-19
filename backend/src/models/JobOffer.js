import mongoose from 'mongoose';
import {
  WILAYA_NAMES,
  SECTOR_KEYS,
  CONTRACT_KEYS,
  EDUCATION_KEYS,
  EXPERIENCE_KEYS,
  OFFER_STATUS,
} from '../config/constants.js';

// كيان «عرض العمل JobOffer» — الفصل 7
const jobOfferSchema = new mongoose.Schema(
  {
    company: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },
    postedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

    // حقول إجبارية — 3.6
    title: { type: String, required: true, trim: true, maxlength: 120 },
    profession: { type: String, required: true, trim: true },
    sector: { type: String, enum: SECTOR_KEYS, required: true },
    wilaya: { type: String, enum: WILAYA_NAMES, required: true },
    contractType: { type: String, enum: CONTRACT_KEYS, required: true },

    // الراتب اختياري — 3.6
    salaryMin: { type: Number, min: 0 },
    salaryMax: { type: Number, min: 0 },
    salaryHidden: { type: Boolean, default: false },

    description: { type: String, required: true, maxlength: 5000 },
    skills: [{ type: String, trim: true, maxlength: 40 }],
    educationLevel: { type: String, enum: EDUCATION_KEYS },
    experienceLevel: { type: String, enum: EXPERIENCE_KEYS },
    positions: { type: Number, min: 1, default: 1 },

    // الموقع الجغرافي — للترتيب «الأقرب جغرافيًا» (3.3)
    // اختياري: يُحذف الحقل كاملًا عند غياب الإحداثيات حتى لا يرفضه فهرس 2dsphere
    location: {
      type: {
        type: String,
        enum: ['Point'],
      },
      coordinates: { type: [Number] }, // [lng, lat]
    },

    // دورة حياة العرض: مراجعة المشرف قبل الظهور (3.6 — مكافحة الإعلانات الوهمية)
    status: {
      type: String,
      enum: Object.values(OFFER_STATUS),
      default: OFFER_STATUS.PENDING,
      index: true,
    },
    rejectionReason: { type: String },
    reviewedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    reviewedAt: { type: Date },

    publishedAt: { type: Date },
    expiresAt: { type: Date, required: true },

    // عرض مميّز مدفوع — يُبرز في أعلى النتائج (3.8)
    featured: { type: Boolean, default: false },
    featuredUntil: { type: Date },

    viewsCount: { type: Number, default: 0 },
    applicationsCount: { type: Number, default: 0 },
  },
  { timestamps: true }
);

// فهرس نصّي — البحث السريع بالوظيفة/المهنة/الشركة (3.2)
jobOfferSchema.index({ title: 'text', description: 'text', profession: 'text', skills: 'text' });
// فهارس التصفية الأكثر استعمالًا (3.3)
jobOfferSchema.index({ status: 1, wilaya: 1, sector: 1, contractType: 1, publishedAt: -1 });
jobOfferSchema.index({ status: 1, featured: -1, publishedAt: -1 });
jobOfferSchema.index({ location: '2dsphere' });

// هل العرض ظاهر للعموم الآن
jobOfferSchema.virtual('isLive').get(function isLive() {
  return this.status === OFFER_STATUS.APPROVED && this.expiresAt > new Date();
});

jobOfferSchema.virtual('isFeaturedNow').get(function isFeaturedNow() {
  return Boolean(this.featured && this.featuredUntil && this.featuredUntil > new Date());
});

jobOfferSchema.set('toJSON', { virtuals: true });
jobOfferSchema.set('toObject', { virtuals: true });

// فهرس 2dsphere يرفض { type: 'Point' } دون إحداثيات، لذا نحذف الحقل كاملًا
jobOfferSchema.pre('save', function dropEmptyLocation(next) {
  if (!this.location?.coordinates?.length) {
    this.location = undefined;
  } else {
    this.location.type = 'Point';
  }
  next();
});

// مدّة الصلاحية الافتراضية 30 يومًا إن لم تُحدَّد
jobOfferSchema.pre('validate', function setDefaultExpiry(next) {
  if (!this.expiresAt) {
    this.expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  }
  next();
});

// الراتب الأدنى لا يتجاوز الأقصى
jobOfferSchema.pre('validate', function checkSalary(next) {
  if (this.salaryMin != null && this.salaryMax != null && this.salaryMin > this.salaryMax) {
    return next(new Error('الراتب الأدنى لا يمكن أن يتجاوز الراتب الأقصى'));
  }
  next();
});

export default mongoose.model('JobOffer', jobOfferSchema);
