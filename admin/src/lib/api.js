// عميل الـ API للوحة الإدارة
const BASE = '/api';
const TOKEN_KEY = 'admin_token';

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token) {
  if (token) localStorage.setItem(TOKEN_KEY, token);
  else localStorage.removeItem(TOKEN_KEY);
}

export class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

async function request(method, path, body, query) {
  const url = new URL(BASE + path, window.location.origin);
  if (query) {
    Object.entries(query).forEach(([k, v]) => {
      if (v !== undefined && v !== null && v !== '') url.searchParams.set(k, v);
    });
  }

  const token = getToken();
  let res;
  try {
    res = await fetch(url, {
      method,
      headers: {
        ...(body ? { 'Content-Type': 'application/json' } : {}),
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
      },
      body: body ? JSON.stringify(body) : undefined,
    });
  } catch {
    throw new ApiError(0, 'تعذّر الاتصال بالخادم');
  }

  let json = {};
  try {
    json = await res.json();
  } catch {
    throw new ApiError(res.status, 'ردّ غير صالح من الخادم');
  }

  if (!res.ok) {
    // الجلسة منتهية: نُخرج المستخدم
    if (res.status === 401) setToken(null);
    throw new ApiError(res.status, json.message || 'حدث خطأ');
  }

  return json.data ?? json;
}

export const api = {
  get: (path, query) => request('GET', path, null, query),
  post: (path, body) => request('POST', path, body),
  patch: (path, body) => request('PATCH', path, body),
  delete: (path, body) => request('DELETE', path, body),
};

export function fileUrl(path) {
  if (!path) return null;
  return path.startsWith('http') ? path : path;
}
