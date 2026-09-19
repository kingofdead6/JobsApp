import mongoose from 'mongoose';

// كيان «المفضّلة / التنبيه» — الفصل 7
// نوعان: عرض محفوظ (favorite) أو معايير بحث محفوظة مع تنبيه (search)
const savedItemSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    kind: { type: String, enum: ['favorite', 'search'], required: true },

    // kind = favorite
    offer: { type: mongoose.Schema.Types.ObjectId, ref: 'JobOffer' },

    // kind = search — حفظ عمليات البحث وتلقّي تنبيه عند ظهور عرض مطابق (3.3)
    label: { type: String, trim: true, maxlength: 80 },
    criteria: {
      q: String,
      wilaya: String,
      sector: String,
      contractType: String,
      salaryMin: Number,
      educationLevel: String,
      experienceLevel: String,
    },
    alertEnabled: { type: Boolean, default: true },
    lastAlertedAt: { type: Date },
  },
  { timestamps: true }
);

// عرض واحد لا يُحفظ مرّتين لنفس المستخدم
savedItemSchema.index(
  { user: 1, offer: 1 },
  { unique: true, partialFilterExpression: { kind: 'favorite' } }
);
savedItemSchema.index({ user: 1, kind: 1, createdAt: -1 });
savedItemSchema.index({ kind: 1, alertEnabled: 1 });

export default mongoose.model('SavedItem', savedItemSchema);
