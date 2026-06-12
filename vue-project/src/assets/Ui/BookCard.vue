<script setup lang="ts">
import { RouterLink } from 'vue-router'
import { BookOpen, Globe, Lock, Archive } from 'lucide-vue-next'
import type { Book } from '@/store/types/interface'
import { formatDistanceToNow } from 'date-fns'

defineProps<{ book: Book }>()

const visibilityIcon = { public: Globe, unlisted: Globe, private: Lock, archived: Archive }
const statusColor = {
  draft:     'text-ink-400 bg-ink-100',
  published: 'text-green-700 bg-green-50',
  archived:  'text-ink-400 bg-ink-50',
}
</script>

<template>
  <RouterLink
    :to="`/app/books/${book._id}`"
    class="group flex flex-col gap-3 p-5 bg-white rounded-xl border border-ink-100 hover:border-amber-300 hover:shadow-sm transition-all duration-200"
  >
    <!-- Cover / placeholder -->
    <div class="w-full aspect-[3/2] rounded-lg overflow-hidden bg-gradient-to-br from-ink-100 to-ink-200 flex items-center justify-center">
      <img v-if="book.cover" :src="book.cover" :alt="book.title" class="w-full h-full object-cover" />
      <BookOpen v-else :size="32" class="text-ink-300" />
    </div>

    <!-- Meta -->
    <div class="flex-1 min-w-0">
      <div class="flex items-start justify-between gap-2 mb-1">
        <h3 class="font-display font-semibold text-ink-900 group-hover:text-amber-700 transition-colors line-clamp-2 leading-snug">
          {{ book.title }}
        </h3>
        <component
          :is="visibilityIcon[book.visibility]"
          :size="14"
          class="text-ink-300 shrink-0 mt-0.5"
        />
      </div>

      <p v-if="book.description" class="text-sm text-ink-500 line-clamp-2 mb-3">
        {{ book.description }}
      </p>

      <div class="flex items-center justify-between">
        <span class="text-xs px-2 py-0.5 rounded-full font-ui" :class="statusColor[book.status]">
          {{ book.status }}
        </span>
        <span class="text-xs text-ink-400 font-ui">
          {{ formatDistanceToNow(new Date(book.updatedAt), { addSuffix: true }) }}
        </span>
      </div>
    </div>
  </RouterLink>
</template>