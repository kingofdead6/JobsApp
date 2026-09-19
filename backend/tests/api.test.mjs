// اختبار تكاملي سريع لمسارات الـ API الأساسية
const BASE = 'http://127.0.0.1:5000/api';
let pass = 0, fail = 0;

async function call(method, path, { token, body, raw } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      ...(body && !raw ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? (raw ? body : JSON.stringify(body)) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  return { status: res.status, json };
}

function check(name, cond, extra = '') {
  if (cond) { pass++; console.log(`  ✓ ${name}`); }
  else { fail++; console.log(`  ✗ ${name} ${extra}`); }
}

const log = (s) => console.log(`\n=== ${s} ===`);

// 1. صحة الخادم + المراجع
log('العام');
let r = await call('GET', '/health');
check('health 200', r.status === 200);

r = await call('GET', '/reference');
check('58 ولاية', r.json.data?.wilayas?.length === 58, `got ${r.json.data?.wilayas?.length}`);
check('6 أنواع عقود', r.json.data?.contractTypes?.length === 6);
check('11 قطاعًا', r.json.data?.sectors?.length === 11);

r = await call('GET', '/home');
check('الواجهة الرئيسية', r.status === 200 && r.json.data?.latestOffers?.length > 0);
check('لافتة ترويجية', r.json.data?.banners?.length > 0);

// 2. البحث والتصفية
log('البحث والتصفية (3.3)');
r = await call('GET', '/jobs');
const totalJobs = r.json.data?.pagination?.total;
check('قائمة العروض', r.status === 200 && totalJobs === 8, `total=${totalJobs}`);

r = await call('GET', '/jobs?wilaya=' + encodeURIComponent('وهران'));
check('تصفية بالولاية', r.json.data?.items?.every(i => i.wilaya === 'وهران') && r.json.data.items.length === 1);

r = await call('GET', '/jobs?contractType=internship');
check('تصفية بنوع العقد', r.json.data?.items?.length === 1 && r.json.data.items[0].contractType === 'internship');

r = await call('GET', '/jobs?sector=construction,transport');
check('تصفية بعدّة قطاعات', r.json.data?.items?.length === 2, `got ${r.json.data?.items?.length}`);

r = await call('GET', '/jobs?salaryMin=70000');
check('تصفية بالراتب', r.json.data?.items?.every(i => i.salaryMax >= 70000));

r = await call('GET', '/jobs?q=' + encodeURIComponent('مهندس'));
check('بحث نصّي عربي', r.json.data?.items?.length >= 1, `got ${r.json.data?.items?.length}`);

r = await call('GET', '/jobs/featured');
check('العروض المميّزة', r.json.data?.items?.length === 2, `got ${r.json.data?.items?.length}`);

r = await call('GET', '/jobs/by-wilaya');
check('العروض حسب الولاية', r.json.data?.items?.length > 0);

// العرض المميّز يتصدّر النتائج
r = await call('GET', '/jobs');
check('العرض المميّز في المقدّمة', r.json.data?.items?.[0]?.featured === true);

// العرض قيد المراجعة لا يظهر للعموم
check('العرض قيد المراجعة مخفي', !r.json.data.items.some(i => i.title === 'عون استقبال'));

// 3. المصادقة
log('المصادقة (3.1)');
r = await call('POST', '/auth/login', { body: { identifier: '0555121456', password: 'seeker123456' } });
const seekerToken = r.json.data?.token;
check('دخول الباحث عن عمل', r.status === 200 && !!seekerToken);

r = await call('POST', '/auth/login', { body: { identifier: '0555121456', password: 'wrong' } });
check('رفض كلمة مرور خاطئة', r.status === 401);

r = await call('POST', '/auth/login', { body: { identifier: '0550120001', password: 'company123456' } });
const companyToken = r.json.data?.token;
check('دخول المؤسسة', r.status === 200 && !!companyToken);

r = await call('POST', '/auth/login', { body: { identifier: '0550000000', password: 'admin123456' } });
const adminToken = r.json.data?.token;
check('دخول المشرف', r.status === 200 && !!adminToken);

r = await call('GET', '/auth/me', { token: seekerToken });
check('بيانات المستخدم الحالي', r.json.data?.user?.fullName === 'أحمد بن يوسف');
check('كلمة المرور غير مُعادة', r.json.data?.user?.password === undefined);

r = await call('GET', '/auth/me');
check('رفض الوصول دون رمز', r.status === 401);

// تسجيل جديد + OTP
const newPhone = '0561' + String(Date.now()).slice(-6);
r = await call('POST', '/auth/register', {
  body: { fullName: 'مستخدم تجريبي', phone: newPhone, password: 'test123456', role: 'seeker', wilaya: 'سطيف' },
});
const devOtp = r.json.data?.devOtp;
check('إنشاء حساب', r.status === 201 && !!devOtp);

r = await call('POST', '/auth/login', { body: { identifier: newPhone, password: 'test123456' } });
check('منع الدخول قبل تأكيد الهاتف', r.status === 403);

r = await call('POST', '/auth/verify-otp', { body: { phone: newPhone, code: '000000' } });
check('رفض رمز OTP خاطئ', r.status === 400);

r = await call('POST', '/auth/verify-otp', { body: { phone: newPhone, code: devOtp } });
check('قبول رمز OTP صحيح', r.status === 200 && !!r.json.data?.token);

r = await call('POST', '/auth/register', {
  body: { fullName: 'مكرر', phone: newPhone, password: 'test123456', role: 'seeker' },
});
check('منع تكرار رقم الهاتف', r.status === 409);

r = await call('POST', '/auth/register', {
  body: { fullName: 'مخترق', phone: '0599999999', password: 'test123456', role: 'admin' },
});
check('منع إنشاء حساب مشرف', r.status === 403 || r.status === 400);

// 4. السيرة الذاتية
log('السيرة الذاتية (3.5)');
r = await call('GET', '/profile/me', { token: seekerToken });
check('جلب السيرة الذاتية', r.status === 200);
check('مؤشّر الاكتمال %', typeof r.json.data?.profile?.completion === 'number', `= ${r.json.data?.profile?.completion}`);

r = await call('PATCH', '/profile/me', { token: seekerToken, body: { headline: 'تقني سامي محدَّث' } });
check('تحديث السيرة', r.json.data?.profile?.headline === 'تقني سامي محدَّث');

// 5. تفاصيل العرض والترشّح
log('تفاصيل العرض والترشّح (3.4)');
r = await call('GET', '/jobs');
const offerId = r.json.data.items[0]._id;

r = await call('GET', `/jobs/${offerId}`, { token: seekerToken });
check('تفاصيل العرض', r.status === 200 && !!r.json.data?.offer?.title);
check('اسم المؤسسة مُرفق', !!r.json.data?.offer?.company?.name);

r = await call('POST', '/saved/offers/' + offerId, { token: seekerToken });
check('حفظ العرض في المفضّلة', r.status === 201);

r = await call('GET', '/saved/offers', { token: seekerToken });
check('قائمة المحفوظات', r.json.data?.items?.length === 1);

r = await call('GET', `/jobs/${offerId}`, { token: seekerToken });
check('العرض معلَّم كمحفوظ', r.json.data?.isSaved === true);

r = await call('POST', '/applications', { token: seekerToken, body: { offerId, coverLetter: 'أرغب في الانضمام إلى فريقكم.' } });
const applicationId = r.json.data?.application?._id;
check('تقديم الطلب', r.status === 201 && !!applicationId);

r = await call('POST', '/applications', { token: seekerToken, body: { offerId } });
check('منع الترشّح مرّتين', r.status === 409);

r = await call('POST', '/applications', { token: companyToken, body: { offerId } });
check('منع المؤسسة من الترشّح', r.status === 403);

r = await call('GET', '/applications/mine', { token: seekerToken });
check('طلباتي', r.json.data?.items?.length === 1 && r.json.data.items[0].status === 'pending');

// 6. جانب المؤسسة
log('نشر العرض (3.6)');
r = await call('POST', '/jobs', {
  token: companyToken,
  body: {
    title: 'عامل بناء', profession: 'عامل بناء', sector: 'construction',
    wilaya: 'الجزائر العاصمة', contractType: 'full_time',
    description: 'مطلوب عمال بناء ذوو خبرة للعمل في ورشات بالعاصمة، التكفّل بالنقل والإطعام مضمون.',
  },
});
const newOfferId = r.json.data?.offer?._id;
check('نشر عرض جديد', r.status === 201 && !!newOfferId);
check('العرض يبدأ قيد المراجعة', r.json.data?.offer?.status === 'pending');

r = await call('POST', '/jobs', { token: companyToken, body: { title: 'ناقص' } });
check('رفض عرض ناقص الحقول', r.status === 400);

r = await call('POST', '/jobs', { token: seekerToken, body: { title: 'x' } });
check('منع الباحث من نشر عرض', r.status === 403);

r = await call('GET', '/jobs?q=' + encodeURIComponent('عامل بناء'));
check('العرض الجديد غير ظاهر قبل المصادقة', !r.json.data.items.some(i => i._id === newOfferId));

// 7. لوحة الإدارة
log('لوحة الإدارة (الفصل 4)');
r = await call('GET', '/admin/offers?status=pending', { token: adminToken });
check('قائمة العروض قيد المراجعة', r.json.data?.items?.length >= 2, `got ${r.json.data?.items?.length}`);

r = await call('GET', '/admin/offers', { token: seekerToken });
check('منع غير المشرف من لوحة الإدارة', r.status === 403);

r = await call('PATCH', `/admin/offers/${newOfferId}/review`, { token: adminToken, body: { decision: 'reject' } });
check('رفض دون سبب مرفوض', r.status === 400);

r = await call('PATCH', `/admin/offers/${newOfferId}/review`, { token: adminToken, body: { decision: 'approve' } });
check('المصادقة على العرض', r.status === 200 && r.json.data?.offer?.status === 'approved');

r = await call('GET', '/jobs?q=' + encodeURIComponent('عامل بناء'));
check('العرض يظهر بعد المصادقة', r.json.data.items.some(i => i._id === newOfferId));

r = await call('GET', '/admin/stats', { token: adminToken });
check('الإحصائيات', r.status === 200 && r.json.data?.applicationsTotal >= 1);
check('أكثر الولايات نشاطًا', r.json.data?.topWilayas?.length > 0);

// 8. الترشّحات من جانب المؤسسة + المراسلة
log('الترشّحات والمراسلة (3.7)');
r = await call('GET', `/applications/offer/${offerId}`, { token: companyToken });
check('ترشّحات العرض', r.json.data?.items?.length === 1);

r = await call('PATCH', `/applications/${applicationId}/status`, { token: companyToken, body: { status: 'accepted', note: 'مرحبًا بك' } });
check('قبول الترشّح', r.status === 200 && r.json.data?.application?.status === 'accepted');

r = await call('GET', '/notifications', { token: seekerToken });
check('إشعار بتغيّر حالة الطلب', r.json.data?.items?.some(n => n.type === 'application_status'));

r = await call('POST', '/messages', { token: companyToken, body: { applicationId, body: 'مرحبًا، نود مقابلتك يوم الأحد.' } });
const convId = r.json.data?.conversationId;
check('إرسال رسالة', r.status === 201 && !!convId);

r = await call('GET', '/messages/conversations', { token: seekerToken });
check('قائمة المحادثات', r.json.data?.items?.length === 1);
check('عدّاد غير المقروء', r.json.data?.items?.[0]?.unreadCount === 1);

r = await call('GET', `/messages/conversations/${convId}`, { token: seekerToken });
check('قراءة الرسائل', r.json.data?.messages?.length === 1);

r = await call('GET', '/messages/unread-count', { token: seekerToken });
check('تصفير غير المقروء بعد القراءة', r.json.data?.count === 0);

// وصول طرف ثالث إلى المحادثة
r = await call('POST', '/auth/login', { body: { identifier: '0550120002', password: 'company123456' } });
const otherToken = r.json.data?.token;
r = await call('GET', `/messages/conversations/${convId}`, { token: otherToken });
check('منع طرف ثالث من قراءة المحادثة', r.status === 403);

// 9. البلاغات
log('البلاغات');
r = await call('POST', '/reports', { token: seekerToken, body: { targetType: 'offer', targetId: offerId, reason: 'fake', details: 'يبدو وهميًا' } });
check('إرسال بلاغ', r.status === 201);

r = await call('POST', '/reports', { token: seekerToken, body: { targetType: 'offer', targetId: offerId, reason: 'fake' } });
check('منع تكرار البلاغ', r.status === 409);

r = await call('GET', '/admin/reports', { token: adminToken });
check('البلاغات في لوحة الإدارة', r.json.data?.items?.length === 1);
check('ملخّص الهدف مُرفق', !!r.json.data?.items?.[0]?.target);

// 10. البحث المحفوظ
log('البحث المحفوظ (3.3)');
r = await call('POST', '/saved/searches', { token: seekerToken, body: { label: 'وظائف الإعلام الآلي', criteria: { sector: 'it' } } });
check('حفظ بحث', r.status === 201);

r = await call('GET', '/saved/searches', { token: seekerToken });
check('عدّ النتائج المطابقة', r.json.data?.items?.[0]?.matchCount >= 1);

// 11. المؤسسات
log('المؤسسات (3.8)');
r = await call('GET', '/companies');
check('دليل المؤسسات', r.json.data?.items?.length === 6);
check('عدّ العروض النشطة', r.json.data?.items?.some(c => c.activeOffers > 0));

r = await call('GET', '/companies?verified=true');
check('تصفية الموثّقة فقط', r.json.data?.items?.every(c => c.verificationStatus === 'verified'));

// 12. التوصيات
log('التوصيات (3.9)');
r = await call('GET', '/jobs/recommended', { token: seekerToken });
check('عروض موصى بها', r.status === 200 && r.json.data?.items?.length > 0);

console.log(`\n${'='.repeat(40)}\nنجح: ${pass}   فشل: ${fail}\n${'='.repeat(40)}`);
process.exit(fail ? 1 : 0);
