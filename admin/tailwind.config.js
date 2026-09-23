/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        // هوية لوحة الإدارة: بنفسجي-نيلي، مختلف عن أزرق الباحث
        // وأخضر المؤسسة، ليعرف المستخدم فورًا أنه في لوحة التحكّم.
        admin: {
          DEFAULT: '#4F46E5',
          dark: '#4338CA',
          light: '#6366F1',
          soft: '#EEF2FF',
        },
        // ألوان الشريط الجانبي الداكن
        sidebar: {
          DEFAULT: '#0F172A',
          hover: '#1E293B',
          border: '#1E293B',
        },
      },
      fontFamily: {
        sans: ['Cairo', 'Segoe UI', 'Tahoma', 'sans-serif'],
        mono: ['ui-monospace', 'SFMono-Regular', 'Menlo', 'monospace'],
      },
      boxShadow: {
        card: '0 1px 3px rgba(15,23,42,0.06), 0 1px 2px rgba(15,23,42,0.04)',
        lifted: '0 10px 30px rgba(15,23,42,0.10)',
      },
      keyframes: {
        'fade-up': {
          '0%': { opacity: '0', transform: 'translateY(8px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        'pulse-dot': {
          '0%,100%': { opacity: '1' },
          '50%': { opacity: '0.35' },
        },
      },
      animation: {
        'fade-up': 'fade-up 0.35s ease-out both',
        'pulse-dot': 'pulse-dot 1.8s ease-in-out infinite',
      },
    },
  },
  plugins: [],
};
