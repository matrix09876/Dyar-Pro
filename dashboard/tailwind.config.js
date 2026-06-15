/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        // وفق Dyar Ultra UI Handoff: Noto Sans Arabic + Inter فقط
        sans: ['"Noto Sans Arabic"', 'Inter', 'system-ui', 'sans-serif'],
      },
      colors: {
        // Dyar brand — برتقالي ديار (من التطبيق الحالي + Figma handoff)
        brand: {
          50: '#fff4ed', 100: '#ffe6d5', 200: '#feccaa', 300: '#fda874',
          400: '#fb7a3c', 500: '#f4691e', 600: '#e04e12', 700: '#ba3a11',
          800: '#943016', 900: '#772a15', 950: '#401208',
        },
        ink: { DEFAULT: '#1a1a1f', muted: '#6b7280' },
        surface: { dark: '#15151a', card: '#1e1e25' },
      },
      minHeight: { cta: '52px' },   // أهداف لمس ≥44px وفق الـ QA spec
    },
  },
  plugins: [],
};
