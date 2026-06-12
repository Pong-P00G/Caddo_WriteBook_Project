<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { BookOpen } from 'lucide-vue-next'
import api from '@/api/Api'
import type { Book, Chapter } from '@/store/types/interface'
import { generateHTML } from '@tiptap/html'
import StarterKit from '@tiptap/starter-kit'
import Image from '@tiptap/extension-image'
import Link from '@tiptap/extension-link'

const route = useRoute()
const slug  = route.params.slug as string

const book           = ref<Book | null>(null)
const activeChapter  = ref<Chapter | null>(null)
const loading        = ref(true)
const error          = ref('')

onMounted(async () => {
  try {
    const { data } = await api.get<{ data: Book }>(`/books/slug/${slug}`)
    book.value = data.data
    if (book.value.chapters.length > 0) {
      activeChapter.value = book.value.chapters[0] ?? null
    }
  } catch {
    error.value = 'Book not found or is not publicly available.'
  } finally {
    loading.value = false
  }
})

function renderContent(content: string): string {
  if (!content) return '<p class="text-ink-300 italic">This chapter has no content yet.</p>'
  try {
    const json = JSON.parse(content)
    return generateHTML(json, [StarterKit, Image, Link])
  } catch {
    return content
  }
}
</script>

<template>
  <div class="min-h-screen bg-parchment">
    <!-- Loading -->
    <div v-if="loading" class="flex items-center justify-center h-screen">
      <div class="animate-spin w-6 h-6 border-2 border-amber-500 border-t-transparent rounded-full" />
    </div>

    <!-- Error -->
    <div v-else-if="error" class="flex flex-col items-center justify-center h-screen text-center px-4">
      <BookOpen :size="40" class="text-ink-200 mb-4" />
      <p class="text-ink-500">{{ error }}</p>
    </div>

    <!-- Book reader -->
    <div v-else-if="book" class="flex h-screen overflow-hidden">
      <!-- Chapter nav sidebar -->
      <aside class="w-64 shrink-0 border-r border-ink-100 overflow-y-auto p-5 bg-white/60 backdrop-blur-sm">
        <h1 class="font-display text-base font-bold text-ink-900 mb-1 leading-snug">{{ book.title }}</h1>
        <p class="text-xs text-ink-400 font-ui mb-5">
          by {{ (book.author as { name: string }).name }}
        </p>

        <nav class="space-y-0.5">
          <button
            v-for="ch in book.chapters"
            :key="ch._id"
            @click="activeChapter = ch"
            class="w-full text-left px-3 py-2 rounded-lg text-sm transition-colors"
            :class="activeChapter?._id === ch._id
              ? 'bg-amber-50 text-amber-700 font-medium'
              : 'text-ink-600 hover:bg-ink-50 hover:text-ink-800'"
          >
            {{ ch.title }}
          </button>
        </nav>
      </aside>

      <!-- Chapter content -->
      <main class="flex-1 overflow-y-auto">
        <div v-if="activeChapter" class="max-w-2xl mx-auto px-8 py-14">
          <h2 class="font-display text-3xl font-bold text-ink-950 mb-8">{{ activeChapter.title }}</h2>
          <div
            class="prose prose-ink max-w-none font-body text-ink-800 leading-relaxed"
            v-html="renderContent(activeChapter.content)"
          />
        </div>
        <div v-else class="flex items-center justify-center h-full text-ink-400">
          Select a chapter to read
        </div>
      </main>
    </div>
  </div>
</template>