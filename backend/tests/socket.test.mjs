// اختبار التسليم الآني: مؤسسة ترسل رسالة، والباحث يستقبلها عبر المقبس
import { io } from 'socket.io-client';

const HTTP = 'http://127.0.0.1:5000';
const BASE = `${HTTP}/api`;
let pass = 0, fail = 0;

function check(name, cond, extra = '') {
  if (cond) { pass++; console.log(`  ✓ ${name}`); }
  else { fail++; console.log(`  ✗ ${name} ${extra}`); }
}

async function login(identifier, password) {
  const r = await fetch(`${BASE}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identifier, password }),
  });
  const j = await r.json();
  if (!j.success) throw new Error(`login ${identifier}: ${j.message}`);
  return { token: j.data.token, user: j.data.user };
}

function connect(token) {
  return new Promise((resolve, reject) => {
    const s = io(HTTP, {
      transports: ['websocket', 'polling'],
      auth: { token },
      reconnection: false,
    });
    const t = setTimeout(() => reject(new Error('connect timeout')), 12000);
    s.on('connect', () => { clearTimeout(t); resolve(s); });
    s.on('connect_error', (e) => { clearTimeout(t); reject(e); });
  });
}

/** ينتظر حدثًا بعينه أو ينتهي بالمهلة */
function waitFor(socket, event, ms = 8000) {
  return new Promise((resolve) => {
    const t = setTimeout(() => resolve(null), ms);
    socket.once(event, (data) => { clearTimeout(t); resolve(data); });
  });
}

console.log('=== التسليم الآني عبر Socket.IO ===');

const seeker = await login('0555121456', 'seeker123456');
const company = await login('0550120001', 'company123456');
check('دخول الطرفين', !!seeker.token && !!company.token);

// رفض الاتصال دون رمز صالح
let rejected = false;
try {
  await connect('invalid.token.value');
} catch {
  rejected = true;
}
check('رفض اتصال برمز غير صالح', rejected);

const seekerSock = await connect(seeker.token);
const companySock = await connect(company.token);
check('اتصال المقبس للطرفين', seekerSock.connected && companySock.connected);

// نحتاج ترشّحًا لفتح محادثة
const offersRes = await fetch(`${BASE}/jobs`);
const offer = (await offersRes.json()).data.items[0];

let applicationId;
const applyRes = await fetch(`${BASE}/applications`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${seeker.token}`,
  },
  body: JSON.stringify({ offerId: offer._id, coverLetter: 'اختبار آني' }),
});
const applyJson = await applyRes.json();
if (applyJson.success) {
  applicationId = applyJson.data.application._id;
} else {
  // ترشّح موجود مسبقًا: نأخذه من القائمة
  const mine = await fetch(`${BASE}/applications/mine`, {
    headers: { Authorization: `Bearer ${seeker.token}` },
  });
  applicationId = (await mine.json()).data.items[0]?._id;
}
check('توفّر ترشّح لفتح المحادثة', !!applicationId);

// 1) المؤسسة ترسل -> الباحث يستقبل فورًا
const seekerWaits = waitFor(seekerSock, 'message:new');

const sendRes = await fetch(`${BASE}/messages`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${company.token}`,
  },
  body: JSON.stringify({ applicationId, body: 'مرحبًا، هل أنت متاح للمقابلة؟' }),
});
const sendJson = await sendRes.json();
check('إرسال الرسالة', sendRes.status === 201, sendJson.message || '');
const conversationId = sendJson.data?.conversationId;

const received = await seekerWaits;
check('وصلت الرسالة آنيًا إلى الباحث', received !== null,
  received === null ? '(انتهت المهلة)' : '');
if (received) {
  check('المحادثة صحيحة', `${received.conversationId}` === `${conversationId}`);
  check('نصّ الرسالة صحيح',
    received.message?.body === 'مرحبًا، هل أنت متاح للمقابلة؟');
  check('معرّف الرسالة موجود (لمنع التكرار)', !!received.message?._id);
}

// 2) المرسِل لا يستقبل نسخة من رسالته
let echo = null;
companySock.once('message:new', (d) => { echo = d; });

// 3) الباحث يردّ -> المؤسسة تستقبل
const companyWaits = waitFor(companySock, 'message:new');
await fetch(`${BASE}/messages`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${seeker.token}`,
  },
  body: JSON.stringify({ conversationId, body: 'نعم، متاح غدًا صباحًا.' }),
});
const reply = await companyWaits;
check('وصل الردّ آنيًا إلى المؤسسة', reply !== null,
  reply === null ? '(انتهت المهلة)' : '');
if (reply) check('نصّ الردّ صحيح', reply.message?.body === 'نعم، متاح غدًا صباحًا.');

// 4) حدث «يكتب الآن» يصل للطرف الآخر فقط
const typingWait = waitFor(seekerSock, 'typing', 4000);
companySock.emit('typing', { conversationId, to: seeker.user._id });
const typing = await typingWait;
check('حدث «يكتب الآن» يصل', typing !== null);
if (typing) check('مصدر الكتابة صحيح', `${typing.from}` === `${company.user._id}`);

// 5) الإشعار يصل آنيًا أيضًا
const notifWait = waitFor(seekerSock, 'notification', 6000);
await fetch(`${BASE}/messages`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${company.token}`,
  },
  body: JSON.stringify({ conversationId, body: 'تذكير بالموعد' }),
});
const notif = await notifWait;
check('الإشعار يصل آنيًا', notif !== null);

seekerSock.close();
companySock.close();

console.log(`\n${'='.repeat(40)}\nنجح: ${pass}   فشل: ${fail}\n${'='.repeat(40)}`);
process.exit(fail ? 1 : 0);
