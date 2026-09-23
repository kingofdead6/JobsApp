import { useCallback, useEffect, useState } from 'react';
import { api } from '../lib/api';
import {
  Badge,
  EmptyState,
  ErrorBox,
  LABELS,
  Modal,
  Pagination,
  Spinner,
  formatDate,
} from '../components/ui.jsx';

const VERIFICATION_LABELS = {
  unverified: 'غير موثّقة',
  pending: 'قيد المراجعة',
  verified: 'موثّقة',
  rejected: 'مرفوضة',
};

export default function Companies() {
  const [verificationStatus, setVerificationStatus] = useState('pending');
  const [q, setQ] = useState('');
  const [page, setPage] = useState(1);

  const [data, setData] = useState({ items: [], pagination: { pages: 1 } });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [rejecting, setRejecting] = useState(null);
  const [note, setNote] = useState('');
  const [subscribing, setSubscribing] = useState(null);
  const [plan, setPlan] = useState('monthly');
  const [months, setMonths] = useState(1);
  const [cvAccess, setCvAccess] = useState(true);
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    setError('');
    api
      .get('/admin/companies', { verificationStatus, q, page })
      .then(setData)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [verificationStatus, q, page]);

  useEffect(() => {
    const t = setTimeout(load, 350);
    return () => clearTimeout(t);
  }, [load]);

  async function verify(company, decision, reason) {
    setBusy(true);
    try {
      await api.patch(`/admin/companies/${company._id}/verify`, {
        decision,
        note: reason,
      });
      setRejecting(null);
      setNote('');
      load();
    } catch (e) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function saveSubscription() {
    setBusy(true);
    try {
      await api.patch(`/admin/companies/${subscribing._id}/subscription`, {
        plan,
        months: Number(months),
        cvDatabaseAccess: cvAccess,
      });
      setSubscribing(null);
      load();
    } catch (e) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="card flex flex-wrap gap-3 p-4">
        <input
          className="input max-w-xs"
          placeholder="ابحث باسم المؤسسة..."
          value={q}
          onChange={(e) => {
            setQ(e.target.value);
            setPage(1);
          }}
        />
        <select
          className="input max-w-[180px]"
          value={verificationStatus}
          onChange={(e) => {
            setVerificationStatus(e.target.value);
            setPage(1);
          }}
        >
          <option value="">كل الحالات</option>
          <option value="pending">طلبات التوثيق</option>
          <option value="verified">موثّقة</option>
          <option value="unverified">غير موثّقة</option>
          <option value="rejected">مرفوضة</option>
        </select>
      </div>

      {loading ? (
        <Spinner />
      ) : error ? (
        <ErrorBox message={error} onRetry={load} />
      ) : data.items.length === 0 ? (
        <EmptyState title="لا توجد مؤسسات" />
      ) : (
        <div className="card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="border-b border-slate-200 bg-slate-50">
                <tr>
                  <th className="th">المؤسسة</th>
                  <th className="th">القطاع</th>
                  <th className="th">الولاية</th>
                  <th className="th">السجل التجاري</th>
                  <th className="th">التوثيق</th>
                  <th className="th">الاشتراك</th>
                  <th className="th">إجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {data.items.map((c) => (
                  <tr key={c._id} className="row-hover">
                    <td className="td">
                      <div className="font-bold text-slate-800">{c.name}</div>
                      <div className="text-xs text-slate-500">
                        {c.owner?.phone || ''}
                      </div>
                    </td>
                    <td className="td">{LABELS.sectors[c.sector] || c.sector}</td>
                    <td className="td">{c.wilaya}</td>
                    <td className="td text-xs" dir="ltr">
                      {c.commercialRegister || '-'}
                    </td>
                    <td className="td">
                      <Badge status={c.verificationStatus}>
                        {VERIFICATION_LABELS[c.verificationStatus]}
                      </Badge>
                    </td>
                    <td className="td text-xs">
                      {c.subscription?.plan === 'free' || !c.subscription?.plan ? (
                        <span className="text-slate-400">مجاني</span>
                      ) : (
                        <>
                          <div className="font-bold text-emerald-600">
                            {c.subscription.plan === 'monthly' ? 'شهري' : 'سنوي'}
                          </div>
                          <div className="text-slate-500">
                            حتى {formatDate(c.subscription.expiresAt)}
                          </div>
                        </>
                      )}
                    </td>
                    <td className="td">
                      <div className="flex flex-wrap gap-1.5">
                        {c.verificationStatus === 'pending' && (
                          <>
                            <button
                              onClick={() => verify(c, 'approve')}
                              disabled={busy}
                              className="btn-success px-3 py-1.5 text-xs"
                            >
                              توثيق
                            </button>
                            <button
                              onClick={() => setRejecting(c)}
                              disabled={busy}
                              className="btn-danger px-3 py-1.5 text-xs"
                            >
                              رفض
                            </button>
                          </>
                        )}
                        <button
                          onClick={() => {
                            setSubscribing(c);
                            setPlan(c.subscription?.plan === 'free' ? 'monthly' : c.subscription?.plan || 'monthly');
                            setCvAccess(Boolean(c.subscription?.cvDatabaseAccess));
                          }}
                          className="btn-outline px-3 py-1.5 text-xs"
                        >
                          الاشتراك
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <Pagination
            page={data.pagination?.page || 1}
            pages={data.pagination?.pages || 1}
            onChange={setPage}
          />
        </div>
      )}

      {rejecting && (
        <Modal
          title="رفض طلب التوثيق"
          onClose={() => {
            setRejecting(null);
            setNote('');
          }}
          footer={
            <>
              <button
                onClick={() => {
                  setRejecting(null);
                  setNote('');
                }}
                className="btn-outline"
              >
                إلغاء
              </button>
              <button
                onClick={() => verify(rejecting, 'reject', note.trim())}
                className="btn-danger"
                disabled={busy}
              >
                تأكيد الرفض
              </button>
            </>
          }
        >
          <textarea
            className="input min-h-[90px]"
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="سبب رفض التوثيق (يصل إلى المؤسسة)"
          />
        </Modal>
      )}

      {subscribing && (
        <Modal
          title={`اشتراك: ${subscribing.name}`}
          onClose={() => setSubscribing(null)}
          footer={
            <>
              <button onClick={() => setSubscribing(null)} className="btn-outline">
                إلغاء
              </button>
              <button onClick={saveSubscription} className="btn-primary" disabled={busy}>
                حفظ
              </button>
            </>
          }
        >
          <div className="space-y-4">
            <div>
              <label className="mb-1.5 block text-sm font-semibold">الخطة</label>
              <select
                className="input"
                value={plan}
                onChange={(e) => setPlan(e.target.value)}
              >
                <option value="free">مجاني</option>
                <option value="monthly">شهري</option>
                <option value="yearly">سنوي</option>
              </select>
            </div>

            {plan !== 'free' && (
              <>
                <div>
                  <label className="mb-1.5 block text-sm font-semibold">
                    المدّة (بالأشهر)
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="24"
                    className="input"
                    value={months}
                    onChange={(e) => setMonths(e.target.value)}
                  />
                </div>

                <label className="flex items-center gap-2 text-sm">
                  <input
                    type="checkbox"
                    checked={cvAccess}
                    onChange={(e) => setCvAccess(e.target.checked)}
                    className="h-4 w-4 rounded"
                  />
                  الوصول إلى قاعدة السير الذاتية
                </label>
              </>
            )}
          </div>
        </Modal>
      )}
    </div>
  );
}
