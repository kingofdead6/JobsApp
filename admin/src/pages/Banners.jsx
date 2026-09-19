import { useCallback, useEffect, useState } from 'react';
import { api } from '../lib/api';
import { EmptyState, ErrorBox, Modal, Spinner } from '../components/ui.jsx';

const EMPTY = { title: '', subtitle: '', ctaLabel: '', active: true, order: 0 };

export default function Banners() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(EMPTY);
  const [busy, setBusy] = useState(false);

  // الإشعار الجماعي
  const [broadcastOpen, setBroadcastOpen] = useState(false);
  const [bTitle, setBTitle] = useState('');
  const [bBody, setBBody] = useState('');
  const [bRole, setBRole] = useState('');

  const load = useCallback(() => {
    setLoading(true);
    setError('');
    api
      .get('/admin/banners')
      .then((d) => setItems(d.items || []))
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  useEffect(load, [load]);

  async function save() {
    if (!form.title.trim()) {
      alert('عنوان اللافتة مطلوب');
      return;
    }
    setBusy(true);
    try {
      const payload = {
        title: form.title.trim(),
        subtitle: form.subtitle.trim(),
        ctaLabel: form.ctaLabel.trim(),
        active: form.active,
        order: Number(form.order) || 0,
      };
      if (editing._id) {
        await api.patch(`/admin/banners/${editing._id}`, payload);
      } else {
        await api.post('/admin/banners', payload);
      }
      setEditing(null);
      load();
    } catch (e) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  async function remove(banner) {
    if (!confirm(`حذف اللافتة «${banner.title}»؟`)) return;
    try {
      await api.delete(`/admin/banners/${banner._id}`);
      load();
    } catch (e) {
      alert(e.message);
    }
  }

  async function toggleActive(banner) {
    try {
      await api.patch(`/admin/banners/${banner._id}`, { active: !banner.active });
      load();
    } catch (e) {
      alert(e.message);
    }
  }

  async function sendBroadcast() {
    if (!bTitle.trim()) {
      alert('عنوان الإشعار مطلوب');
      return;
    }
    setBusy(true);
    try {
      await api.post('/admin/broadcast', {
        title: bTitle.trim(),
        body: bBody.trim(),
        role: bRole || undefined,
      });
      setBroadcastOpen(false);
      setBTitle('');
      setBBody('');
      setBRole('');
      alert('تم إرسال الإشعار الجماعي');
    } catch (e) {
      alert(e.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => {
            setEditing({});
            setForm(EMPTY);
          }}
          className="btn-primary"
        >
          + لافتة جديدة
        </button>
        <button onClick={() => setBroadcastOpen(true)} className="btn-outline">
          📢 إشعار جماعي
        </button>
      </div>

      {loading ? (
        <Spinner />
      ) : error ? (
        <ErrorBox message={error} onRetry={load} />
      ) : items.length === 0 ? (
        <EmptyState
          title="لا توجد لافتات"
          subtitle="أضف لافتة لتظهر في أعلى الواجهة الرئيسية للتطبيق"
        />
      ) : (
        <div className="grid gap-4 md:grid-cols-2">
          {items.map((b) => (
            <div key={b._id} className="card overflow-hidden">
              {/* معاينة مطابقة لشكل اللافتة في التطبيق */}
              <div className="bg-gradient-to-l from-primary-light to-primary-dark p-5">
                <div className="max-w-[220px] text-lg font-extrabold leading-relaxed text-white">
                  {b.title}
                </div>
                {b.subtitle && (
                  <div className="mt-1 text-xs text-white/70">{b.subtitle}</div>
                )}
                {b.ctaLabel && (
                  <span className="mt-3 inline-block rounded-lg bg-gold px-3 py-1.5 text-xs font-extrabold text-amber-950">
                    {b.ctaLabel}
                  </span>
                )}
              </div>

              <div className="flex items-center justify-between px-4 py-3">
                <div className="flex items-center gap-2">
                  <span
                    className={`badge ${
                      b.active
                        ? 'bg-emerald-100 text-emerald-700'
                        : 'bg-slate-200 text-slate-600'
                    }`}
                  >
                    {b.active ? 'نشطة' : 'معطّلة'}
                  </span>
                  <span className="text-xs text-slate-400">الترتيب: {b.order}</span>
                </div>
                <div className="flex gap-1.5">
                  <button
                    onClick={() => toggleActive(b)}
                    className="btn-outline px-3 py-1.5 text-xs"
                  >
                    {b.active ? 'تعطيل' : 'تفعيل'}
                  </button>
                  <button
                    onClick={() => {
                      setEditing(b);
                      setForm({
                        title: b.title || '',
                        subtitle: b.subtitle || '',
                        ctaLabel: b.ctaLabel || '',
                        active: b.active,
                        order: b.order || 0,
                      });
                    }}
                    className="btn-outline px-3 py-1.5 text-xs"
                  >
                    تعديل
                  </button>
                  <button
                    onClick={() => remove(b)}
                    className="btn-danger px-3 py-1.5 text-xs"
                  >
                    حذف
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {editing && (
        <Modal
          title={editing._id ? 'تعديل اللافتة' : 'لافتة جديدة'}
          onClose={() => setEditing(null)}
          footer={
            <>
              <button onClick={() => setEditing(null)} className="btn-outline">
                إلغاء
              </button>
              <button onClick={save} className="btn-primary" disabled={busy}>
                حفظ
              </button>
            </>
          }
        >
          <div className="space-y-4">
            <Field label="العنوان *">
              <input
                className="input"
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                placeholder="مستقبلك المهني يبدأ من هنا"
              />
            </Field>
            <Field label="العنوان الفرعي">
              <input
                className="input"
                value={form.subtitle}
                onChange={(e) => setForm({ ...form, subtitle: e.target.value })}
              />
            </Field>
            <Field label="نص الزر">
              <input
                className="input"
                value={form.ctaLabel}
                onChange={(e) => setForm({ ...form, ctaLabel: e.target.value })}
                placeholder="اكتشف آلاف عروض العمل"
              />
            </Field>
            <Field label="الترتيب">
              <input
                type="number"
                className="input"
                value={form.order}
                onChange={(e) => setForm({ ...form, order: e.target.value })}
              />
            </Field>
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={form.active}
                onChange={(e) => setForm({ ...form, active: e.target.checked })}
                className="h-4 w-4 rounded"
              />
              نشطة
            </label>
          </div>
        </Modal>
      )}

      {broadcastOpen && (
        <Modal
          title="إشعار جماعي"
          onClose={() => setBroadcastOpen(false)}
          footer={
            <>
              <button onClick={() => setBroadcastOpen(false)} className="btn-outline">
                إلغاء
              </button>
              <button onClick={sendBroadcast} className="btn-primary" disabled={busy}>
                إرسال
              </button>
            </>
          }
        >
          <div className="space-y-4">
            <div className="rounded-lg bg-amber-50 p-3 text-xs text-amber-800">
              سيصل هذا الإشعار إلى كل المستخدمين المطابقين. لا يمكن التراجع بعد الإرسال.
            </div>
            <Field label="العنوان *">
              <input
                className="input"
                value={bTitle}
                onChange={(e) => setBTitle(e.target.value)}
              />
            </Field>
            <Field label="النص">
              <textarea
                className="input min-h-[90px]"
                value={bBody}
                onChange={(e) => setBBody(e.target.value)}
              />
            </Field>
            <Field label="الفئة المستهدفة">
              <select
                className="input"
                value={bRole}
                onChange={(e) => setBRole(e.target.value)}
              >
                <option value="">كل المستخدمين</option>
                <option value="seeker">الباحثون عن عمل</option>
                <option value="company">المؤسسات</option>
              </select>
            </Field>
          </div>
        </Modal>
      )}
    </div>
  );
}

function Field({ label, children }) {
  return (
    <div>
      <label className="mb-1.5 block text-sm font-semibold text-slate-700">{label}</label>
      {children}
    </div>
  );
}
