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

export default function Users() {
  const [q, setQ] = useState('');
  const [role, setRole] = useState('');
  const [status, setStatus] = useState('');
  const [page, setPage] = useState(1);

  const [data, setData] = useState({ items: [], pagination: { pages: 1 } });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [suspending, setSuspending] = useState(null);
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    setError('');
    api
      .get('/admin/users', { q, role, status, page })
      .then(setData)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [q, role, status, page]);

  useEffect(() => {
    const t = setTimeout(load, 350);
    return () => clearTimeout(t);
  }, [load]);

  async function setUserStatus(user, next, why) {
    setBusy(true);
    try {
      await api.patch(`/admin/users/${user._id}/status`, {
        status: next,
        reason: why,
      });
      setSuspending(null);
      setReason('');
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
          placeholder="ابحث بالاسم أو الهاتف أو البريد..."
          value={q}
          onChange={(e) => {
            setQ(e.target.value);
            setPage(1);
          }}
        />
        <select
          className="input max-w-[160px]"
          value={role}
          onChange={(e) => {
            setRole(e.target.value);
            setPage(1);
          }}
        >
          <option value="">كل الأدوار</option>
          <option value="seeker">باحث عن عمل</option>
          <option value="company">مؤسسة</option>
          <option value="admin">مشرف</option>
        </select>
        <select
          className="input max-w-[160px]"
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(1);
          }}
        >
          <option value="">كل الحالات</option>
          <option value="active">نشط</option>
          <option value="suspended">معلّق</option>
        </select>
      </div>

      {loading ? (
        <Spinner />
      ) : error ? (
        <ErrorBox message={error} onRetry={load} />
      ) : data.items.length === 0 ? (
        <EmptyState title="لا يوجد مستخدمون" />
      ) : (
        <div className="card overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="border-b border-slate-200 bg-slate-50">
                <tr>
                  <th className="th">الاسم</th>
                  <th className="th">الهاتف</th>
                  <th className="th">الدور</th>
                  <th className="th">الولاية</th>
                  <th className="th">الحالة</th>
                  <th className="th">التسجيل</th>
                  <th className="th">إجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {data.items.map((u) => (
                  <tr key={u._id} className="row-hover">
                    <td className="td">
                      <div className="font-bold text-slate-800">{u.fullName}</div>
                      <div className="text-xs text-slate-500">{u.email || ''}</div>
                    </td>
                    <td className="td" dir="ltr">
                      {u.phone}
                      {!u.phoneVerified && (
                        <span className="badge mr-1 bg-amber-100 text-amber-700">
                          غير مؤكّد
                        </span>
                      )}
                    </td>
                    <td className="td">{LABELS.roles[u.role]}</td>
                    <td className="td">{u.wilaya || '-'}</td>
                    <td className="td">
                      <Badge status={u.status}>
                        {u.status === 'active'
                          ? 'نشط'
                          : u.status === 'suspended'
                            ? 'معلّق'
                            : 'محذوف'}
                      </Badge>
                    </td>
                    <td className="td text-xs">{formatDate(u.createdAt)}</td>
                    <td className="td">
                      {u.role !== 'admin' && u.status !== 'deleted' && (
                        u.status === 'active' ? (
                          <button
                            onClick={() => setSuspending(u)}
                            className="btn-danger px-3 py-1.5 text-xs"
                          >
                            تعليق
                          </button>
                        ) : (
                          <button
                            onClick={() => setUserStatus(u, 'active')}
                            disabled={busy}
                            className="btn-success px-3 py-1.5 text-xs"
                          >
                            إعادة تفعيل
                          </button>
                        )
                      )}
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

      {suspending && (
        <Modal
          title="تعليق الحساب"
          onClose={() => {
            setSuspending(null);
            setReason('');
          }}
          footer={
            <>
              <button
                onClick={() => {
                  setSuspending(null);
                  setReason('');
                }}
                className="btn-outline"
              >
                إلغاء
              </button>
              <button
                onClick={() => setUserStatus(suspending, 'suspended', reason.trim())}
                className="btn-danger"
                disabled={busy}
              >
                تأكيد التعليق
              </button>
            </>
          }
        >
          <p className="mb-3 text-sm text-slate-600">
            سيُمنع <strong>{suspending.fullName}</strong> من الدخول، وتُخفى عروضه من
            النتائج.
          </p>
          <textarea
            className="input min-h-[90px]"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="سبب التعليق (يظهر للمستخدم عند محاولة الدخول)"
          />
        </Modal>
      )}
    </div>
  );
}
