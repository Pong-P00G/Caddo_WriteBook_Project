<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import { StickyNote } from 'lucide-vue-next'
import api from '@/api/Api'
import type { Note } from '@/store/types/interface'
import { generateHTML } from '@tiptap/html'
import StarterKit from '@tiptap/starter-kit'
import Image from '@tiptap/extension-image'
import Link from '@tiptap/extension-link'

const route   = useRoute()
const noteId  = route.params.noteId as string

const note    = ref<Note | null>(null)
const loading = ref(true)
const error   = ref('')

onMounted(async () => {
  try {
    const { data } = await api.get<{ success: boolean; data: Note }>(`/notes/${noteId}`)
    note.value = data.data
  } catch {
    error.value = 'Note not found or is not publicly available.'
  } finally {
    loading.value = false
  }
})

function renderContent(content: string): string {
  if (!content) return '<p class="text-ink-300 italic">This note has no content yet.</p>'
  try {
    return generateHTML(JSON.parse(content), [StarterKit, Image, Link])
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
      <StickyNote :size="40" class="text-ink-200 mb-4" />
      <p class="text-ink-500">{{ error }}</p>
    </div>

    <!-- Note reader -->
    <div v-else-if="note" class="max-w-2xl mx-auto px-8 py-14">
      <h1 class="font-display text-4xl font-bold text-ink-950 mb-4 leading-tight">{{ note.title }}</h1>
      <p class="text-sm text-ink-400 font-ui mb-10">
        {{ new Date(note.updatedAt).toLocaleDateString(undefined, { month: 'long', day: 'numeric', year: 'numeric' }) }}
      </p>
      <div
        class="prose prose-ink max-w-none font-body text-ink-800 leading-relaxed"
        v-html="renderContent(note.content)"
      />
    </div>
  </div>
</template>
