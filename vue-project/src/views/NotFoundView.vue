<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <div class="min-h-screen bg-parchment flex flex-col items-center justify-center text-center px-4">
    <p class="text-8xl mb-6">📄</p>
    <h1 class="font-display text-4xl font-bold text-ink-900 mb-3">Page not found</h1>
    <p class="text-ink-500 mb-8">This page doesn't exist or has been moved.</p>
    <RouterLink
      to="/"
      class="px-5 py-2.5 bg-amber-500 hover:bg-amber-600 text-ink-950 rounded-lg font-ui font-semibold text-sm transition-colors"
    >
      Go home
    </RouterLink>
  </div>
</template>