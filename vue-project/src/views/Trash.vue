<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { RotateCcw, Trash2 } from 'lucide-vue-next'
import api from '@/api/Api'
import type { Note, ApiResponse } from '@/store/types/interface'

const notes   = ref<Note[]>([])
const loading = ref(false)

async function fetchTrash() {
  loading.value = true
  try {
    const { data } = await api.get<ApiResponse<Note[]>>('/notes/trash')
    notes.value = data.data
  } finally {
    loading.value = false
  }
}

async function restore(id: string) {
  await api.post(`/notes/${id}/restore`)
  notes.value = notes.value.filter(n => n._id !== id)
}

async function permanentDelete(id: string) {
  await api.delete(`/notes/${id}/permanent`)
  notes.value = notes.value.filter(n => n._id !== id)
}

onMounted(fetchTrash)

function relativeTime(d?: string | null): string {
  if (!d) return ''
  const diff = Date.now() - new Date(d).getTime()
  const days = Math.floor(diff / 86_400_000)
  if (days < 1) return 'Today'
  if (days === 1) return 'Yesterday'
  return `${days} days ago`
}
</script>

<template>
  <div class="flex flex-col h-full bg-white dark:bg-ink-950">

    <!-- Top bar -->
    <div class="flex items-center justify-between px-8 py-3 shrink-0">
      <span class="text-sm text-ink-400 dark:text-ink-600 font-ui">
        {{ loading ? '…' : `${notes.length} item${notes.length !== 1 ? 's' : ''} in trash` }}
      </span>
    </div>
    <div class="h-px bg-ink-200 dark:bg-ink-800 shrink-0" />

    <!-- Content -->
    <div class="flex-1 overflow-y-auto">
      <div class="max-w-2xl mx-auto px-8 py-8">

        <!-- Loading -->
        <div v-if="loading" class="space-y-px">
          <div v-for="n in 4" :key="n" class="h-14 bg-ink-100 dark:bg-ink-800 rounded-lg animate-pulse" :style="{ opacity: 1 - n * 0.2 }" />
        </div>

        <!-- Empty -->
        <div v-else-if="notes.length === 0" class="flex flex-col items-center justify-center py-24 text-center">
          <Trash2 :size="32" class="text-ink-200 dark:text-ink-700 mb-4" />
          <p class="font-display text-lg font-semibold text-ink-500 dark:text-ink-500 mb-1">Trash is empty</p>
          <p class="text-sm text-ink-400 dark:text-ink-600">Deleted notes will appear here.</p>
        </div>

        <!-- List -->
        <ul v-else class="space-y-px">
          <li
            v-for="note in notes"
            :key="note._id"
            class="group flex items-center gap-4 px-3 py-3 rounded-lg hover:bg-ink-50 dark:hover:bg-ink-900 transition-colors"
          >
            <div class="flex-1 min-w-0">
              <p class="text-sm font-ui font-medium text-ink-700 dark:text-ink-300 truncate line-through decoration-ink-300 dark:decoration-ink-600">
                {{ note.title || 'Untitled' }}
              </p>
              <p class="text-xs text-ink-400 dark:text-ink-600 font-ui mt-0.5">
                Deleted {{ relativeTime(note.deletedAt) }}
              </p>
            </div>

            <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
              <button
                @click="restore(note._id)"
                class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-ui font-medium text-ink-600 dark:text-ink-400 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                title="Restore"
              >
                <RotateCcw :size="12" />
                Restore
              </button>
              <button
                @click="permanentDelete(note._id)"
                class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg text-xs font-ui font-medium text-red-500 hover:bg-red-50 dark:hover:bg-red-950/20 transition-colors"
                title="Delete permanently"
              >
                <Trash2 :size="12" />
                Delete
              </button>
            </div>
          </li>
        </ul>

        <!-- Info -->
        <p v-if="notes.length > 0" class="text-xs text-ink-300 dark:text-ink-700 font-ui mt-8 text-center">
          Notes in trash are permanently deleted after 30 days.
        </p>
      </div>
    </div>
  </div>
</template>
