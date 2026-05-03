/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ['./app/**/*.{js,jsx,ts,tsx}', './components/**/*.{js,jsx,ts,tsx}'],
  presets: [require('nativewind/preset')],
  theme: {
    extend: {
      colors: {
        primary: '#659b5e',
        secondary: '#556f44',
        coach: '#283f3b',
        bg: '#F7F6F2',
      },
    },
  },
  plugins: [],
};
