import { useEffect, useState } from 'react';
import {
  APK_SIZE,
  APK_URL,
  APP_STORE_URL,
  APP_VERSION,
  CONTACT_EMAIL,
  PLAY_STORE_URL,
  isDownloadReady,
} from './config';
import { Icon, Logo, PhoneMockup } from './components/ui.jsx';

export default function App() {
  return (
    <div className="min-h-screen overflow-x-hidden">
      <Header />
      <Hero />
      <Stats />
      <Features />
      <Audience />
      <HowItWorks />
      <DownloadSection />
      <Faq />
      <Footer />
    </div>
  );
}

/* ─────────────────────────── الترويسة ─────────────────────────── */

function Header() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 transition-all duration-300 ${
        scrolled
          ? 'bg-navy-dark/95 py-3 shadow-lg backdrop-blur'
          : 'bg-transparent py-5'
      }`}
    >
      <div className="section flex items-center justify-between">
        <Logo size="sm" />
        <nav className="hidden items-center gap-7 md:flex">
          {[
            ['المميّزات', '#features'],
            ['كيف يعمل', '#how'],
            ['الأسئلة', '#faq'],
          ].map(([label, href]) => (
            <a
              key={href}
              href={href}
              className="text-sm font-bold text-white/80 transition hover:text-gold"
            >
              {label}
            </a>
          ))}
        </nav>
        <a href="#download" className="btn-gold px-5 py-2.5 text-sm">
          <Icon name="download" className="h-4 w-4" />
          تحميل
        </a>
      </div>
    </header>
  );
}

/* ──────────────────────────── البطل ──────────────────────────── */

function Hero() {
  return (
    <section className="relative overflow-hidden bg-gradient-to-b from-navy to-navy-dark pb-24 pt-32 sm:pt-40">
      {/* أشكال زخرفية */}
      <div className="pointer-events-none absolute -right-24 -top-24 h-80 w-80 rounded-full bg-white/[0.04]" />
      <div className="pointer-events-none absolute -left-16 top-1/3 h-56 w-56 rounded-full bg-gold/[0.07]" />

      <div className="section grid items-center gap-14 lg:grid-cols-2">
        <div className="animate-fade-up text-center lg:text-right">
          <span className="inline-flex items-center gap-2 rounded-full border border-gold/30 bg-gold/10 px-4 py-2 text-xs font-bold text-gold-light">
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-pulse-ring rounded-full bg-gold" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-gold" />
            </span>
            منصّة التشغيل الجزائرية
          </span>

          <h1 className="mt-6 text-4xl font-black leading-[1.25] text-white sm:text-5xl lg:text-6xl">
            فرصتك للعمل
            <br />
            <span className="text-gold">تبدأ من هنا</span>
          </h1>

          <p className="mx-auto mt-6 max-w-xl text-base leading-relaxed text-white/75 lg:mx-0 sm:text-lg">
            تطبيق جزائري يربطك مباشرة بأصحاب المؤسسات في كل الولايات الـ58.
            ابحث حسب ولايتك ومهنتك، أنشئ سيرتك الذاتية، وقدّم طلبك في أقل من
            ثلاث نقرات.
          </p>

          <div className="mt-9 flex flex-col items-center gap-3 sm:flex-row sm:justify-center lg:justify-start">
            <DownloadButton />
            <a href="#features" className="btn-ghost">
              اكتشف المميّزات
            </a>
          </div>

          <div className="mt-8 flex flex-wrap items-center justify-center gap-5 text-xs text-white/60 lg:justify-start">
            {[
              ['shield', 'آمن وموثوق'],
              ['check', 'مجاني للباحثين عن عمل'],
              ['pin', 'كل الولايات الـ58'],
            ].map(([icon, label]) => (
              <span key={label} className="flex items-center gap-1.5">
                <Icon name={icon} className="h-4 w-4 text-gold" />
                {label}
              </span>
            ))}
          </div>
        </div>

        <div className="relative flex justify-center gap-5">
          <PhoneMockup
            variant="home"
            className="animate-float"
          />
          <PhoneMockup
            variant="job"
            className="hidden animate-float lg:block [animation-delay:1.5s]"
          />
        </div>
      </div>

      {/* أفق المدينة */}
      <Skyline />
    </section>
  );
}

function Skyline() {
  const bars = [42, 70, 33, 86, 50, 64, 38, 76, 28, 58, 46, 80, 35, 68, 44, 74];
  return (
    <div
      className="pointer-events-none absolute inset-x-0 bottom-0 flex items-end justify-center gap-1.5 opacity-[0.13]"
      aria-hidden="true"
    >
      {bars.map((h, i) => (
        <div
          key={i}
          className="w-6 rounded-t bg-white sm:w-10"
          style={{ height: `${h}px` }}
        />
      ))}
    </div>
  );
}

function DownloadButton({ large = false }) {
  if (!isDownloadReady) {
    return (
      <span
        className={`btn cursor-not-allowed bg-white/15 text-white/70 ${
          large ? 'px-9 py-5 text-lg' : ''
        }`}
        title="سيُضاف رابط التحميل قريبًا"
      >
        <Icon name="android" className="h-5 w-5" />
        سيتوفّر التحميل قريبًا
      </span>
    );
  }

  return (
    <a
      href={APK_URL}
      download
      className={`btn-gold ${large ? 'px-9 py-5 text-lg' : ''}`}
    >
      <Icon name="android" className="h-5 w-5" />
      حمّل التطبيق لأندرويد
    </a>
  );
}

/* ─────────────────────────── الإحصائيات ─────────────────────────── */

function Stats() {
  const items = [
    ['58', 'ولاية مغطّاة'],
    ['11', 'قطاعًا مهنيًا'],
    ['6', 'أنواع عقود'],
    ['100%', 'مجاني للباحثين'],
  ];

  return (
    <section className="border-b border-slate-100 bg-white py-14">
      <div className="section grid grid-cols-2 gap-8 lg:grid-cols-4">
        {items.map(([value, label]) => (
          <div key={label} className="text-center">
            <div className="text-3xl font-black text-navy sm:text-4xl">
              {value}
            </div>
            <div className="mt-1.5 text-xs font-bold text-slate-500 sm:text-sm">
              {label}
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}

/* ─────────────────────────── المميّزات ─────────────────────────── */

function Features() {
  const features = [
    {
      icon: 'search',
      color: 'bg-emerald-500',
      title: 'بحث ذكي ودقيق',
      body: 'صفِّ العروض حسب الولاية والمهنة ونوع العقد ومجال الراتب، واحفظ بحثك لتصلك تنبيهات بالعروض الجديدة المطابقة.',
    },
    {
      icon: 'file',
      color: 'bg-blue-500',
      title: 'سيرة ذاتية رقمية',
      body: 'أنشئ سيرتك الذاتية داخل التطبيق أو ارفع ملف PDF، وأرسلها بنقرة واحدة مع كل طلب توظيف.',
    },
    {
      icon: 'chat',
      color: 'bg-violet-500',
      title: 'مراسلة مباشرة',
      body: 'تواصل مع المؤسسة فور تقديم طلبك، وتابع حالة الترشّح: قيد الدراسة، مقبول، أو مرفوض.',
    },
    {
      icon: 'shield',
      color: 'bg-orange-500',
      title: 'حماية من الاحتيال',
      body: 'كل عرض يُراجَع من طرف المشرف قبل نشره، مع توثيق المؤسسات ونظام إبلاغ عن العروض المشبوهة.',
    },
    {
      icon: 'bell',
      color: 'bg-rose-500',
      title: 'إشعارات فورية',
      body: 'تنبيه لحظي عند ظهور عرض يناسبك، أو تغيّر حالة طلبك، أو وصول رسالة جديدة من مؤسسة.',
    },
    {
      icon: 'pin',
      color: 'bg-teal-600',
      title: 'كل الولايات الـ58',
      body: 'من أدرار إلى المنيعة — تغطية كاملة لكل الولايات وكل المهن، لا الإطارات فقط.',
    },
  ];

  return (
    <section id="features" className="bg-slate-50 py-20 sm:py-24">
      <div className="section">
        <SectionTitle
          eyebrow="المميّزات"
          title="كل ما تحتاجه للعثور على عمل"
          subtitle="صُمّم التطبيق ليعمل بكفاءة على الهواتف المتوسطة وشبكات 3G."
        />

        <div className="mt-14 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {features.map((f) => (
            <div key={f.title} className="card">
              <div
                className={`mb-4 flex h-12 w-12 items-center justify-center rounded-xl ${f.color}`}
              >
                <Icon name={f.icon} className="h-6 w-6 text-white" />
              </div>
              <h3 className="mb-2 text-lg font-black text-slate-800">
                {f.title}
              </h3>
              <p className="text-sm leading-relaxed text-slate-600">{f.body}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ─────────────────────── الجمهور المستهدف ─────────────────────── */

function Audience() {
  return (
    <section className="bg-white py-20 sm:py-24">
      <div className="section grid gap-8 lg:grid-cols-2">
        <div className="rounded-3xl bg-gradient-to-bl from-navy-light to-navy p-8 text-white sm:p-10">
          <div className="mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-white/15">
            <Icon name="users" className="h-7 w-7" />
          </div>
          <h3 className="mb-3 text-2xl font-black">للباحثين عن عمل</h3>
          <p className="mb-6 text-sm leading-relaxed text-white/75">
            حرفي، تقني، خرّيج أو صاحب مهنة ميدانية — التطبيق مجاني بالكامل
            ومصمّم ليكون سهلًا مهما كان مستواك الرقمي.
          </p>
          <ul className="space-y-3">
            {[
              'بحث حسب الولاية والمهنة ونوع العقد',
              'سيرة ذاتية رقمية جاهزة للإرسال',
              'تنبيهات بالعروض الجديدة المطابقة',
              'متابعة حالة كل طلب توظيف',
            ].map((item) => (
              <li key={item} className="flex items-start gap-2.5 text-sm">
                <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-gold">
                  <Icon name="check" className="h-3 w-3 text-navy-dark" />
                </span>
                <span className="text-white/90">{item}</span>
              </li>
            ))}
          </ul>
        </div>

        <div className="rounded-3xl border-2 border-slate-200 bg-slate-50 p-8 sm:p-10">
          <div className="mb-5 flex h-14 w-14 items-center justify-center rounded-2xl bg-navy-soft">
            <Icon name="building" className="h-7 w-7 text-navy" />
          </div>
          <h3 className="mb-3 text-2xl font-black text-slate-800">
            لأصحاب المؤسسات
          </h3>
          <p className="mb-6 text-sm leading-relaxed text-slate-600">
            مؤسسة صغيرة، ورشة، مطعم أو مصنع — انشر عرضك في ثلاث خطوات وتابع
            الترشّحات من لوحة خاصّة بك.
          </p>
          <ul className="space-y-3">
            {[
              'نشر عرض عمل بمعالج من ثلاث خطوات',
              'لوحة تحكّم بإحصائيات المشاهدات والترشّحات',
              'مراسلة المترشّحين والاطّلاع على سيرهم',
              'شارة «مؤسسة موثّقة» بعد التحقّق',
            ].map((item) => (
              <li key={item} className="flex items-start gap-2.5 text-sm">
                <span className="mt-0.5 flex h-5 w-5 shrink-0 items-center justify-center rounded-full bg-navy">
                  <Icon name="check" className="h-3 w-3 text-white" />
                </span>
                <span className="text-slate-700">{item}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>
    </section>
  );
}

/* ─────────────────────────── كيف يعمل ─────────────────────────── */

function HowItWorks() {
  const steps = [
    ['حمّل التطبيق', 'ثبّت ملف APK على هاتفك في أقل من دقيقة.'],
    ['أنشئ حسابك', 'سجّل برقم هاتفك الجزائري وأكّده برمز SMS.'],
    ['أكمل سيرتك', 'أضف خبراتك ومهاراتك، أو ارفع ملف PDF جاهز.'],
    ['ابحث وقدّم', 'صفِّ العروض حسب ولايتك وقدّم طلبك بنقرة.'],
  ];

  return (
    <section id="how" className="bg-slate-50 py-20 sm:py-24">
      <div className="section">
        <SectionTitle
          eyebrow="كيف يعمل"
          title="أربع خطوات إلى فرصتك القادمة"
        />

        <div className="mt-14 grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map(([title, body], i) => (
            <div key={title} className="relative">
              <div className="card h-full pt-8">
                <span className="absolute -top-4 right-6 flex h-11 w-11 items-center justify-center rounded-xl bg-gradient-to-bl from-navy-light to-navy text-lg font-black text-white shadow-lg">
                  {i + 1}
                </span>
                <h3 className="mb-2 text-base font-black text-slate-800">
                  {title}
                </h3>
                <p className="text-sm leading-relaxed text-slate-600">{body}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ─────────────────────────── التحميل ─────────────────────────── */

function DownloadSection() {
  return (
    <section
      id="download"
      className="relative overflow-hidden bg-gradient-to-bl from-navy-light to-navy-dark py-20 sm:py-24"
    >
      <div className="pointer-events-none absolute -left-20 -top-20 h-72 w-72 rounded-full bg-gold/[0.07]" />

      <div className="section relative text-center">
        <Logo />
        <h2 className="mx-auto mt-8 max-w-2xl text-3xl font-black leading-tight text-white sm:text-4xl">
          حمّل التطبيق وابدأ رحلتك المهنية اليوم
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-base text-white/70">
          الإصدار {APP_VERSION} · {APK_SIZE} · يعمل على أندرويد 8.0 فما فوق
        </p>

        <div className="mt-10 flex flex-col items-center justify-center gap-4 sm:flex-row">
          <DownloadButton large />

          {PLAY_STORE_URL ? (
            <a href={PLAY_STORE_URL} className="btn-ghost">
              <Icon name="android" className="h-5 w-5" />
              Google Play
            </a>
          ) : null}

          {APP_STORE_URL ? (
            <a href={APP_STORE_URL} className="btn-ghost">
              <Icon name="apple" className="h-5 w-5" />
              App Store
            </a>
          ) : null}
        </div>

        {!PLAY_STORE_URL && (
          <p className="mt-6 text-xs text-white/50">
            التطبيق قيد المراجعة للنشر على Google Play و App Store
          </p>
        )}

        <InstallNote />
      </div>
    </section>
  );
}

/** إرشادات تثبيت ملف APK خارج المتجر */
function InstallNote() {
  return (
    <div className="mx-auto mt-12 max-w-2xl rounded-2xl border border-white/15 bg-white/[0.06] p-6 text-right">
      <h3 className="mb-3 flex items-center gap-2 text-sm font-black text-white">
        <Icon name="shield" className="h-4 w-4 text-gold" />
        كيف أثبّت ملف APK؟
      </h3>
      <ol className="space-y-2 text-xs leading-relaxed text-white/70">
        {[
          'حمّل الملف بالضغط على زر التحميل أعلاه.',
          'افتح الملف من شريط الإشعارات أو من مجلّد «التنزيلات».',
          'إن ظهرت رسالة «تثبيت التطبيقات غير المعروفة»، فعّل الإذن للمتصفّح ثم أعد المحاولة.',
          'اضغط «تثبيت» وانتظر انتهاء العملية.',
        ].map((step, i) => (
          <li key={i} className="flex gap-2.5">
            <span className="shrink-0 font-bold text-gold">{i + 1}.</span>
            <span>{step}</span>
          </li>
        ))}
      </ol>
    </div>
  );
}

/* ─────────────────────────── الأسئلة ─────────────────────────── */

function Faq() {
  const items = [
    [
      'هل التطبيق مجاني؟',
      'نعم، التطبيق مجاني بالكامل للباحثين عن عمل ولن يُطلب منك أي مبلغ مقابل البحث أو التقديم. المؤسسات وحدها تدفع مقابل العروض المميّزة والاشتراكات.',
    ],
    [
      'هل يغطّي التطبيق كل الولايات؟',
      'نعم، كل الولايات الـ58 وكل القطاعات: البناء، النقل، المطاعم، الصناعة، التجارة، الإعلام الآلي، الصحة، التعليم، الفلاحة، الخدمات والحرف.',
    ],
    [
      'كيف أحمي نفسي من العروض الوهمية؟',
      'كل عرض يُراجَع من طرف المشرف قبل نشره، والمؤسسات الموثّقة تحمل شارة خاصّة. لا تدفع أي مبلغ مقابل التوظيف مهما كان السبب، وأبلغ عن أي عرض يطلب ذلك عبر زر «الإبلاغ».',
    ],
    [
      'ماذا يحدث لبياناتي الشخصية؟',
      'نلتزم بالقانون 18-07 المتعلّق بحماية المعطيات ذات الطابع الشخصي: لا نبيع بياناتك، ونجمع الحد الأدنى اللازم، ويمكنك حذف حسابك وبياناتك نهائيًا في أي وقت من داخل التطبيق.',
    ],
    [
      'هل يعمل التطبيق على هاتفي؟',
      `يعمل على أندرويد 8.0 فما فوق. حجم التطبيق ${APK_SIZE} وهو مصمّم ليعمل بكفاءة على الهواتف المتوسطة وشبكات 3G.`,
    ],
  ];

  const [open, setOpen] = useState(0);

  return (
    <section id="faq" className="bg-white py-20 sm:py-24">
      <div className="section max-w-3xl">
        <SectionTitle eyebrow="الأسئلة الشائعة" title="أسئلة قد تدور في بالك" />

        <div className="mt-12 space-y-3">
          {items.map(([q, a], i) => {
            const isOpen = open === i;
            return (
              <div
                key={q}
                className={`overflow-hidden rounded-2xl border transition-colors ${
                  isOpen
                    ? 'border-navy/25 bg-navy-soft/40'
                    : 'border-slate-200 bg-white'
                }`}
              >
                <button
                  onClick={() => setOpen(isOpen ? -1 : i)}
                  aria-expanded={isOpen}
                  className="flex w-full items-center justify-between gap-4 px-5 py-4 text-right"
                >
                  <span className="text-sm font-extrabold text-slate-800 sm:text-base">
                    {q}
                  </span>
                  <span
                    className={`flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-lg font-black transition-transform ${
                      isOpen
                        ? 'rotate-45 bg-navy text-white'
                        : 'bg-slate-100 text-slate-500'
                    }`}
                  >
                    +
                  </span>
                </button>
                {isOpen && (
                  <p className="animate-fade-up px-5 pb-5 text-sm leading-relaxed text-slate-600">
                    {a}
                  </p>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </section>
  );
}

/* ─────────────────────────── مكوّنات ─────────────────────────── */

function SectionTitle({ eyebrow, title, subtitle }) {
  return (
    <div className="text-center">
      <span className="text-xs font-black uppercase tracking-widest text-gold-dark">
        {eyebrow}
      </span>
      <h2 className="mt-3 text-3xl font-black leading-tight text-slate-900 sm:text-4xl">
        {title}
      </h2>
      {subtitle && (
        <p className="mx-auto mt-4 max-w-2xl text-base text-slate-600">
          {subtitle}
        </p>
      )}
    </div>
  );
}

function Footer() {
  return (
    <footer className="bg-navy-dark py-12 text-white/60">
      <div className="section">
        <div className="flex flex-col items-center gap-8 border-b border-white/10 pb-8 sm:flex-row sm:items-start sm:justify-between">
          <div className="text-center sm:text-right">
            <Logo size="sm" />
            <p className="mt-4 max-w-xs text-xs leading-relaxed">
              منصّة التشغيل الجزائرية التي تربط الباحثين عن عمل بأصحاب
              المؤسسات في كل الولايات الـ58.
            </p>
          </div>

          <div className="flex gap-12 text-center sm:text-right">
            <div>
              <h4 className="mb-3 text-xs font-black text-white">التطبيق</h4>
              <ul className="space-y-2 text-xs">
                <li>
                  <a href="#features" className="transition hover:text-gold">
                    المميّزات
                  </a>
                </li>
                <li>
                  <a href="#how" className="transition hover:text-gold">
                    كيف يعمل
                  </a>
                </li>
                <li>
                  <a href="#download" className="transition hover:text-gold">
                    تحميل
                  </a>
                </li>
              </ul>
            </div>
            <div>
              <h4 className="mb-3 text-xs font-black text-white">تواصل</h4>
              <ul className="space-y-2 text-xs">
                <li>
                  <a
                    href={`mailto:${CONTACT_EMAIL}`}
                    className="transition hover:text-gold"
                  >
                    {CONTACT_EMAIL}
                  </a>
                </li>
                <li>
                  <a href="#faq" className="transition hover:text-gold">
                    الأسئلة الشائعة
                  </a>
                </li>
              </ul>
            </div>
          </div>
        </div>

        <div className="flex flex-col items-center justify-between gap-3 pt-6 text-center text-xs sm:flex-row">
          <span>
            © {new Date().getFullYear()} بحث عن عمل DZ · جميع الحقوق محفوظة
          </span>
          <span className="font-bold text-gold">معًا نحو مستقبل أفضل</span>
        </div>
      </div>
    </footer>
  );
}
