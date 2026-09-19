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

const STATUS_LABELS = {
  open: 'مفتوح',
  reviewing: 'قيد المعالجة',
  resolved: 'معالَج',
  dismissed: 'مرفوض',
};

const TARGET_LABELS = { offer: 'عرض عمل', user: 'مستخدم', company: 'مؤسسة' };

export default function Reports() {
  const [status, setStatus] = useState('open');
  const [page, setPage] = useState(1);

  const [data, setData] = useState({ items: [], pagination: { pages: 1 } });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [handling, setHandling] = useState(null);
  const [decision, setDecision] = useState('resolved');
  const [action, setAction] = useState('none');
  const [resolution, setResolution] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    setError('');
    api
      .get('/admin/reports', { status, page })
      .then(setData)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [status, page]);

  useEffect(load, [load]);

  async function submit() {
    setBusy(true);
    try {
      await api.patch(`/admin/reports/${handling._id}`, {
        status: decision,
        resolution: resolution.trim(),
        action: action === 'none' ? undefined : action,
      });
      setHandling(null);
      setResolution('');
      setAction('none');
      load();
    } catch (e) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-2">
        {['open', 'reviewing', 'resolved', 'dismissed', 'all'].map((s) => (
          <button
            key={s}
            onClick={() => {
              setStatus(s);
              setPage(1);
            }}
            className={`rounded-lg px-4 py-2 text-sm font-bold transition ${
              status === s
                ? 'bg-primary text-white'
                : 'bg-white text-slate-600 hover:bg-slate-100'
            }`}
          >
            {s === 'all' ? 'الكل' : STATUS_LABELS[s]}
          </button>
        ))}
      </div>

      {loading ? (
        <Spinner />
      ) : error ? (
        <ErrorBox message={error} onRetry={load} />
      ) : data.items.length === 0 ? (
        <EmptyState
          title="لا توجد بلاغات"
          subtitle={status === 'open' ? 'لا توجد بلاغات تنتظر المعالجة' : undefined}
        />
      ) : (
        <div className="space-y-3">
          {data.items.map((r) => (
            <div key={r._id} className="card p-5">
              <div className="mb-3 flex flex-wrap items-start justify-between gap-3">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="badge bg-slate-100 text-slate-700">
                      {TARGET_LABELS[r.targetType]}
                    </span>
                    <Badge status={r.status}>{STATUS_LABELS[r.status]}</Badge>
                  </div>
                  <div className="mt-2 font-bold text-slate-800">
                    {LABELS.reportReasons[r.reason] || r.reason}
                  </div>
                </div>
                <div className="text-xs text-slate-500">{formatDate(r.createdAt)}</div>
              </div>

              {r.details && (
                <p className="mb-3 rounded-lg bg-slate-50 p-3 text-sm leading-6 text-slate-700">
                  {r.details}
                </p>
              )}

              <div className="mb-3 grid gap-2 text-sm sm:grid-cols-2">
                <div>
                  <span className="font-bold text-slate-500">المُبلِّغ: </span>
                  {r.reporter?.fullName || '-'}{' '}
                  <span className="text-xs text-slate-400" dir="ltr">
                    {r.reporter?.phone || ''}
                  </span>
                </div>
                <div>
                  <span className="font-bold text-slate-500">الهدف: </span>
                  {r.target?.title || r.target?.fullName || r.target?.name || 'محذوف'}
                </div>
              </div>

              {r.resolution && (
                <div className="mb-3 rounded-lg bg-emerald-50 p-3 text-sm text-emerald-800">
                  <span className="font-bold">المعالجة: </span>
                  {r.resolution}
                </div>
              )}

              {(r.status === 'open' || r.status === 'reviewing') && (
                <button
                  onClick={() => {
                    setHandling(r);
                    setDecision('resolved');
                  }}
                  className="btn-primary px-4 py-2 text-sm"
                >
                  معالجة البلاغ
                </button>
              )}
            </div>
          ))}

          <Pagination
            page={data.pagination?.page || 1}
            pages={data.pagination?.pages || 1}
            onChange={setPage}
          />
        </div>
      )}

      {handling && (
        <Modal
          title="معالجة البلاغ"
          onClose={() => setHandling(null)}
          footer={
            <>
              <button onClick={() => setHandling(null)} className="btn-outline">
                إلغاء
              </button>
              <button onClick={submit} className="btn-primary" disabled={busy}>
                تأكيد
              </button>
            </>
          }
        >
          <div className="space-y-4">
            <div>
              <label className="mb-1.5 block text-sm font-semibold">القرار</label>
              <select
                className="input"
                value={decision}
                onChange={(e) => setDecision(e.target.value)}
              >
                <option value="reviewing">قيد المعالجة</option>
                <option value="resolved">معالَج — البلاغ صحيح</option>
                <option value="dismissed">مرفوض — البلاغ غير صحيح</option>
              </select>
            </div>

            {decision === 'resolved' && (
              <div>
                <label className="mb-1.5 block text-sm font-semibold">
                  إجراء على الهدف
                </label>
                <select
                  className="input"
                  value={action}
                  onChange={(e) => setAction(e.target.value)}
                >
                  <option value="none">بدون إجراء</option>
                  {handling.targetType === 'offer' && (
                    <option value="remove_offer">إزالة العرض</option>
                  )}
                  {handling.targetType === 'user' && (
                    <option value="suspend_user">تعليق حساب المستخدم</option>
                  )}
                </select>
              </div>
            )}

            <div>
              <label className="mb-1.5 block text-sm font-semibold">
                ملاحظة المعالجة
              </label>
              <textarea
                className="input min-h-[90px]"
                value={resolution}
                onChange={(e) => setResolution(e.target.value)}
                placeholder="وصف مختصر لما تمّ اتّخاذه"
              />
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}
