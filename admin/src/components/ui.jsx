// مكوّنات واجهة مشتركة + التسميات العربية

export const LABELS = {
  contractTypes: {
    full_time: 'دوام كامل',
    part_time: 'دوام جزئي',
    cdd: 'مؤقت',
    internship: 'تربّص',
    seasonal: 'موسمي',
    remote: 'عن بُعد',
  },
  sectors: {
    construction: 'البناء والأشغال العمومية',
    transport: 'النقل واللوجستيك',
    hospitality: 'المطاعم والفندقة',
    industry: 'الصناعة',
    commerce: 'التجارة',
    it: 'الإعلام الآلي',
    health: 'الصحة',
    education: 'التعليم',
    agriculture: 'الفلاحة',
    services: 'الخدمات',
    crafts: 'الحرف',
  },
  offerStatus: {
    pending: 'قيد المراجعة',
    approved: 'منشور',
    rejected: 'مرفوض',
    paused: 'موقوف',
    expired: 'منتهٍ',
  },
  reportReasons: {
    fake: 'عرض وهمي',
    scam: 'محاولة احتيال',
    money_request: 'طلب مال',
    offensive: 'محتوى مسيء',
    duplicate: 'عرض مكرر',
    other: 'سبب آخر',
  },
  roles: { seeker: 'باحث عن عمل', company: 'مؤسسة', admin: 'مشرف' },
};

const STATUS_STYLES = {
  approved: 'bg-emerald-100 text-emerald-700',
  verified: 'bg-emerald-100 text-emerald-700',
  active: 'bg-emerald-100 text-emerald-700',
  resolved: 'bg-emerald-100 text-emerald-700',
  pending: 'bg-amber-100 text-amber-700',
  reviewing: 'bg-amber-100 text-amber-700',
  open: 'bg-amber-100 text-amber-700',
  rejected: 'bg-red-100 text-red-700',
  suspended: 'bg-red-100 text-red-700',
  paused: 'bg-slate-200 text-slate-600',
  expired: 'bg-slate-200 text-slate-600',
  dismissed: 'bg-slate-200 text-slate-600',
  unverified: 'bg-slate-200 text-slate-600',
};

export function Badge({ status, children }) {
  return (
    <span className={`badge ${STATUS_STYLES[status] || 'bg-slate-100 text-slate-600'}`}>
      {children}
    </span>
  );
}

export function Spinner() {
  return (
    <div className="flex justify-center py-16">
      <div className="h-9 w-9 animate-spin rounded-full border-4 border-slate-200 border-t-primary" />
    </div>
  );
}

export function EmptyState({ title, subtitle }) {
  return (
    <div className="py-16 text-center">
      <div className="mb-2 text-4xl">📭</div>
      <div className="font-bold text-slate-700">{title}</div>
      {subtitle && <div className="mt-1 text-sm text-slate-500">{subtitle}</div>}
    </div>
  );
}

export function ErrorBox({ message, onRetry }) {
  return (
    <div className="rounded-xl border border-red-200 bg-red-50 p-5 text-center">
      <div className="font-bold text-red-700">{message}</div>
      {onRetry && (
        <button onClick={onRetry} className="btn-outline mt-3">
          إعادة المحاولة
        </button>
      )}
    </div>
  );
}

/** نافذة منبثقة بسيطة */
export function Modal({ title, children, onClose, footer }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
      <div className="w-full max-w-lg rounded-xl bg-white shadow-xl">
        <div className="flex items-center justify-between border-b border-slate-200 px-5 py-4">
          <h3 className="font-extrabold text-slate-800">{title}</h3>
          <button
            onClick={onClose}
            className="rounded-lg px-2 py-1 text-slate-400 hover:bg-slate-100"
            aria-label="إغلاق"
          >
            ✕
          </button>
        </div>
        <div className="max-h-[60vh] overflow-y-auto px-5 py-4">{children}</div>
        {footer && (
          <div className="flex justify-end gap-2 border-t border-slate-200 px-5 py-4">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}

/** ترقيم الصفحات */
export function Pagination({ page, pages, onChange }) {
  if (pages <= 1) return null;

  return (
    <div className="flex items-center justify-center gap-2 py-4">
      <button
        className="btn-outline px-3 py-1.5"
        disabled={page <= 1}
        onClick={() => onChange(page - 1)}
      >
        السابق
      </button>
      <span className="text-sm text-slate-600">
        صفحة {page} من {pages}
      </span>
      <button
        className="btn-outline px-3 py-1.5"
        disabled={page >= pages}
        onClick={() => onChange(page + 1)}
      >
        التالي
      </button>
    </div>
  );
}

export function formatDate(value) {
  if (!value) return '-';
  const d = new Date(value);
  return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`;
}
