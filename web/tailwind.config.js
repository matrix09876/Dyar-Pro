/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: { sans: ['"Noto Sans Arabic"', 'Inter', 'system-ui', 'sans-serif'] },
      colors: {
        brand: {
          50: '#fff4ed', 100: '#ffe6d5', 400: '#fb7a3c',
          500: '#f4691e', 600: '#e04e12', 700: '#ba3a11', 950: '#401208',
        },
      },
    },
  },
  plugins: [],
};
