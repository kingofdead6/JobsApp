import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../lib/api';
import { ErrorBox, LABELS, Spinner } from '../components/ui.jsx';

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

  return (
    <div className="space-y-5">
      {/* بطاقات الإحصائيات */}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="الباحثون عن عمل"
          value={users.seeker || 0}
          icon="👤"
          color="bg-blue-50 text-blue-600"
        />
        <StatCard
          label="المؤسسات"
          value={users.company || 0}
          icon="🏢"
          color="bg-purple-50 text-purple-600"
        />
        <StatCard
          label="العروض المنشورة"
          value={offers.approved || 0}
          icon="📋"
          color="bg-emerald-50 text-emerald-600"
        />
        <StatCard
          label="إجمالي الترشّحات"
          value={stats.applicationsTotal || 0}
          icon="📨"
          color="bg-amber-50 text-amber-600"
        />
      </div>

      {/* مهام تنتظر المعالجة */}
      <div className="grid gap-4 sm:grid-cols-3">
        <QueueCard
          to="/offers"
          label="عروض قيد المراجعة"
          value={offers.pending || 0}
          tone="amber"
        />
        <QueueCard
          to="/reports"
          label="بلاغات مفتوحة"
          value={stats.queue?.pendingReports || 0}
          tone="red"
        />
        <QueueCard
          to="/companies"
          label="طلبات توثيق"
          value={stats.queue?.pendingVerifications || 0}
          tone="blue"
        />
      </div>

      <div className="grid gap-5 lg:grid-cols-2">
        <TopList
          title="أكثر الولايات نشاطًا"
          items={stats.topWilayas || []}
          nameKey="wilaya"
        />
        <TopList
          title="أكثر القطاعات نشاطًا"
          items={(stats.topSectors || []).map((s) => ({
            sector: LABELS.sectors[s.sector] || s.sector,
            count: s.count,
          }))}
          nameKey="sector"
        />
      </div>

      <div className="card p-5">
        <h3 className="mb-3 font-extrabold text-slate-800">حالة العروض</h3>
        <div className="flex flex-wrap gap-4">
          {Object.entries(LABELS.offerStatus).map(([key, label]) => (
            <div key={key} className="min-w-[110px] rounded-lg bg-slate-50 px-4 py-3">
              <div className="text-2xl font-extrabold text-slate-800">
                {offers[key] || 0}
              </div>
              <div className="text-xs text-slate-500">{label}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="text-sm text-slate-500">
        تسجيلات جديدة خلال الأسبوع الأخير:{' '}
        <span className="font-bold text-slate-700">{stats.recentSignups || 0}</span>
      </div>
    </div>
  );
}

function StatCard({ label, value, icon, color }) {
  return (
    <div className="card flex items-center gap-4 p-5">
      <div className={`flex h-12 w-12 items-center justify-center rounded-xl text-xl ${color}`}>
        {icon}
      </div>
      <div>
        <div className="text-2xl font-extrabold text-slate-800">{value}</div>
        <div className="text-xs text-slate-500">{label}</div>
      </div>
    </div>
  );
}

function QueueCard({ to, label, value, tone }) {
  const tones = {
    amber: 'border-amber-200 bg-amber-50 text-amber-700',
    red: 'border-red-200 bg-red-50 text-red-700',
    blue: 'border-blue-200 bg-blue-50 text-blue-700',
  };

  return (
    <Link
      to={to}
      className={`rounded-xl border p-5 transition hover:shadow-sm ${tones[tone]}`}
    >
      <div className="text-3xl font-extrabold">{value}</div>
      <div className="mt-1 text-sm font-semibold">{label}</div>
      <div className="mt-2 text-xs opacity-70">اضغط للمعالجة ←</div>
    </Link>
  );
}

function TopList({ title, items, nameKey }) {
  const max = Math.max(...items.map((i) => i.count), 1);

  return (
    <div className="card p-5">
      <h3 className="mb-4 font-extrabold text-slate-800">{title}</h3>
      {items.length === 0 ? (
        <p className="text-sm text-slate-500">لا توجد بيانات بعد</p>
      ) : (
        <div className="space-y-3">
          {items.map((item, i) => (
            <div key={i}>
              <div className="mb-1 flex justify-between text-sm">
                <span className="font-semibold text-slate-700">{item[nameKey]}</span>
                <span className="text-slate-500">{item.count}</span>
              </div>
              <div className="h-2 overflow-hidden rounded-full bg-slate-100">
                <div
                  className="h-full rounded-full bg-primary"
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
