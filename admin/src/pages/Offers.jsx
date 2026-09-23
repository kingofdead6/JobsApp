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
  Tabs,
  formatDate,
} from '../components/ui.jsx';

const TABS = [
  { key: 'pending', label: 'قيد المراجعة' },
  { key: 'approved', label: 'منشورة' },
  { key: 'rejected', label: 'مرفوضة' },
  { key: 'all', label: 'الكل' },
];

export default function Offers() {
  const [status, setStatus] = useState('pending');
  const [page, setPage] = useState(1);
  const [data, setData] = useState({ items: [], pagination: { pages: 1 } });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [viewing, setViewing] = useState(null);
  const [rejecting, setRejecting] = useState(null);
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    setError('');
    api
      .get('/admin/offers', { status, page })
      .then(setData)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [status, page]);

  useEffect(load, [load]);

  async function approve(offer) {
    setBusy(true);
    try {
      await api.patch(`/admin/offers/${offer._id}/review`, { decision: 'approve' });
      setViewing(null);
      load();
    } catch (e) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function reject() {
    if (!reason.trim()) {
      alert('سبب الرفض مطلوب');
      return;
    }
    setBusy(true);
    try {
      await api.patch(`/admin/offers/${rejecting._id}/review`, {
        decision: 'reject',
        reason: reason.trim(),
      });
      setRejecting(null);
      setReason('');
      setViewing(null);
      load();
    } catch (e) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function toggleFeatured(offer) {
    setBusy(true);
    try {
      await api.patch(`/admin/offers/${offer._id}/feature`, {
        featured: !offer.featured,
        days: 15,
      });
      load();
    } catch (e) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-4">
      {/* التبويبات */}
      <div>
        <Tabs
          items={TABS.map((t) => ({
            key: t.key,
            label: t.label,
            count: t.key === 'pending' ? data.pagination?.total : 0,
          }))}
          value={status}
          onChange={(k) => {
            setStatus(k);
            setPage(1);
          }}
        />
      </div>

      {loading ? (
        <Spinner />
      ) : error ? (
        <ErrorBox message={error} onRetry={load} />
      ) : data.items.length === 0 ? (
        <EmptyState
          title="لا توجد عروض"
          subtitle={status === 'pending' ? 'لا توجد عروض تنتظر المراجعة' : undefined}
        />
      ) : (
        <div className="card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="border-b border-slate-200 bg-slate-50">
                <tr>
                  <th className="th">الوظيفة</th>
                  <th className="th">المؤسسة</th>
                  <th className="th">الولاية</th>
                  <th className="th">الحالة</th>
                  <th className="th">التاريخ</th>
                  <th className="th">إجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {data.items.map((o) => (
                  <tr key={o._id} className="row-hover">
                    <td className="td">
                      <div className="font-bold text-slate-800">{o.title}</div>
                      <div className="text-xs text-slate-500">
                        {LABELS.sectors[o.sector]} ·{' '}
                        {LABELS.contractTypes[o.contractType]}
                      </div>
                    </td>
                    <td className="td">
                      <div>{o.company?.name || '-'}</div>
                      <div className="text-xs text-slate-500">
                        {o.postedBy?.phone || ''}
                      </div>
                    </td>
                    <td className="td">{o.wilaya}</td>
                    <td className="td">
                      <Badge status={o.status}>{LABELS.offerStatus[o.status]}</Badge>
                      {o.featured && (
                        <span className="badge mr-1 bg-amber-100 text-amber-700">مميّز</span>
                      )}
                    </td>
                    <td className="td text-xs">{formatDate(o.createdAt)}</td>
                    <td className="td">
                      <div className="flex flex-wrap gap-1.5">
                        <button
                          onClick={() => setViewing(o)}
                          className="btn-outline px-3 py-1.5 text-xs"
                        >
                          عرض
                        </button>
                        {o.status === 'pending' && (
                          <>
                            <button
                              onClick={() => approve(o)}
                              disabled={busy}
                              className="btn-success px-3 py-1.5 text-xs"
                            >
                              مصادقة
                            </button>
                            <button
                              onClick={() => setRejecting(o)}
                              disabled={busy}
                              className="btn-danger px-3 py-1.5 text-xs"
                            >
                              رفض
                            </button>
                          </>
                        )}
                        {o.status === 'approved' && (
                          <button
                            onClick={() => toggleFeatured(o)}
                            disabled={busy}
                            className="btn-outline px-3 py-1.5 text-xs"
                          >
                            {o.featured ? 'إلغاء الإبراز' : 'إبراز'}
                          </button>
                        )}
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

      {/* تفاصيل العرض */}
      {viewing && (
        <Modal
          title="تفاصيل العرض"
          onClose={() => setViewing(null)}
          footer={
            viewing.status === 'pending' ? (
              <>
                <button
                  onClick={() => {
                    setRejecting(viewing);
                  }}
                  className="btn-danger"
                  disabled={busy}
                >
                  رفض
                </button>
                <button
                  onClick={() => approve(viewing)}
                  className="btn-success"
                  disabled={busy}
                >
                  مصادقة ونشر
                </button>
              </>
            ) : (
              <button onClick={() => setViewing(null)} className="btn-outline">
                إغلاق
              </button>
            )
          }
        >
          <div className="space-y-3 text-sm">
            <h4 className="text-lg font-extrabold text-slate-800">{viewing.title}</h4>
            <Row label="المؤسسة" value={viewing.company?.name} />
            <Row label="المهنة" value={viewing.profession} />
            <Row label="القطاع" value={LABELS.sectors[viewing.sector]} />
            <Row label="الولاية" value={viewing.wilaya} />
            <Row label="نوع العقد" value={LABELS.contractTypes[viewing.contractType]} />
            <Row
              label="الراتب"
              value={
                viewing.salaryMin || viewing.salaryMax
                  ? `${viewing.salaryMin || ''} - ${viewing.salaryMax || ''} دج`
                  : 'غير محدّد'
              }
            />
            <Row label="عدد المناصب" value={viewing.positions} />
            <Row label="هاتف الناشر" value={viewing.postedBy?.phone} />

            <div>
              <div className="mb-1 font-bold text-slate-600">الوصف</div>
              <p className="whitespace-pre-wrap rounded-lg bg-slate-50 p-3 leading-7 text-slate-700">
                {viewing.description}
              </p>
            </div>

            {viewing.skills?.length > 0 && (
              <div>
                <div className="mb-1.5 font-bold text-slate-600">المهارات المطلوبة</div>
                <div className="flex flex-wrap gap-2">
                  {viewing.skills.map((s, i) => (
                    <span key={i} className="badge bg-slate-100 text-slate-700">
                      {s}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {viewing.rejectionReason && (
              <div className="rounded-lg bg-red-50 p-3 text-red-700">
                <span className="font-bold">سبب الرفض: </span>
                {viewing.rejectionReason}
              </div>
            )}
          </div>
        </Modal>
      )}

      {/* سبب الرفض */}
      {rejecting && (
        <Modal
          title="رفض العرض"
          onClose={() => {
            setRejecting(null);
            setReason('');
          }}
          footer={
            <>
              <button
                onClick={() => {
                  setRejecting(null);
                  setReason('');
                }}
                className="btn-outline"
              >
                إلغاء
              </button>
              <button onClick={reject} className="btn-danger" disabled={busy}>
                تأكيد الرفض
              </button>
            </>
          }
        >
          <p className="mb-3 text-sm text-slate-600">
            سيصل سبب الرفض إلى المؤسسة في إشعار. كن واضحًا حتى تتمكّن من التصحيح.
          </p>
          <textarea
            className="input min-h-[110px]"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="مثال: الوصف غير كافٍ، أو العرض يطلب مبلغًا ماليًا من المترشّح."
          />
        </Modal>
      )}
    </div>
  );
}

function Row({ label, value }) {
  return (
    <div className="flex gap-3">
      <span className="w-28 shrink-0 font-bold text-slate-500">{label}</span>
      <span className="text-slate-800">{value || '-'}</span>
    </div>
  );
}
