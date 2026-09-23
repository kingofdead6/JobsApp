import { useState } from 'react';
import { useAuth } from '../lib/auth.jsx';
import { Icon } from '../components/ui.jsx';

export default function Login() {
  const { login } = useAuth();
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(identifier.trim(), password);
    } catch (err) {
      setError(err.message || 'تعذّر تسجيل الدخول');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-sidebar p-4">
      {/* شبكة خفيفة في الخلفية توحي بلوحة تحكّم */}
      <div
        className="pointer-events-none absolute inset-0 opacity-[0.07]"
        style={{
          backgroundImage:
            'linear-gradient(#fff 1px, transparent 1px), linear-gradient(90deg, #fff 1px, transparent 1px)',
          backgroundSize: '44px 44px',
        }}
      />

      <div className="relative w-full max-w-md animate-fade-up rounded-2xl bg-white p-8 shadow-lifted">
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-admin shadow-lg shadow-admin/30">
            <Icon name="shield" className="h-7 w-7 text-white" />
          </div>
          <h1 className="text-xl font-extrabold text-slate-800">لوحة الإدارة</h1>
          <p className="mt-1 text-sm text-slate-500">
            بحث عن <span className="font-bold text-admin">عمل</span> DZ
          </p>
        </div>

        <form onSubmit={onSubmit} className="space-y-4">
          <div>
            <label
              htmlFor="identifier"
              className="mb-1.5 block text-sm font-bold text-slate-700"
            >
              رقم الهاتف أو البريد الإلكتروني
            </label>
            <input
              id="identifier"
              className="input"
              value={identifier}
              onChange={(e) => setIdentifier(e.target.value)}
              placeholder="0550000000"
              autoComplete="username"
              required
            />
          </div>

          <div>
            <label
              htmlFor="password"
              className="mb-1.5 block text-sm font-bold text-slate-700"
            >
              كلمة المرور
            </label>
            <input
              id="password"
              type="password"
              className="input"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              autoComplete="current-password"
              required
            />
          </div>

          {error && (
            <div className="flex items-start gap-2 rounded-lg bg-rose-50 px-4 py-3 text-sm font-semibold text-rose-700">
              <Icon name="warning" className="mt-0.5 h-4 w-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <button type="submit" className="btn-primary w-full" disabled={loading}>
            {loading ? (
              <>
                <span className="h-4 w-4 animate-spin rounded-full border-2 border-white/40 border-t-white" />
                جارٍ الدخول...
              </>
            ) : (
              <>
                <Icon name="shield" className="h-4 w-4" />
                تسجيل الدخول
              </>
            )}
          </button>
        </form>

        <p className="mt-6 flex items-center justify-center gap-1.5 text-center text-xs text-slate-400">
          <Icon name="shield" className="h-3.5 w-3.5" />
          الدخول محصور بحسابات المشرفين
        </p>
      </div>
    </div>
  );
}
