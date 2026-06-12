<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { EditorContent } from '@tiptap/vue-3'
import { ArrowLeft, CheckCircle2, Loader2 } from 'lucide-vue-next'
import { useBooksStore } from '@/store/books'
import { useWritebookEditor } from '@/composable/Userwritebookeditor'
import EditorToolbar from '@/components/EditorToolbar.vue'

const route  = useRoute()
const router = useRouter()
const store  = useBooksStore()

const bookId    = route.params.bookId as string
const chapterId = route.params.chapterId as string
const chapterTitle = ref('')

async function handleSave(content: string) {
  await store.saveChapter(bookId, chapterId, content)
}

const { editor, wordCount, isSaving, setContent } = useWritebookEditor('', handleSave)

onMounted(async () => {
  const chapter = await store.fetchChapter(bookId, chapterId)
  chapterTitle.value = chapter.title
  setContent(chapter.content)
})
</script>

<template>
  <div class="h-screen flex flex-col bg-parchment">
    <!-- Editor header -->
    <header class="flex items-center justify-between px-5 py-3 border-b border-ink-100 bg-parchment/90 backdrop-blur-sm sticky top-0 z-10">
      <div class="flex items-center gap-4">
        <RouterLink
          :to="`/app/books/${bookId}`"
          class="flex items-center gap-1.5 text-sm text-ink-500 hover:text-ink-800 transition-colors"
        >
          <ArrowLeft :size="16" />
          Back
        </RouterLink>
        <div class="h-4 w-px bg-ink-200" />
        <h2 class="font-display font-semibold text-ink-800 truncate max-w-xs">{{ chapterTitle }}</h2>
      </div>

      <div class="flex items-center gap-3">
        <!-- Autosave indicator -->
        <span class="flex items-center gap-1.5 text-xs text-ink-400 font-ui">
          <Loader2 v-if="isSaving" :size="13" class="animate-spin" />
          <CheckCircle2 v-else :size="13" class="text-green-500" />
          {{ isSaving ? 'Saving…' : 'Saved' }}
        </span>
        <span class="text-xs text-ink-400 font-ui">{{ wordCount.toLocaleString() }} words</span>
      </div>
    </header>

    <!-- Toolbar -->
    <div class="px-5 py-2 border-b border-ink-100 bg-white/60 backdrop-blur-sm">
      <EditorToolbar :editor="editor" />
    </div>

    <!-- Content area -->
    <div class="flex-1 overflow-y-auto">
      <div class="max-w-2xl mx-auto px-6 py-12">
        <EditorContent :editor="editor" class="min-h-full" />
      </div>
    </div>
  </div>
</template>