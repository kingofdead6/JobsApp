import mongoose from 'mongoose';
import { APPLICATION_STATUS } from '../config/constants.js';

// كيان «الترشّح Application» — الفصل 7
const applicationSchema = new mongoose.Schema(
  {
    offer: { type: mongoose.Schema.Types.ObjectId, ref: 'JobOffer', required: true },
    applicant: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    company: { type: mongoose.Schema.Types.ObjectId, ref: 'Company', required: true },

    // رسالة تحفيزية اختيارية — 3.4
    coverLetter: { type: String, maxlength: 2000 },

    // نسخة من السيرة الذاتية وقت الترشّح (حتى لا يتغيّر ما رآه صاحب العمل لاحقًا)
    cvSnapshot: { type: mongoose.Schema.Types.Mixed },

    status: {
      type: String,
      enum: Object.values(APPLICATION_STATUS),
      default: APPLICATION_STATUS.PENDING,
    },
    statusNote: { type: String, maxlength: 500 },
    statusChangedAt: { type: Date },

    viewedByCompany: { type: Boolean, default: false },
    conversation: { type: mongoose.Schema.Types.ObjectId, ref: 'Conversation' },
  },
  { timestamps: true }
);

// لا يترشّح المستخدم لنفس العرض مرّتين
applicationSchema.index({ offer: 1, applicant: 1 }, { unique: true });
applicationSchema.index({ applicant: 1, createdAt: -1 });
applicationSchema.index({ company: 1, status: 1, createdAt: -1 });

export default mongoose.model('Application', applicationSchema);
