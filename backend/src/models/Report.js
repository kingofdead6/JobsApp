import mongoose from 'mongoose';
import { REPORT_REASONS } from '../config/constants.js';

// كيان «البلاغ Report» — الإبلاغ عن عرض مشبوه أو احتيالي (3.4 + لوحة الإدارة)
const reportSchema = new mongoose.Schema(
  {
    reporter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

    targetType: { type: String, enum: ['offer', 'user', 'company'], required: true },
    targetId: { type: mongoose.Schema.Types.ObjectId, required: true },

    reason: { type: String, enum: REPORT_REASONS.map((r) => r.key), required: true },
    details: { type: String, maxlength: 1000 },

    status: {
      type: String,
      enum: ['open', 'reviewing', 'resolved', 'dismissed'],
      default: 'open',
    },
    resolution: { type: String, maxlength: 500 },
    handledBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    handledAt: { type: Date },
  },
  { timestamps: true }
);

reportSchema.index({ status: 1, createdAt: -1 });
reportSchema.index({ targetType: 1, targetId: 1 });
// بلاغ واحد لكل مستخدم على نفس الهدف
reportSchema.index({ reporter: 1, targetType: 1, targetId: 1 }, { unique: true });

export default mongoose.model('Report', reportSchema);
