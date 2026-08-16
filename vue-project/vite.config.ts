import { fileURLToPath, URL } from "node:url";
import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import vueDevTools from "vite-plugin-vue-devtools";
import tailwindcss from "@tailwindcss/vite";

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue(), vueDevTools(), tailwindcss()],
  server: {
    port: 5001,
    proxy: {
      "/api": {
        target: "http://localhost:3000",
        changeOrigin: true,
      },
      "/uploads": {
        target: "http://localhost:3000",
        changeOrigin: true,
      },
    },
  },
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  build: {
    // Don't generate sourcemaps in production for smaller output
    sourcemap: false,
    // Enable CSS code splitting
    cssCodeSplit: true,
    rollupOptions: {
      output: {
        // Split vendor chunks for better caching + smaller initial bundle
        manualChunks(id) {
          // Tiptap is large (~400KB) — give it its own chunk
          if (id.includes("@tiptap")) {
            return "vendor-tiptap";
          }
          // Lucide icons — separate chunk
          if (id.includes("lucide-vue-next")) {
            return "vendor-lucide";
          }
          // Vue core + router + pinia — small runtime chunk
          if (
            id.includes("node_modules/vue/") ||
            id.includes("node_modules/@vue/") ||
            id.includes("node_modules/pinia") ||
            id.includes("node_modules/vue-router")
          ) {
            return "vendor-vue";
          }
          // Other node_modules
          if (id.includes("node_modules")) {
            return "vendor-misc";
          }
        },
      },
    },
  },
});
