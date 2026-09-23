// مكوّنات واجهة لوحة الإدارة + التسميات العربية

/* ─────────────────────────────────────────────
   الأيقونات: SVG مضمّنة (لا تبعية خارجية)
   ───────────────────────────────────────────── */

const PATHS = {
  dashboard: 'M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z',
  clipboard:
    'M9 2a1 1 0 00-1 1v1H6a2 2 0 00-2 2v14a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-2V3a1 1 0 00-1-1H9zm0 3h6v1H9V5z',
  building:
    'M4 21V5a2 2 0 012-2h6a2 2 0 012 2v16H4zm12 0V9h4v12h-4zM7 7h2v2H7V7zm0 4h2v2H7v-2zm0 4h2v2H7v-2z',
  users:
    'M16 11a4 4 0 100-8 4 4 0 000 8zm-8 0a4 4 0 100-8 4 4 0 000 8zm0 2c-3 0-6 1.5-6 4v3h9v-3c0-1 .4-2 1-2.8-1.2-.8-2.7-1.2-4-1.2zm8 0c-.6 0-1.3.1-2 .2 1 1 1.5 2.2 1.5 3.6V20H22v-3c0-2.5-3-4-6-4z',
  flag: 'M5 3a1 1 0 011 1v1.2l3.6-.9a5 5 0 013.3.3l1.2.5a5 5 0 003.3.3l1.4-.4A1 1 0 0120 6v8a1 1 0 01-.8 1l-1.5.3a5 5 0 01-3.3-.3l-1.2-.5a5 5 0 00-3.3-.3L6 15v5a1 1 0 11-2 0V4a1 1 0 011-1z',
  megaphone:
    'M18 3a1 1 0 011 1v16a1 1 0 01-1.6.8L11 16H8a5 5 0 010-8h3l6.4-4.8A1 1 0 0118 3zM5 12a3 3 0 003 3v-6a3 3 0 00-3 3z',
  shield:
    'M12 2l8 3v6c0 5-3.4 9.4-8 11-4.6-1.6-8-6-8-11V5l8-3zm-1 12.8l5-5-1.4-1.4L11 12l-1.6-1.6L8 11.8l3 3z',
  logout:
    'M10 3H5a2 2 0 00-2 2v14a2 2 0 002 2h5v-2H5V5h5V3zm6.6 3.6L15.2 8l3 3H9v2h9.2l-3 3 1.4 1.4L22 12l-5.4-5.4z',
  menu: 'M3 6h18v2H3V6zm0 5h18v2H3v-2zm0 5h18v2H3v-2z',
  check: 'M9 16.2l-3.5-3.5L4 14.2l5 5 11-11-1.5-1.4L9 16.2z',
  x: 'M18.3 5.7L12 12l6.3 6.3-1.4 1.4L10.6 13.4 4.3 19.7 2.9 18.3 9.2 12 2.9 5.7l1.4-1.4L10.6 10.6l6.3-6.3 1.4 1.4z',
  eye: 'M12 5c-5 0-9 4.5-10 7 1 2.5 5 7 10 7s9-4.5 10-7c-1-2.5-5-7-10-7zm0 11a4 4 0 110-8 4 4 0 010 8zm0-2a2 2 0 100-4 2 2 0 000 4z',
  star: 'M12 2l3 6.6 7 .8-5.2 4.8 1.4 7L12 17.8 5.8 21.2l1.4-7L2 9.4l7-.8L12 2z',
  search: 'M10 2a8 8 0 105 14.3l5.4 5.4 1.4-1.4-5.4-5.4A8 8 0 0010 2zm0 2a6 6 0 110 12 6 6 0 010-12z',
  refresh:
    'M12 4V1L8 5l4 4V6a6 6 0 11-6 6H4a8 8 0 108-8zm0 0',
  warning:
    'M12 2L1 21h22L12 2zm1 14h-2v2h2v-2zm0-7h-2v5h2V9z',
  inbox:
    'M4 3h16a1 1 0 011 1v16a1 1 0 01-1 1H4a1 1 0 01-1-1V4a1 1 0 011-1zm1 11v5h14v-5h-4a3 3 0 01-6 0H5zm0-9v7h5a1 1 0 011 1 1 1 0 002 0 1 1 0 011-1h5V5H5z',
  trend:
    'M3 17l6-6 4 4 7-7v5h2V4h-8v2h5l-6 6-4-4-7 7 1.4 1.4z',
  clock: 'M12 2a10 10 0 100 20 10 10 0 000-20zm1 10V6h-2v8h6v-2h-4z',
  plus: 'M11 5h2v6h6v2h-6v6h-2v-6H5v-2h6V5z',
  trash:
    'M9 3h6l1 1h4v2H4V4h4l1-1zM6 7h12l-1 13a1 1 0 01-1 1H8a1 1 0 01-1-1L6 7z',
  pencil:
    'M3 17.2V21h3.8L18 9.8 14.2 6 3 17.2zM20.7 7.3a1 1 0 000-1.4l-2.6-2.6a1 1 0 00-1.4 0L15 5l3.8 3.8 1.9-1.5z',
};

export function Icon({ name, className = 'h-5 w-5' }) {
  const d = PATHS[name] || PATHS.dashboard;
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
      aria-hidden="true"
    >
      <path d={d} />
    </svg>
  );
}

/* ─────────────────────────────────────────────
   التسميات
   ───────────────────────────────────────────── */

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
  rejected: 'bg-rose-100 text-rose-700',
  suspended: 'bg-rose-100 text-rose-700',
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
      <div className="h-9 w-9 animate-spin rounded-full border-[3px] border-slate-200 border-t-admin" />
    </div>
  );
}

export function EmptyState({ title, subtitle, icon = 'inbox' }) {
  return (
    <div className="animate-fade-up py-16 text-center">
      <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-admin-soft text-admin">
        <Icon name={icon} className="h-8 w-8" />
      </div>
      <div className="font-extrabold text-slate-700">{title}</div>
      {subtitle && <div className="mt-1 text-sm text-slate-500">{subtitle}</div>}
    </div>
  );
}

export function ErrorBox({ message, onRetry }) {
  return (
    <div className="rounded-xl border border-rose-200 bg-rose-50 p-6 text-center">
      <div className="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-xl bg-rose-100 text-rose-600">
        <Icon name="warning" className="h-6 w-6" />
      </div>
      <div className="font-bold text-rose-700">{message}</div>
      {onRetry && (
        <button onClick={onRetry} className="btn-outline mt-4">
          <Icon name="refresh" className="h-4 w-4" />
          إعادة المحاولة
        </button>
      )}
    </div>
  );
}

/** نافذة منبثقة */
export function Modal({ title, children, onClose, footer, wide = false }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 p-4 backdrop-blur-sm">
      <div
        className={`w-full ${wide ? 'max-w-3xl' : 'max-w-lg'} animate-fade-up
                    overflow-hidden rounded-2xl bg-white shadow-lifted`}
      >
        <div className="flex items-center justify-between border-b border-slate-200 px-5 py-4">
          <h3 className="font-extrabold text-slate-800">{title}</h3>
          <button
            onClick={onClose}
            className="rounded-lg p-1.5 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600"
            aria-label="إغلاق"
          >
            <Icon name="x" className="h-4 w-4" />
          </button>
        </div>
        <div className="max-h-[60vh] overflow-y-auto px-5 py-4">{children}</div>
        {footer && (
          <div className="flex justify-end gap-2 border-t border-slate-200 bg-slate-50 px-5 py-4">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}

export function Pagination({ page, pages, onChange }) {
  if (pages <= 1) return null;

  return (
    <div className="flex items-center justify-center gap-2 border-t border-slate-200 py-4">
      <button
        className="btn-outline px-3 py-1.5"
        disabled={page <= 1}
        onClick={() => onChange(page - 1)}
      >
        السابق
      </button>
      <span className="px-2 text-sm text-slate-600">
        صفحة <span className="font-bold text-slate-800">{page}</span> من {pages}
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

/** تبويبات أفقية موحّدة */
export function Tabs({ items, value, onChange }) {
  return (
    <div className="flex flex-wrap gap-1.5 rounded-xl bg-white p-1.5 shadow-card">
      {items.map((t) => (
        <button
          key={String(t.key)}
          onClick={() => onChange(t.key)}
          className={`flex items-center gap-2 rounded-lg px-4 py-2 text-sm font-bold transition ${
            value === t.key
              ? 'bg-admin text-white shadow-sm'
              : 'text-slate-600 hover:bg-slate-100'
          }`}
        >
          {t.label}
          {t.count > 0 && (
            <span
              className={`rounded-full px-1.5 text-[10px] font-extrabold ${
                value === t.key ? 'bg-white/25' : 'bg-rose-100 text-rose-600'
              }`}
            >
              {t.count}
            </span>
          )}
        </button>
      ))}
    </div>
  );
}

export function formatDate(value) {
  if (!value) return '-';
  const d = new Date(value);
  return `${d.getDate()}/${d.getMonth() + 1}/${d.getFullYear()}`;
}

export function formatDateTime(value) {
  if (!value) return '-';
  const d = new Date(value);
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  return `${formatDate(value)} · ${hh}:${mm}`;
}
