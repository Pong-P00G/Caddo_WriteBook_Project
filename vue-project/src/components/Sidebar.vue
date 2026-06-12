<script setup lang="ts">
import { RouterLink, useRoute } from 'vue-router'
import { BookOpen, Library, Settings, PenLine, LogOut } from 'lucide-vue-next'
import { useAuthStore } from '@/store/auth'
import { useRouter } from 'vue-router'

const route  = useRoute()
const router = useRouter()
const auth   = useAuthStore()

const nav = [
  { to: '/app/library', icon: Library,  label: 'Library' },
  { to: '/app/books/new', icon: PenLine, label: 'New Book' },
  { to: '/app/settings', icon: Settings, label: 'Settings' },
]

async function handleLogout() {
  await auth.logout()
  router.push('/login')
}
</script>

<template>
  <aside class="w-60 bg-ink-950 flex flex-col shrink-0 border-r border-ink-900">
    <!-- Logo -->
    <div class="p-5 border-b border-ink-800">
      <RouterLink to="/app/library" class="flex items-center gap-2.5 group">
        <div class="w-8 h-8 bg-amber-500 rounded flex items-center justify-center shrink-0">
          <BookOpen :size="16" class="text-ink-950" />
        </div>
        <span class="font-display text-lg font-bold text-parchment tracking-tight">
          Writebook
        </span>
      </RouterLink>
    </div>

    <!-- Nav -->
    <nav class="flex-1 p-3 space-y-0.5">
      <RouterLink
        v-for="item in nav"
        :key="item.to"
        :to="item.to"
        class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors"
        :class="route.path === item.to
          ? 'bg-ink-800 text-amber-400'
          : 'text-ink-300 hover:bg-ink-800 hover:text-parchment'"
      >
        <component :is="item.icon" :size="16" />
        {{ item.label }}
      </RouterLink>
    </nav>

    <!-- User -->
    <div class="p-3 border-t border-ink-800">
      <div class="flex items-center gap-3 px-3 py-2 mb-1">
        <div class="w-7 h-7 rounded-full bg-amber-500 flex items-center justify-center text-ink-950 text-xs font-bold shrink-0">
          {{ auth.user?.name?.charAt(0).toUpperCase() }}
        </div>
        <span class="text-ink-300 text-sm truncate">{{ auth.user?.name }}</span>
      </div>
      <button
        @click="handleLogout"
        class="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-ink-400 hover:bg-ink-800 hover:text-red-400 transition-colors"
      >
        <LogOut :size="16" />
        Sign out
      </button>
    </div>
  </aside>
</template>