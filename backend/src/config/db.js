import mongoose from 'mongoose';

export async function connectDB() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGODB_URI غير محدّد في ملف .env');

  mongoose.set('strictQuery', true);
  await mongoose.connect(uri, { serverSelectionTimeoutMS: 8000 });
  console.log(`[db] متصل بقاعدة البيانات: ${mongoose.connection.name}`);

  mongoose.connection.on('error', (err) => console.error('[db] خطأ:', err.message));
  mongoose.connection.on('disconnected', () => console.warn('[db] انقطع الاتصال'));
}
