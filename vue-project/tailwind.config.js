/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        ink: {
          50: "#f8f8f8",
          100: "#f0f0f0",
          200: "#e2e2e2",
          300: "#c8c8c8",
          400: "#a0a0a0",
          500: "#7a7a7a",
          600: "#5a5a5a",
          700: "#3a3a3a",
          800: "#262626",
          900: "#171717",
          950: "#0d0d0d",
        },
        amber: {
          50: "#fdf8ec",
          100: "#faefc9",
          200: "#f4dc8e",
          300: "#edc654",
          400: "#e6b02c",
          500: "#d9941c",
          600: "#bf7015",
          700: "#9b5214",
          800: "#7e4118",
          900: "#6a3618",
          950: "#3d1b09",
        },
      },
      fontFamily: {
        display: ['"Playfair Display"', "Georgia", "serif"],
        body: ['"Source Serif 4"', "Georgia", "serif"],
        mono: ['"JetBrains Mono"', "monospace"],
        ui: ['"Inter"', "system-ui", "sans-serif"],
      },
      boxShadow: {
        card: "0 1px 3px 0 rgb(0 0 0 / 0.06), 0 1px 2px -1px rgb(0 0 0 / 0.06)",
        popover: "0 4px 6px -1px rgb(0 0 0 / 0.10), 0 2px 4px -2px rgb(0 0 0 / 0.10)",
        modal: "0 10px 15px -3px rgb(0 0 0 / 0.10), 0 4px 6px -4px rgb(0 0 0 / 0.10)",
        "card-hover": "0 4px 12px 0 rgb(0 0 0 / 0.08), 0 2px 4px -2px rgb(0 0 0 / 0.06)",
        "inner-sm": "inset 0 1px 2px 0 rgb(0 0 0 / 0.05)",
      },
      borderRadius: {
        "card": "12px",
        "dialog": "16px",
        "chip": "8px",
        "pill": "9999px",
      },
      transitionDuration: {
        fast: "120ms",
        base: "200ms",
        slow: "350ms",
      },
      transitionTimingFunction: {
        bounce: "cubic-bezier(0.34, 1.56, 0.64, 1)",
        smooth: "cubic-bezier(0.4, 0, 0.2, 1)",
      },
      spacing: {
        "4.5": "1.125rem",
        "13": "3.25rem",
        "15": "3.75rem",
        "18": "4.5rem",
      },
      scale: {
        "101": "1.01",
        "102": "1.02",
      },
      typography: (theme) => ({
        ink: {
          css: {
            "--tw-prose-body": theme("colors.ink.700"),
            "--tw-prose-headings": theme("colors.ink.900"),
            "--tw-prose-links": theme("colors.amber.600"),
            "--tw-prose-bold": theme("colors.ink.800"),
            "--tw-prose-counters": theme("colors.ink.400"),
            "--tw-prose-bullets": theme("colors.ink.400"),
            "--tw-prose-hr": theme("colors.ink.200"),
            "--tw-prose-quotes": theme("colors.ink.600"),
            "--tw-prose-quote-borders": theme("colors.ink.300"),
            "--tw-prose-code": theme("colors.ink.700"),
          },
        },
      }),
    },
  },
  plugins: [require("@tailwindcss/typography")],
};
