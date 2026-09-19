import JobOffer from '../models/JobOffer.js';
import SavedItem from '../models/SavedItem.js';
import { notify } from './notificationService.js';
import { OFFER_STATUS } from '../config/constants.js';

const HOUR = 60 * 60 * 1000;

// ينقل العروض المنتهية إلى حالة «منتهٍ» حتى لا تظهر في النتائج
async function expireOffers() {
  const result = await JobOffer.updateMany(
    { status: OFFER_STATUS.APPROVED, expiresAt: { $lte: new Date() } },
    { status: OFFER_STATUS.EXPIRED }
  );
  if (result.modifiedCount) {
    console.log(`[scheduler] انتهت صلاحية ${result.modifiedCount} عرض`);
  }

  // رفع صفة «مميّز» عن العروض التي انقضت مدّتها المدفوعة
  await JobOffer.updateMany(
    { featured: true, featuredUntil: { $lte: new Date() } },
    { featured: false, featuredUntil: undefined }
  );
}

/**
 * تنبيه أصحاب عمليات البحث المحفوظة عند ظهور عرض مطابق (3.3).
 * يُرسل تنبيهًا واحدًا لكل بحث في الدورة، ولا يُعيد تنبيه ما سبق.
 */
async function runSavedSearchAlerts() {
  const searches = await SavedItem.find({ kind: 'search', alertEnabled: true }).lean();

  for (const search of searches) {
    const since = search.lastAlertedAt || search.createdAt;
    const c = search.criteria || {};

    const filter = {
      status: OFFER_STATUS.APPROVED,
      expiresAt: { $gt: new Date() },
      publishedAt: { $gt: since },
    };
    if (c.q) filter.$text = { $search: c.q };
    if (c.wilaya) filter.wilaya = c.wilaya;
    if (c.sector) filter.sector = c.sector;
    if (c.contractType) filter.contractType = c.contractType;
    if (c.salaryMin) filter.salaryMax = { $gte: c.salaryMin };

    const count = await JobOffer.countDocuments(filter);
    if (!count) continue;

    await notify({
      user: search.user,
      type: 'matching_offer',
      title: 'عروض جديدة تناسبك',
      body: `${count} عرض جديد مطابق لبحثك «${search.label}»`,
      data: { savedSearchId: search._id, criteria: c },
    });

    await SavedItem.updateOne({ _id: search._id }, { lastAlertedAt: new Date() });
  }
}

async function tick() {
  try {
    await expireOffers();
    await runSavedSearchAlerts();
  } catch (err) {
    console.error('[scheduler] خطأ:', err.message);
  }
}

/**
 * مهام دورية بسيطة داخل العملية نفسها.
 * عند التوسّع تُنقل إلى مجدول خارجي (cron) لتفادي التكرار بين عدّة نسخ من الخادم.
 */
export function startScheduler() {
  setTimeout(tick, 10_000).unref();       // تشغيلة أولى بعد الإقلاع
  setInterval(tick, HOUR).unref();        // ثم كل ساعة
  console.log('[scheduler] المهام الدورية مفعّلة');
}
