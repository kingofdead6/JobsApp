import { useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { useAuth } from '../lib/auth.jsx';

const NAV = [
  { to: '/', label: 'لوحة القيادة', icon: '📊' },
  { to: '/offers', label: 'مصادقة العروض', icon: '📋' },
  { to: '/companies', label: 'المؤسسات', icon: '🏢' },
  { to: '/users', label: 'المستخدمون', icon: '👥' },
  { to: '/reports', label: 'البلاغات', icon: '🚩' },
  { to: '/banners', label: 'المحتوى الترويجي', icon: '📢' },
];

export default function Layout({ children }) {
  const { user, logout } = useAuth();
  const [open, setOpen] = useState(false);
  const location = useLocation();

  const title = NAV.find((n) => n.to === location.pathname)?.label || 'لوحة الإدارة';

  return (
    <div className="flex min-h-screen">
      {/* الشريط الجانبي */}
      <aside
        className={`fixed inset-y-0 right-0 z-40 w-64 transform bg-primary text-white transition-transform
                    lg:static lg:translate-x-0 ${open ? 'translate-x-0' : 'translate-x-full'}`}
      >
        <div className="flex h-16 items-center gap-2 border-b border-white/10 px-5">
          <span className="text-2xl">🔍</span>
          <div className="leading-tight">
            <div className="text-sm font-extrabold">
              بحث عن <span className="text-gold">عمل</span> DZ
            </div>
            <div className="text-[10px] text-white/60">لوحة الإدارة</div>
          </div>
        </div>

        <nav className="space-y-1 p-3">
          {NAV.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              onClick={() => setOpen(false)}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-semibold transition ${
                  isActive ? 'bg-white/15 text-white' : 'text-white/70 hover:bg-white/10'
                }`
              }
            >
              <span>{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>

        <div className="absolute inset-x-0 bottom-0 border-t border-white/10 p-4">
          <div className="mb-3 text-xs text-white/70">{user?.fullName}</div>
          <button onClick={logout} className="btn w-full bg-white/10 text-white hover:bg-white/20">
            تسجيل الخروج
          </button>
        </div>
      </aside>

      {open && (
        <div
          className="fixed inset-0 z-30 bg-black/40 lg:hidden"
          onClick={() => setOpen(false)}
        />
      )}

      {/* المحتوى */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-20 flex h-16 items-center gap-3 border-b border-slate-200 bg-white px-5">
          <button
            onClick={() => setOpen(true)}
            className="rounded-lg p-2 text-slate-600 hover:bg-slate-100 lg:hidden"
            aria-label="فتح القائمة"
          >
            ☰
          </button>
          <h1 className="text-lg font-extrabold text-slate-800">{title}</h1>
        </header>

        <main className="flex-1 p-5">{children}</main>
      </div>
    </div>
  );
}
