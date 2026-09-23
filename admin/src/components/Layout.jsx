import { useEffect, useState } from 'react';
import { NavLink, useLocation } from 'react-router-dom';
import { api } from '../lib/api';
import { useAuth } from '../lib/auth.jsx';
import { Icon } from './ui.jsx';

const NAV = [
  { to: '/', label: 'لوحة القيادة', icon: 'dashboard' },
  { to: '/offers', label: 'مصادقة العروض', icon: 'clipboard', queue: 'offers' },
  { to: '/companies', label: 'المؤسسات', icon: 'building', queue: 'companies' },
  { to: '/users', label: 'المستخدمون', icon: 'users' },
  { to: '/reports', label: 'البلاغات', icon: 'flag', queue: 'reports' },
  { to: '/banners', label: 'المحتوى الترويجي', icon: 'megaphone' },
];

export default function Layout({ children }) {
  const { user, logout } = useAuth();
  const [open, setOpen] = useState(false);
  const [queues, setQueues] = useState({});
  const location = useLocation();

  // عدّادات المهام المعلّقة تظهر بجانب عناصر القائمة
  useEffect(() => {
    let alive = true;
    const load = () =>
      api
        .get('/admin/stats')
        .then((d) => {
          if (!alive) return;
          setQueues({
            offers: d.offers?.pending || 0,
            reports: d.queue?.pendingReports || 0,
            companies: d.queue?.pendingVerifications || 0,
          });
        })
        .catch(() => {});
    load();
    const t = setInterval(load, 60000);
    return () => {
      alive = false;
      clearInterval(t);
    };
  }, [location.pathname]);

  const current = NAV.find((n) => n.to === location.pathname);
  const totalPending =
    (queues.offers || 0) + (queues.reports || 0) + (queues.companies || 0);

  return (
    <div className="flex min-h-screen bg-slate-100">
      {/* الشريط الجانبي الداكن */}
      <aside
        className={`fixed inset-y-0 right-0 z-40 flex w-64 transform flex-col
                    bg-sidebar text-slate-300 transition-transform duration-200
                    lg:static lg:translate-x-0
                    ${open ? 'translate-x-0' : 'translate-x-full'}`}
      >
        <div className="flex h-16 items-center gap-3 border-b border-sidebar-border px-5">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-admin">
            <Icon name="shield" className="h-5 w-5 text-white" />
          </div>
          <div className="leading-tight">
            <div className="text-sm font-extrabold text-white">لوحة الإدارة</div>
            <div className="text-[10px] text-slate-400">بحث عن عمل DZ</div>
          </div>
        </div>

        <nav className="flex-1 space-y-1 overflow-y-auto p-3">
          {NAV.map((item) => {
            const count = item.queue ? queues[item.queue] : 0;
            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={() => setOpen(false)}
                className={({ isActive }) =>
                  `group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm
                   font-semibold transition-colors ${
                     isActive
                       ? 'bg-admin text-white shadow-lg shadow-admin/20'
                       : 'text-slate-400 hover:bg-sidebar-hover hover:text-white'
                   }`
                }
              >
                <Icon name={item.icon} className="h-[18px] w-[18px]" />
                <span className="flex-1">{item.label}</span>
                {count > 0 && (
                  <span className="rounded-full bg-rose-500 px-2 py-0.5 text-[10px] font-extrabold text-white">
                    {count}
                  </span>
                )}
              </NavLink>
            );
          })}
        </nav>

        <div className="border-t border-sidebar-border p-4">
          <div className="mb-3 flex items-center gap-2.5">
            <div className="flex h-8 w-8 items-center justify-center rounded-full bg-admin/20 text-xs font-extrabold text-admin-light">
              {user?.fullName?.charAt(0) || 'م'}
            </div>
            <div className="min-w-0 flex-1">
              <div className="truncate text-xs font-bold text-slate-200">
                {user?.fullName}
              </div>
              <div className="text-[10px] text-slate-500">مشرف المنصّة</div>
            </div>
          </div>
          <button
            onClick={logout}
            className="btn w-full bg-sidebar-hover text-slate-300 hover:bg-rose-600 hover:text-white"
          >
            <Icon name="logout" className="h-4 w-4" />
            تسجيل الخروج
          </button>
        </div>
      </aside>

      {open && (
        <div
          className="fixed inset-0 z-30 bg-slate-900/50 backdrop-blur-sm lg:hidden"
          onClick={() => setOpen(false)}
        />
      )}

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-20 flex h-16 items-center gap-3 border-b border-slate-200 bg-white/90 px-5 backdrop-blur">
          <button
            onClick={() => setOpen(true)}
            className="rounded-lg p-2 text-slate-600 hover:bg-slate-100 lg:hidden"
            aria-label="فتح القائمة"
          >
            <Icon name="menu" className="h-5 w-5" />
          </button>

          <div className="flex items-center gap-2.5">
            {current && (
              <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-admin-soft text-admin">
                <Icon name={current.icon} className="h-[18px] w-[18px]" />
              </span>
            )}
            <h1 className="text-lg font-extrabold text-slate-800">
              {current?.label || 'لوحة الإدارة'}
            </h1>
          </div>

          <div className="mr-auto flex items-center gap-3">
            {totalPending > 0 && (
              <span className="hidden items-center gap-2 rounded-full bg-amber-50 px-3 py-1.5 text-xs font-bold text-amber-700 sm:flex">
                <span className="h-2 w-2 animate-pulse-dot rounded-full bg-amber-500" />
                {totalPending} مهمّة تنتظر المعالجة
              </span>
            )}
          </div>
        </header>

        <main className="flex-1 p-5">{children}</main>
      </div>
    </div>
  );
}
