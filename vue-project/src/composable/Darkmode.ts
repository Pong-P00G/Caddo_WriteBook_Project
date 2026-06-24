import { ref, watchEffect } from "vue";

type Theme = "light" | "dark";

export function useDarkMode() {
  const getInitialTheme = (): Theme => {
    const stored = localStorage.getItem("wb_theme") as Theme;
    if (stored === "light" || stored === "dark") return stored;
    return window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark"
      : "light";
  };

  const theme = ref<Theme>(getInitialTheme());

  watchEffect(() => {
    if (theme.value === "dark") {
      document.documentElement.classList.add("dark");
    } else {
      document.documentElement.classList.remove("dark");
    }
    localStorage.setItem("wb_theme", theme.value);
  });

  const toggle = () => {
    theme.value = theme.value === "light" ? "dark" : "light";
  };

  return { theme, toggle };
}
