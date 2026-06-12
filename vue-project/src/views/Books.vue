<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { Plus, Pencil, Trash2, GripVertical, Globe, Lock, Eye } from 'lucide-vue-next'
import { useBooksStore } from '@/store/books'

const route  = useRoute()
const router = useRouter()
const store  = useBooksStore()

const bookId       = route.params.bookId as string
const newChapterTitle = ref('')
const addingChapter   = ref(false)
const deletingChapter = ref<string | null>(null)

onMounted(() => store.fetchBook(bookId))

async function handleAddChapter() {
  if (!newChapterTitle.value.trim()) return
  const chapter = await store.createChapter(bookId, newChapterTitle.value.trim())
  newChapterTitle.value = ''
  addingChapter.value   = false
  router.push(`/app/books/${bookId}/chapters/${chapter._id}/edit`)
}

async function handleDeleteChapter(chapterId: string) {
  deletingChapter.value = chapterId
  await store.deleteChapter(bookId, chapterId)
  deletingChapter.value = null
}

async function handlePublish() {
  if (!store.activeBook) return
  const newStatus = store.activeBook.status === 'published' ? 'draft' : 'published'
  await store.updateBook(bookId, { status: newStatus })
}
</script>

<template>
  <div class="p-6 max-w-3xl mx-auto">
    <!-- Book loading skeleton -->
    <div v-if="store.loading && !store.activeBook" class="animate-pulse space-y-4">
      <div class="h-8 bg-ink-100 rounded w-1/2" />
      <div class="h-4 bg-ink-100 rounded w-3/4" />
    </div>

    <template v-else-if="store.activeBook">
      <!-- Header -->
      <div class="mb-8">
        <div class="flex items-start justify-between gap-4 mb-2">
          <h1 class="font-display text-3xl font-bold text-ink-950">{{ store.activeBook.title }}</h1>
          <div class="flex items-center gap-2 shrink-0">
            <!-- Publish toggle -->
            <button
              @click="handlePublish"
              class="flex items-center gap-1.5 px-3.5 py-2 rounded-lg text-sm font-ui font-medium transition-colors"
              :class="store.activeBook.status === 'published'
                ? 'bg-green-50 text-green-700 hover:bg-green-100'
                : 'bg-ink-100 text-ink-600 hover:bg-ink-200'"
            >
              <Globe v-if="store.activeBook.status === 'published'" :size="14" />
              <Lock v-else :size="14" />
              {{ store.activeBook.status === 'published' ? 'Published' : 'Publish' }}
            </button>

            <!-- Read link (if published) -->
            <RouterLink
              v-if="store.activeBook.status === 'published'"
              :to="`/read/${store.activeBook.slug}`"
              class="flex items-center gap-1.5 px-3.5 py-2 rounded-lg bg-amber-500 hover:bg-amber-600 text-ink-950 text-sm font-ui font-medium transition-colors"
            >
              <Eye :size="14" />
              Preview
            </RouterLink>
          </div>
        </div>
        <p v-if="store.activeBook.description" class="text-ink-500">
          {{ store.activeBook.description }}
        </p>
        <p class="text-sm text-ink-400 font-ui mt-2">
          {{ store.activeBook.wordCount.toLocaleString() }} words ·
          {{ store.activeBook.chapters.length }} chapters
        </p>
      </div>

      <!-- Chapters -->
      <div class="mb-4">
        <h2 class="font-display text-lg font-semibold text-ink-800 mb-3">Chapters</h2>

        <!-- Empty -->
        <p v-if="store.activeBook.chapters.length === 0" class="text-ink-400 text-sm italic py-4">
          No chapters yet. Add your first one below.
        </p>

        <!-- Chapter list -->
        <ul class="space-y-1.5">
          <li
            v-for="chapter in store.activeBook.chapters"
            :key="chapter._id"
            class="group flex items-center gap-3 p-3 rounded-lg border border-ink-100 bg-white hover:border-amber-200 transition-colors"
          >
            <GripVertical :size="16" class="text-ink-300 cursor-grab shrink-0" />

            <span class="text-xs font-mono text-ink-300 w-5 text-right shrink-0">
              {{ chapter.order + 1 }}
            </span>

            <span class="flex-1 font-body text-ink-800 truncate">{{ chapter.title }}</span>

            <span class="text-xs text-ink-400 font-ui shrink-0">
              {{ chapter.wordCount.toLocaleString() }}w
            </span>

            <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
              <RouterLink
                :to="`/app/books/${bookId}/chapters/${chapter._id}/edit`"
                class="p-1.5 rounded hover:bg-amber-50 text-ink-400 hover:text-amber-700 transition-colors"
              >
                <Pencil :size="14" />
              </RouterLink>
              <button
                @click="handleDeleteChapter(chapter._id)"
                :disabled="deletingChapter === chapter._id"
                class="p-1.5 rounded hover:bg-red-50 text-ink-400 hover:text-red-600 transition-colors disabled:opacity-50"
              >
                <Trash2 :size="14" />
              </button>
            </div>
          </li>
        </ul>
      </div>

      <!-- Add chapter -->
      <div v-if="addingChapter" class="flex items-center gap-2">
        <input
          v-model="newChapterTitle"
          type="text"
          placeholder="Chapter title…"
          autofocus
          @keyup.enter="handleAddChapter"
          @keyup.esc="addingChapter = false"
          class="flex-1 px-3.5 py-2.5 rounded-lg border border-amber-400 bg-white text-ink-900 font-ui text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent"
        />
        <button
          @click="handleAddChapter"
          class="px-4 py-2.5 bg-amber-500 hover:bg-amber-600 text-ink-950 rounded-lg font-ui font-medium text-sm transition-colors"
        >
          Add
        </button>
        <button
          @click="addingChapter = false"
          class="px-4 py-2.5 text-ink-500 hover:text-ink-700 font-ui text-sm transition-colors"
        >
          Cancel
        </button>
      </div>

      <button
        v-else
        @click="addingChapter = true"
        class="flex items-center gap-2 px-4 py-2.5 rounded-lg border-2 border-dashed border-ink-200 hover:border-amber-400 text-ink-400 hover:text-amber-600 font-ui text-sm transition-all w-full justify-center"
      >
        <Plus :size="16" />
        Add Chapter
      </button>
    </template>
  </div>
</template>