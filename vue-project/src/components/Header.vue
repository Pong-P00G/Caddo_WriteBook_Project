<script setup lang="ts">
import { useRoute } from 'vue-router'

const route = useRoute()

const titles: Record<string, string> = {
  '/app/library':      'My Library',
  '/app/books/new':    'New Book',
  '/app/settings':     'Settings',
}

const title = () => titles[route.path] ?? 'Writebook'
</script>

<template>
  <header class="h-14 border-b border-ink-100 flex items-center px-6 bg-parchment/80 backdrop-blur-sm sticky top-0 z-10">
    <h1 class="font-display text-lg font-semibold text-ink-900">{{ title() }}</h1>
  </header>
</template>