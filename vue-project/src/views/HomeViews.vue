<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { BookOpen, PenLine } from 'lucide-vue-next'
import { useAuthStore } from '@/store/auth'

const auth = useAuthStore()
</script>

<template>
  <div class="min-h-screen bg-parchment flex flex-col">
    <!-- Header -->
    <header class="p-6 flex justify-between items-center">
      <div class="flex items-center gap-2">
        <div class="w-8 h-8 rounded-lg bg-amber-500 flex items-center justify-center text-ink-950">
          <BookOpen :size="18" />
        </div>
        <span class="font-display font-bold text-xl text-ink-900 tracking-tight">Caddo WriteBook</span>
      </div>
      <div class="flex gap-4" v-if="!auth.isAuthenticated">
        <RouterLink to="/login" class="text-ink-600 hover:text-ink-900 font-ui font-medium px-4 py-2 transition-colors">
          Log in
        </RouterLink>
        <RouterLink to="/register" class="bg-amber-500 hover:bg-amber-600 text-ink-950 font-ui font-medium px-4 py-2 rounded-lg transition-colors">
          Get Started
        </RouterLink>
      </div>
      <div class="flex gap-4" v-else>
        <RouterLink to="/app/library" class="bg-amber-500 hover:bg-amber-600 text-ink-950 font-ui font-medium px-4 py-2 rounded-lg transition-colors">
          Go to Library
        </RouterLink>
      </div>
    </header>

    <!-- Hero -->
    <main class="flex-1 flex flex-col items-center justify-center text-center px-4">
      <div class="max-w-3xl mx-auto">
        <h1 class="font-display text-5xl md:text-7xl font-bold text-ink-950 mb-6 tracking-tight">
          Write your next <br /> <span class="text-amber-600">masterpiece</span>
        </h1>
        <p class="text-lg text-ink-600 mb-10 max-w-xl mx-auto leading-relaxed">
          The minimalist, distraction-free writing platform that helps you focus on what matters most: your words.
        </p>
        
        <RouterLink
          :to="auth.isAuthenticated ? '/app/books/new' : '/register'"
          class="inline-flex items-center gap-2 px-8 py-4 bg-ink-900 hover:bg-ink-800 text-white rounded-xl font-ui font-medium text-lg transition-all hover:-translate-y-0.5 shadow-xl shadow-ink-900/10"
        >
          <PenLine :size="20" />
          Start Writing Now
        </RouterLink>
      </div>
    </main>
  </div>
</template>