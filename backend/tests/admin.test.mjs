// يتحقّق من أن كل نداء تستعمله لوحة الإدارة يعمل فعلًا
const BASE = 'http://127.0.0.1:5000/api';
let pass = 0, fail = 0;

async function call(method, path, { token, body } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: {
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  return { status: res.status, json: await res.json().catch(() => ({})) };
}

function check(name, cond, extra = '') {
  if (cond) { pass++; console.log(`  ✓ ${name}`); }
  else { fail++; console.log(`  ✗ ${name} ${extra}`); }
}

console.log('=== مسارات لوحة الإدارة ===');

let r = await call('POST', '/auth/login', {
  body: { identifier: '0550000000', password: 'admin123456' },
});
const token = r.json.data?.token;
check('دخول المشرف', r.status === 200 && !!token);
check('الدور = admin', r.json.data?.user?.role === 'admin');

// كل صفحة من اللوحة
r = await call('GET', '/admin/stats', { token });
check('GET /admin/stats', r.status === 200 && r.json.data?.users);

r = await call('GET', '/admin/offers?status=pending&page=1', { token });
check('GET /admin/offers', r.status === 200 && Array.isArray(r.json.data?.items));
check('ترقيم الصفحات موجود', !!r.json.data?.pagination?.pages);

r = await call('GET', '/admin/users?page=1', { token });
check('GET /admin/users', r.status === 200 && r.json.data?.items?.length > 0);

r = await call('GET', '/admin/users?role=company&q=' + encodeURIComponent('مسؤول'), { token });
check('بحث وتصفية المستخدمين', r.status === 200 && r.json.data.items.every(u => u.role === 'company'));

r = await call('GET', '/admin/companies?verificationStatus=verified', { token });
check('GET /admin/companies', r.status === 200 && r.json.data.items.every(c => c.verificationStatus === 'verified'));

r = await call('GET', '/admin/reports?status=all', { token });
check('GET /admin/reports', r.status === 200 && Array.isArray(r.json.data?.items));

r = await call('GET', '/admin/banners', { token });
check('GET /admin/banners', r.status === 200 && r.json.data?.items?.length >= 1);

// دورة حياة اللافتة كما تفعلها الصفحة
r = await call('POST', '/admin/banners', {
  token, body: { title: 'لافتة اختبار', subtitle: 'فرعي', ctaLabel: 'اضغط', active: true, order: 5 },
});
const bannerId = r.json.data?.banner?._id;
check('POST /admin/banners', r.status === 201 && !!bannerId);

r = await call('PATCH', `/admin/banners/${bannerId}`, { token, body: { active: false } });
check('PATCH /admin/banners/:id', r.status === 200 && r.json.data?.banner?.active === false);

r = await call('DELETE', `/admin/banners/${bannerId}`, { token });
check('DELETE /admin/banners/:id', r.status === 200);

// تعليق مستخدم ثم إعادة تفعيله
// الحساب المزروع تحديدًا: كلمة مروره معروفة (seeker123456)
r = await call('GET', '/admin/users?q=0555121456', { token });
const seeker = r.json.data.items.find(u => u.phone === '0555121456');
if (seeker) {
  r = await call('PATCH', `/admin/users/${seeker._id}/status`, {
    token, body: { status: 'suspended', reason: 'اختبار' },
  });
  check('تعليق حساب', r.status === 200 && r.json.data?.user?.status === 'suspended');

  r = await call('POST', '/auth/login', {
    body: { identifier: seeker.phone, password: 'seeker123456' },
  });
  check('الحساب المعلّق ممنوع من الدخول', r.status === 403);

  r = await call('PATCH', `/admin/users/${seeker._id}/status`, {
    token, body: { status: 'active' },
  });
  check('إعادة تفعيل الحساب', r.status === 200 && r.json.data?.user?.status === 'active');
} else {
  console.log('  (تخطّي اختبار التعليق — لا يوجد باحث نشط)');
}

// منع تعليق حساب مشرف
r = await call('GET', '/admin/users?role=admin', { token });
const adminUser = r.json.data.items[0];
r = await call('PATCH', `/admin/users/${adminUser._id}/status`, {
  token, body: { status: 'suspended' },
});
check('منع تعليق حساب مشرف', r.status === 403);

// إبراز عرض (العرض المميّز)
r = await call('GET', '/admin/offers?status=approved', { token });
const offer = r.json.data.items.find(o => !o.featured);
if (offer) {
  r = await call('PATCH', `/admin/offers/${offer._id}/feature`, {
    token, body: { featured: true, days: 15 },
  });
  check('إبراز عرض', r.status === 200 && r.json.data?.offer?.featured === true);

  r = await call('PATCH', `/admin/offers/${offer._id}/feature`, {
    token, body: { featured: false },
  });
  check('إلغاء الإبراز', r.status === 200 && r.json.data?.offer?.featured === false);
}

// حماية: رمز غير صالح
r = await call('GET', '/admin/stats', { token: 'invalid.token.here' });
check('رفض رمز غير صالح', r.status === 401);

console.log(`\n${'='.repeat(40)}\nنجح: ${pass}   فشل: ${fail}\n${'='.repeat(40)}`);
process.exit(fail ? 1 : 0);
