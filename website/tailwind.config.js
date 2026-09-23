/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        // نفس هوية التطبيق: أزرق كحلي + ذهبي
        navy: {
          DEFAULT: '#0B3C87',
          dark: '#062A63',
          light: '#1D5FBF',
          soft: '#EAF1FC',
        },
        gold: {
          DEFAULT: '#F5B301',
          light: '#FFD34E',
          dark: '#C98F00',
        },
      },
      fontFamily: {
        sans: ['Cairo', 'Segoe UI', 'Tahoma', 'sans-serif'],
      },
      keyframes: {
        'fade-up': {
          '0%': { opacity: '0', transform: 'translateY(18px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        float: {
          '0%,100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-10px)' },
        },
        'pulse-ring': {
          '0%': { transform: 'scale(0.9)', opacity: '0.7' },
          '100%': { transform: 'scale(1.6)', opacity: '0' },
        },
      },
      animation: {
        'fade-up': 'fade-up 0.6s ease-out both',
        float: 'float 5s ease-in-out infinite',
        'pulse-ring': 'pulse-ring 2.4s ease-out infinite',
      },
    },
  },
  plugins: [],
};
