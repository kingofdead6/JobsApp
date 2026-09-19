import mongoose from 'mongoose';
import { SECTOR_KEYS, EDUCATION_KEYS, WILAYA_NAMES } from '../config/constants.js';

// كيان «الملف المهني Profile» — السيرة الذاتية الرقمية (3.5)
const experienceSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    company: { type: String, trim: true },
    wilaya: { type: String, enum: WILAYA_NAMES },
    startDate: { type: Date, required: true },
    endDate: { type: Date },
    current: { type: Boolean, default: false },
    description: { type: String, maxlength: 600 },
  },
  { _id: true }
);

const educationSchema = new mongoose.Schema(
  {
    degree: { type: String, required: true, trim: true },
    institution: { type: String, trim: true },
    level: { type: String, enum: EDUCATION_KEYS },
    year: { type: Number, min: 1950, max: 2100 },
  },
  { _id: true }
);

const languageSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    level: { type: String, enum: ['basic', 'good', 'fluent', 'native'], default: 'good' },
  },
  { _id: false }
);

const profileSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },

    headline: { type: String, trim: true, maxlength: 120 }, // مثال: تقني سامي في الإعلام الآلي
    bio: { type: String, maxlength: 1000 },
    sector: { type: String, enum: SECTOR_KEYS },
    profession: { type: String, trim: true },

    educationLevel: { type: String, enum: EDUCATION_KEYS },
    yearsOfExperience: { type: Number, min: 0, max: 60, default: 0 },

    experiences: [experienceSchema],
    educations: [educationSchema],
    skills: [{ type: String, trim: true, maxlength: 40 }],
    languages: [languageSchema],

    birthDate: { type: Date },
    address: { type: String, maxlength: 200 },

    cvFile: { type: String },      // ملف PDF مرفوع
    cvFileName: { type: String },

    // هل تظهر السيرة الذاتية للمؤسسات المشتركة (نموذج الأعمال، الفصل 8)
    visibleToCompanies: { type: Boolean, default: true },
  },
  { timestamps: true }
);

// مؤشّر اكتمال الملف (%) — 3.5، يحفّز المستخدم على إتمامه
profileSchema.virtual('completion').get(function completion() {
  const checks = [
    Boolean(this.headline),
    Boolean(this.bio),
    Boolean(this.sector),
    Boolean(this.profession),
    Boolean(this.educationLevel),
    this.experiences?.length > 0,
    this.educations?.length > 0,
    this.skills?.length > 0,
    this.languages?.length > 0,
    Boolean(this.cvFile),
  ];
  return Math.round((checks.filter(Boolean).length / checks.length) * 100);
});

profileSchema.set('toJSON', { virtuals: true });
profileSchema.set('toObject', { virtuals: true });

// فهرس نصّي للبحث في قاعدة السير الذاتية (ميزة اشتراك المؤسسات)
profileSchema.index({ headline: 'text', profession: 'text', skills: 'text' });

export default mongoose.model('Profile', profileSchema);
