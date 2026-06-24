<script setup lang="ts">
import { RouterView } from 'vue-router'
import { useAuthStore } from './store/auth'
import { useDarkMode } from './composable/Darkmode'

const authStore = useAuthStore()
authStore.init()

// Apply saved theme immediately (before first render)
useDarkMode()
</script>

<template>
  <div class="min-h-screen bg-ink-100 dark:bg-ink-950 text-ink-800 dark:text-ink-200 font-ui">
    <router-view />
  </div>
</template>
