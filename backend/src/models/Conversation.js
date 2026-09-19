import mongoose from 'mongoose';

// كيان «المحادثة» — المراسلة الداخلية بعد تقديم الطلب (3.7)
const conversationSchema = new mongoose.Schema(
  {
    participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }],
    offer: { type: mongoose.Schema.Types.ObjectId, ref: 'JobOffer' },
    application: { type: mongoose.Schema.Types.ObjectId, ref: 'Application' },

    lastMessage: { type: String, maxlength: 200 },
    lastMessageAt: { type: Date },
    lastSender: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },

    // عدد الرسائل غير المقروءة لكل طرف: { "<userId>": 3 }
    unread: { type: Map, of: Number, default: {} },
  },
  { timestamps: true }
);

conversationSchema.index({ participants: 1, lastMessageAt: -1 });

export default mongoose.model('Conversation', conversationSchema);
