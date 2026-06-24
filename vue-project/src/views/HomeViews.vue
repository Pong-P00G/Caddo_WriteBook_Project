<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { BookOpen, PenLine, Sparkles, Lock, Zap } from 'lucide-vue-next'
import { useAuthStore } from '@/store/auth'

const auth = useAuthStore()

const features = [
  { icon: PenLine,   title: 'Distraction-free',  desc: 'Clean editor that gets out of your way.' },
  { icon: Sparkles,  title: 'Rich formatting',   desc: 'Headings, lists, code, quotes and more.' },
  { icon: Lock,      title: 'Your data, private', desc: 'Self-hosted. No tracking, no ads.' },
  { icon: Zap,       title: 'Instant autosave',   desc: 'Your work is always saved as you type.' },
]
</script>

<template>
  <div class="min-h-screen bg-parchment dark:bg-ink-950 flex flex-col">
    <!-- Nav -->
    <header class="max-w-5xl mx-auto w-full px-6 py-5 flex justify-between items-center">
      <div class="flex items-center gap-2.5">
        <div class="w-8 h-8 rounded-lg bg-amber-500 flex items-center justify-center">
          <BookOpen :size="16" class="text-ink-950" />
        </div>
        <span class="font-display text-xl font-bold text-ink-900 dark:text-ink-50 tracking-tight">Caddo Notes</span>
      </div>

      <nav class="flex items-center gap-2">
        <template v-if="!auth.isAuthenticated">
          <RouterLink
            to="/login"
            class="px-4 py-2 text-sm font-ui font-medium text-ink-600 dark:text-ink-400 hover:text-ink-900 dark:hover:text-ink-100 transition-colors"
          >
            Sign in
          </RouterLink>
          <RouterLink
            to="/register"
            class="px-4 py-2 text-sm font-ui font-semibold bg-amber-500 hover:bg-amber-600 text-ink-950 rounded-lg transition-colors"
          >
            Get started free
          </RouterLink>
        </template>
        <RouterLink
          v-else
          to="/app/notes"
          class="px-4 py-2 text-sm font-ui font-semibold bg-amber-500 hover:bg-amber-600 text-ink-950 rounded-lg transition-colors"
        >
          Open my notes →
        </RouterLink>
      </nav>
    </header>

    <!-- Hero -->
    <main class="flex-1 flex flex-col items-center justify-center text-center px-6 py-16">
      <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-amber-100 dark:bg-amber-950/50 text-amber-700 dark:text-amber-400 text-xs font-ui font-medium mb-8">
        <Sparkles :size="12" />
        Minimal · Personal · Self-hosted
      </div>

      <h1 class="font-display text-5xl md:text-7xl font-bold text-ink-950 dark:text-ink-50 mb-6 leading-tight tracking-tight max-w-3xl">
        Your thoughts,<br />
        <span class="text-amber-500">beautifully kept</span>
      </h1>

      <p class="text-lg text-ink-600 dark:text-ink-400 mb-10 max-w-lg leading-relaxed font-body">
        A calm, distraction-free space to write, think and organise — built for people who love writing.
      </p>

      <RouterLink
        :to="auth.isAuthenticated ? '/app/notes/new' : '/register'"
        class="inline-flex items-center gap-2.5 px-8 py-4 bg-ink-900 dark:bg-amber-500 hover:bg-ink-800 dark:hover:bg-amber-600 text-white dark:text-ink-950 rounded-xl font-ui font-semibold text-base transition-all hover:-translate-y-0.5 shadow-lg shadow-ink-900/20 dark:shadow-amber-500/20"
      >
        <PenLine :size="18" />
        Start writing — it's free
      </RouterLink>

      <!-- Feature grid -->
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mt-20 max-w-3xl w-full">
        <div
          v-for="f in features"
          :key="f.title"
          class="flex flex-col items-center gap-2 p-5 rounded-xl bg-white dark:bg-ink-900 border border-ink-100 dark:border-ink-800 text-center"
        >
          <component :is="f.icon" :size="20" class="text-amber-500" />
          <p class="text-sm font-ui font-semibold text-ink-800 dark:text-ink-200">{{ f.title }}</p>
          <p class="text-xs text-ink-500 dark:text-ink-400 font-body leading-relaxed">{{ f.desc }}</p>
        </div>
      </div>
    </main>

    <!-- Footer -->
    <footer class="text-center pb-8">
      <p class="text-xs text-ink-400 dark:text-ink-600 font-ui">Made with ♥ · Caddo Notes</p>
    </footer>
  </div>
</template>
