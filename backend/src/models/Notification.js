import mongoose from 'mongoose';

// الإشعارات (3.7): عرض جديد مطابق، تغيّر حالة الطلب، رسالة جديدة
const notificationSchema = new mongoose.Schema(
  {
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: {
      type: String,
      enum: [
        'matching_offer',      // عرض جديد مطابق لبحث محفوظ
        'application_status',  // تغيّر حالة الترشّح
        'new_message',         // رسالة جديدة
        'offer_approved',      // مصادقة المشرف على عرضك
        'offer_rejected',      // رفض عرضك
        'new_application',     // ترشّح جديد على عرضك
        'company_verified',    // توثيق المؤسسة
        'broadcast',           // إشعار جماعي من لوحة الإدارة
      ],
      required: true,
    },
    title: { type: String, required: true, maxlength: 120 },
    body: { type: String, maxlength: 400 },

    // للتنقّل داخل التطبيق عند الضغط على الإشعار
    data: { type: mongoose.Schema.Types.Mixed },

    readAt: { type: Date },
  },
  { timestamps: true }
);

notificationSchema.index({ user: 1, createdAt: -1 });
notificationSchema.index({ user: 1, readAt: 1 });

export default mongoose.model('Notification', notificationSchema);
