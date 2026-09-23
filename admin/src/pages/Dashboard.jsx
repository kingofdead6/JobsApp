import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../lib/api';
import { ErrorBox, Icon, LABELS, Spinner } from '../components/ui.jsx';

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    setError('');
    api
      .get('/admin/stats')
      .then(setStats)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }

  useEffect(load, []);

  if (loading) return <Spinner />;
  if (error) return <ErrorBox message={error} onRetry={load} />;

  const offers = stats.offers || {};
  const users = stats.users || {};
  const queue = stats.queue || {};
  const pendingTotal =
    (offers.pending || 0) + (queue.pendingReports || 0) + (queue.pendingVerifications || 0);

  return (
    <div className="space-y-5">
      {/* شريط الحالة العلوي — طابع غرفة التحكّم */}
      <div className="animate-fade-up overflow-hidden rounded-2xl bg-sidebar p-6 text-white shadow-lifted">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-xs font-bold text-slate-400">
              <span
                className={`h-2 w-2 rounded-full ${
                  pendingTotal > 0 ? 'animate-pulse-dot bg-amber-400' : 'bg-emerald-400'
                }`}
              />
              حالة المنصّة
            </div>
            <h2 className="mt-2 text-2xl font-extrabold">
              {pendingTotal > 0
                ? `${pendingTotal} مهمّة تنتظر معالجتك`
                : 'كل شيء تحت السيطرة'}
            </h2>
            <p className="mt-1 text-sm text-slate-400">
              {pendingTotal > 0
                ? 'راجع العروض والبلاغات وطلبات التوثيق المعلّقة.'
                : 'لا توجد مهام معلّقة في الوقت الحالي.'}
            </p>
          </div>

          <div className="flex gap-6">
            <MiniStat
              label="مستخدم"
              value={(users.seeker || 0) + (users.company || 0)}
            />
            <MiniStat label="عرض منشور" value={offers.approved || 0} />
            <MiniStat label="ترشّح" value={stats.applicationsTotal || 0} />
          </div>
        </div>
      </div>

      {/* قوائم الانتظار */}
      <div className="grid gap-4 sm:grid-cols-3">
        <QueueCard
          to="/offers"
          icon="clipboard"
          label="عروض قيد المراجعة"
          value={offers.pending || 0}
          tone="amber"
        />
        <QueueCard
          to="/reports"
          icon="flag"
          label="بلاغات مفتوحة"
          value={queue.pendingReports || 0}
          tone="rose"
        />
        <QueueCard
          to="/companies"
          icon="building"
          label="طلبات توثيق"
          value={queue.pendingVerifications || 0}
          tone="indigo"
        />
      </div>

      {/* البطاقات التفصيلية */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="الباحثون عن عمل"
          value={users.seeker || 0}
          icon="users"
          tone="bg-blue-50 text-blue-600"
        />
        <StatCard
          label="المؤسسات"
          value={users.company || 0}
          icon="building"
          tone="bg-violet-50 text-violet-600"
        />
        <StatCard
          label="العروض المنشورة"
          value={offers.approved || 0}
          icon="clipboard"
          tone="bg-emerald-50 text-emerald-600"
        />
        <StatCard
          label="تسجيلات هذا الأسبوع"
          value={stats.recentSignups || 0}
          icon="trend"
          tone="bg-amber-50 text-amber-600"
        />
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <TopList
          title="أكثر الولايات نشاطًا"
          icon="trend"
          items={stats.topWilayas || []}
          nameKey="wilaya"
        />
        <TopList
          title="أكثر القطاعات نشاطًا"
          icon="building"
          items={(stats.topSectors || []).map((s) => ({
            sector: LABELS.sectors[s.sector] || s.sector,
            count: s.count,
          }))}
          nameKey="sector"
        />
      </div>

      <div className="card p-5">
        <h3 className="mb-4 flex items-center gap-2 font-extrabold text-slate-800">
          <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-admin-soft text-admin">
            <Icon name="clipboard" className="h-4 w-4" />
          </span>
          حالة العروض
        </h3>
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-5">
          {Object.entries(LABELS.offerStatus).map(([key, label]) => (
            <div
              key={key}
              className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3"
            >
              <div className="text-2xl font-extrabold text-slate-800">
                {offers[key] || 0}
              </div>
              <div className="mt-0.5 text-xs text-slate-500">{label}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

function MiniStat({ label, value }) {
  return (
    <div className="text-center">
      <div className="text-2xl font-extrabold text-white">{value}</div>
      <div className="text-[11px] text-slate-400">{label}</div>
    </div>
  );
}

function StatCard({ label, value, icon, tone }) {
  return (
    <div className="card animate-fade-up flex items-center gap-4 p-5">
      <div className={`flex h-12 w-12 items-center justify-center rounded-xl ${tone}`}>
        <Icon name={icon} className="h-6 w-6" />
      </div>
      <div>
        <div className="text-2xl font-extrabold text-slate-800">{value}</div>
        <div className="text-xs text-slate-500">{label}</div>
      </div>
    </div>
  );
}

function QueueCard({ to, icon, label, value, tone }) {
  const tones = {
    amber: 'border-amber-200 bg-amber-50 text-amber-800 hover:border-amber-300',
    rose: 'border-rose-200 bg-rose-50 text-rose-800 hover:border-rose-300',
    indigo: 'border-indigo-200 bg-indigo-50 text-indigo-800 hover:border-indigo-300',
  };

  return (
    <Link
      to={to}
      className={`group animate-fade-up rounded-xl border p-5 transition-all hover:shadow-card ${tones[tone]}`}
    >
      <div className="flex items-start justify-between">
        <div>
          <div className="text-3xl font-extrabold">{value}</div>
          <div className="mt-1 text-sm font-bold">{label}</div>
        </div>
        <Icon name={icon} className="h-6 w-6 opacity-40" />
      </div>
      <div className="mt-3 flex items-center gap-1 text-xs opacity-70">
        اضغط للمعالجة
        <span className="transition-transform group-hover:-translate-x-1">←</span>
      </div>
    </Link>
  );
}

function TopList({ title, icon, items, nameKey }) {
  const max = Math.max(...items.map((i) => i.count), 1);

  return (
    <div className="card p-5">
      <h3 className="mb-4 flex items-center gap-2 font-extrabold text-slate-800">
        <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-admin-soft text-admin">
          <Icon name={icon} className="h-4 w-4" />
        </span>
        {title}
      </h3>
      {items.length === 0 ? (
        <p className="py-4 text-center text-sm text-slate-500">لا توجد بيانات بعد</p>
      ) : (
        <div className="space-y-3.5">
          {items.map((item, i) => (
            <div key={i}>
              <div className="mb-1.5 flex justify-between text-sm">
                <span className="font-semibold text-slate-700">{item[nameKey]}</span>
                <span className="font-bold text-slate-500">{item.count}</span>
              </div>
              <div className="h-2 overflow-hidden rounded-full bg-slate-100">
                <div
                  className="h-full rounded-full bg-gradient-to-l from-admin-light to-admin transition-all duration-700"
                  style={{ width: `${(item.count / max) * 100}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
