/* مكوّنات مشتركة: أيقونات SVG مضمّنة، الشعار، ونموذج الهاتف */

const PATHS = {
  search:
    'M10 2a8 8 0 105 14.3l5.4 5.4 1.4-1.4-5.4-5.4A8 8 0 0010 2zm0 2a6 6 0 110 12 6 6 0 010-12z',
  briefcase:
    'M9 3a2 2 0 00-2 2v1H4a2 2 0 00-2 2v11a2 2 0 002 2h16a2 2 0 002-2V8a2 2 0 00-2-2h-3V5a2 2 0 00-2-2H9zm0 2h6v1H9V5z',
  pin: 'M12 2a7 7 0 00-7 7c0 5.2 7 13 7 13s7-7.8 7-13a7 7 0 00-7-7zm0 9.5A2.5 2.5 0 1112 6a2.5 2.5 0 010 5.5z',
  chat: 'M4 3h16a2 2 0 012 2v10a2 2 0 01-2 2H9l-5 4V5a2 2 0 012-2z',
  file: 'M6 2h8l6 6v12a2 2 0 01-2 2H6a2 2 0 01-2-2V4a2 2 0 012-2zm7 1.5V9h5.5L13 3.5z',
  shield:
    'M12 2l8 3v6c0 5-3.4 9.4-8 11-4.6-1.6-8-6-8-11V5l8-3zm-1 12.8l5-5-1.4-1.4L11 12l-1.6-1.6L8 11.8l3 3z',
  bell: 'M12 2a6 6 0 00-6 6v4l-2 3v1h16v-1l-2-3V8a6 6 0 00-6-6zm0 20a3 3 0 003-3H9a3 3 0 003 3z',
  check: 'M9 16.2l-3.5-3.5L4 14.2l5 5 11-11-1.5-1.4L9 16.2z',
  download:
    'M12 3a1 1 0 011 1v9.6l3.3-3.3 1.4 1.4L12 17.4l-5.7-5.7 1.4-1.4L11 13.6V4a1 1 0 011-1zM4 19h16v2H4v-2z',
  android:
    'M6 9h12v8a2 2 0 01-2 2h-1v3h-2v-3h-2v3H9v-3H8a2 2 0 01-2-2V9zm-2 0a1.5 1.5 0 013 0v6a1.5 1.5 0 01-3 0V9zm13 0a1.5 1.5 0 013 0v6a1.5 1.5 0 01-3 0V9zM8.5 3.5l1 1.7a6.9 6.9 0 015 0l1-1.7.9.5-1 1.8A6 6 0 0118 8H6a6 6 0 012.6-2.2l-1-1.8.9-.5zM9.5 6.5a.75.75 0 100 1.5.75.75 0 000-1.5zm5 0a.75.75 0 100 1.5.75.75 0 000-1.5z',
  apple:
    'M16.4 12.7c0-2.3 1.9-3.4 2-3.5-1.1-1.6-2.8-1.8-3.4-1.8-1.4-.1-2.8.9-3.6.9-.7 0-1.9-.8-3.1-.8-1.6 0-3.1.9-3.9 2.4-1.7 2.9-.4 7.1 1.2 9.4.8 1.1 1.7 2.4 3 2.3 1.2 0 1.6-.8 3.1-.8 1.4 0 1.8.8 3.1.7 1.3 0 2.1-1.1 2.9-2.3.9-1.3 1.3-2.6 1.3-2.7 0 0-2.5-1-2.6-3.8zM14.1 5.5c.7-.8 1.1-2 1-3.1-1 0-2.2.7-2.9 1.5-.6.7-1.2 1.9-1 3 1.1.1 2.2-.6 2.9-1.4z',
  users:
    'M16 11a4 4 0 100-8 4 4 0 000 8zm-8 0a4 4 0 100-8 4 4 0 000 8zm0 2c-3 0-6 1.5-6 4v3h9v-3c0-1 .4-2 1-2.8-1.2-.8-2.7-1.2-4-1.2zm8 0c-.6 0-1.3.1-2 .2 1 1 1.5 2.2 1.5 3.6V20H22v-3c0-2.5-3-4-6-4z',
  star: 'M12 2l3 6.6 7 .8-5.2 4.8 1.4 7L12 17.8 5.8 21.2l1.4-7L2 9.4l7-.8L12 2z',
  building:
    'M4 21V5a2 2 0 012-2h6a2 2 0 012 2v16H4zm12 0V9h4v12h-4zM7 7h2v2H7V7zm0 4h2v2H7v-2zm0 4h2v2H7v-2z',
};

export function Icon({ name, className = 'h-6 w-6' }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="currentColor"
      className={className}
      aria-hidden="true"
    >
      <path d={PATHS[name] || PATHS.search} />
    </svg>
  );
}

/** شعار التطبيق: عدسة بحث + حقيبة، «بحث عن» ثمّ «عمل» ذهبي */
export function Logo({ light = true, size = 'md' }) {
  const dims = {
    sm: { box: 'h-9 w-9', icon: 'h-5 w-5', text: 'text-lg', dz: 'text-[9px]' },
    md: { box: 'h-12 w-12', icon: 'h-6 w-6', text: 'text-2xl', dz: 'text-[10px]' },
  }[size];

  return (
    <div className="flex items-center gap-3">
      <div
        className={`relative flex ${dims.box} items-center justify-center rounded-2xl border-2 border-gold ${
          light ? 'bg-white/15' : 'bg-navy-soft'
        }`}
      >
        <Icon
          name="search"
          className={`${dims.icon} ${light ? 'text-white' : 'text-navy'}`}
        />
        <span className="absolute -bottom-1 -left-1 flex h-5 w-5 items-center justify-center rounded-full bg-gold">
          <Icon name="briefcase" className="h-3 w-3 text-navy-dark" />
        </span>
      </div>
      <div className="leading-none">
        <div className={`${dims.text} font-black`}>
          <span className={light ? 'text-white' : 'text-navy'}>بحث عن </span>
          <span className="text-gold">عمل</span>
        </div>
        <div
          className={`mt-1 ${dims.dz} font-black tracking-[0.3em] ${
            light ? 'text-gold-light' : 'text-gold-dark'
          }`}
        >
          DZ
        </div>
      </div>
    </div>
  );
}

/**
 * نموذج هاتف مرسوم بالكامل بـ CSS — لا نحتاج لقطات شاشة حقيقية.
 * `variant` يحدّد المحتوى المعروض داخل الإطار.
 */
export function PhoneMockup({ variant = 'home', className = '' }) {
  return (
    <div
      className={`relative mx-auto w-[260px] rounded-[2.5rem] border-[10px] border-slate-900 bg-slate-900 shadow-2xl ${className}`}
    >
      {/* نتوء الكاميرا */}
      <div className="absolute left-1/2 top-0 z-10 h-5 w-28 -translate-x-1/2 rounded-b-2xl bg-slate-900" />
      <div className="h-[520px] overflow-hidden rounded-[1.9rem] bg-slate-50">
        {variant === 'home' ? <ScreenHome /> : <ScreenJob />}
      </div>
    </div>
  );
}

function ScreenHome() {
  return (
    <div className="flex h-full flex-col">
      <div className="bg-gradient-to-bl from-navy-light to-navy px-4 pb-5 pt-8">
        <div className="mb-4 flex items-center justify-between">
          <div className="text-sm font-black text-white">
            بحث عن <span className="text-gold">عمل</span>
          </div>
          <Icon name="bell" className="h-4 w-4 text-white/80" />
        </div>
        <div className="text-[13px] font-extrabold text-white">
          مرحبًا، أحمد 👋
        </div>
        <div className="mt-0.5 text-[10px] text-white/70">
          <span className="font-bold text-gold-light">8</span> عروض عمل في انتظارك
        </div>
        <div className="mt-3 flex items-center gap-2 rounded-xl bg-white px-3 py-2.5 shadow-lg">
          <Icon name="search" className="h-3.5 w-3.5 text-navy" />
          <span className="text-[10px] text-slate-400">
            ابحث عن وظيفة، مهنة، شركة...
          </span>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-2 p-3">
        {[
          ['البحث عن عمل', 'search', 'bg-emerald-500'],
          ['سيرتي الذاتية', 'file', 'bg-blue-500'],
          ['الشركات', 'building', 'bg-violet-500'],
          ['حسب الولاية', 'pin', 'bg-orange-500'],
          ['المميّزة', 'star', 'bg-rose-500'],
          ['المحفوظة', 'briefcase', 'bg-teal-600'],
        ].map(([label, icon, bg]) => (
          <div
            key={label}
            className="flex flex-col items-center gap-1.5 rounded-xl border border-slate-200 bg-white py-2.5"
          >
            <span
              className={`flex h-8 w-8 items-center justify-center rounded-lg ${bg}`}
            >
              <Icon name={icon} className="h-4 w-4 text-white" />
            </span>
            <span className="text-[7.5px] font-bold text-slate-700">{label}</span>
          </div>
        ))}
      </div>

      <div className="flex-1 space-y-2 px-3">
        <div className="text-[10px] font-black text-slate-800">
          أحدث عروض العمل
        </div>
        {[
          ['مهندس مدني', 'شركة البناء الجزائرية', 'الجزائر'],
          ['محاسب', 'مؤسسة تجارية خاصة', 'وهران'],
        ].map(([title, co, city]) => (
          <div
            key={title}
            className="rounded-xl border border-slate-200 bg-white p-2.5"
          >
            <div className="flex items-center gap-2">
              <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-navy-soft">
                <Icon name="briefcase" className="h-4 w-4 text-navy" />
              </span>
              <div className="min-w-0 flex-1">
                <div className="truncate text-[9.5px] font-extrabold text-slate-800">
                  {title}
                </div>
                <div className="truncate text-[8px] text-slate-500">{co}</div>
              </div>
            </div>
            <div className="mt-2 flex items-center gap-1.5 border-t border-slate-100 pt-2">
              <Icon name="pin" className="h-2.5 w-2.5 text-emerald-600" />
              <span className="text-[7.5px] text-slate-500">{city}</span>
              <span className="rounded-full bg-emerald-50 px-1.5 py-0.5 text-[7px] font-bold text-emerald-700">
                دوام كامل
              </span>
            </div>
          </div>
        ))}
      </div>

      <div className="flex justify-around border-t border-slate-200 bg-white py-2">
        {['users', 'chat', 'search', 'bell', 'file'].map((n, i) => (
          <Icon
            key={n}
            name={n}
            className={`h-4 w-4 ${i === 2 ? 'text-navy' : 'text-slate-300'}`}
          />
        ))}
      </div>
    </div>
  );
}

function ScreenJob() {
  return (
    <div className="flex h-full flex-col">
      <div className="bg-gradient-to-bl from-navy-light to-navy px-4 pb-5 pt-9 text-center">
        <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-white">
          <Icon name="briefcase" className="h-7 w-7 text-navy" />
        </div>
        <div className="mt-3 text-sm font-black text-white">مهندس مدني</div>
        <div className="mt-1 text-[10px] text-white/70">
          شركة البناء الجزائرية
        </div>
        <div className="mt-2.5 flex justify-center gap-2">
          <span className="rounded-full bg-white/20 px-2 py-1 text-[8px] font-bold text-white">
            الجزائر العاصمة
          </span>
          <span className="rounded-full bg-emerald-500 px-2 py-1 text-[8px] font-bold text-white">
            دوام كامل
          </span>
        </div>
      </div>

      <div className="flex-1 space-y-3 p-3">
        <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-3">
          <div className="text-[8px] text-slate-500">الراتب الشهري</div>
          <div className="text-[13px] font-black text-emerald-700">
            50,000 - 80,000 دج
          </div>
        </div>

        <div>
          <div className="mb-1.5 text-[10px] font-black text-slate-800">
            المهارات المطلوبة
          </div>
          {['إتقان برامج التصميم', 'العمل الجماعي', 'حل المشكلات'].map((s) => (
            <div key={s} className="mb-1.5 flex items-center gap-1.5">
              <span className="flex h-3.5 w-3.5 items-center justify-center rounded-full bg-emerald-100">
                <Icon name="check" className="h-2 w-2 text-emerald-600" />
              </span>
              <span className="text-[8.5px] text-slate-600">{s}</span>
            </div>
          ))}
        </div>
      </div>

      <div className="border-t border-slate-200 bg-white p-3">
        <div className="flex items-center justify-center gap-2 rounded-xl bg-gradient-to-bl from-navy-light to-navy py-3">
          <span className="text-[11px] font-black text-white">تقديم الطلب</span>
        </div>
      </div>
    </div>
  );
}
