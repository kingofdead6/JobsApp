import mongoose from 'mongoose';

// اللافتة الترويجية القابلة للتحديث من لوحة الإدارة (3.2 + الفصل 4)
const bannerSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, maxlength: 120 },
    subtitle: { type: String, maxlength: 200 },
    ctaLabel: { type: String, maxlength: 40 },
    image: { type: String },

    // وجهة الضغط: رابط خارجي أو شاشة داخلية
    linkType: { type: String, enum: ['none', 'url', 'offer', 'search'], default: 'none' },
    linkValue: { type: String },

    active: { type: Boolean, default: true },
    order: { type: Number, default: 0 },
    startsAt: { type: Date },
    endsAt: { type: Date },
  },
  { timestamps: true }
);

bannerSchema.index({ active: 1, order: 1 });

export default mongoose.model('Banner', bannerSchema);
