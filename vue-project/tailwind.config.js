/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{vue,js,ts,jsx,tsx}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        ink: {
          50:  '#f5f4f2',
          100: '#e8e6e1',
          200: '#d1cdc4',
          300: '#b3aca0',
          400: '#8f877a',
          500: '#736b5e',
          600: '#5c5449',
          700: '#4a4339',
          800: '#3d382f',
          900: '#2e2921',
          950: '#1a1712',
        },
        amber: {
          50:  '#fdf8ec',
          100: '#faefc9',
          200: '#f4dc8e',
          300: '#edc654',
          400: '#e6b02c',
          500: '#d9941c',
          600: '#bf7015',
          700: '#9b5214',
          800: '#7e4118',
          900: '#6a3618',
          950: '#3d1b09',
        },
        parchment: '#faf7f2',
      },
      fontFamily: {
        display: ['"Playfair Display"', 'Georgia', 'serif'],
        body:    ['"Source Serif 4"', 'Georgia', 'serif'],
        mono:    ['"JetBrains Mono"', 'monospace'],
        ui:      ['"Inter"', 'system-ui', 'sans-serif'],
      },
      typography: (theme) => ({
        ink: {
          css: {
            '--tw-prose-body':         theme('colors.ink.800'),
            '--tw-prose-headings':     theme('colors.ink.950'),
            '--tw-prose-links':        theme('colors.amber.700'),
            '--tw-prose-bold':         theme('colors.ink.900'),
            '--tw-prose-counters':     theme('colors.ink.500'),
            '--tw-prose-bullets':      theme('colors.ink.400'),
            '--tw-prose-hr':           theme('colors.ink.200'),
            '--tw-prose-quotes':       theme('colors.ink.700'),
            '--tw-prose-quote-borders':theme('colors.amber.400'),
            '--tw-prose-code':         theme('colors.ink.800'),
          },
        },
      }),
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
}