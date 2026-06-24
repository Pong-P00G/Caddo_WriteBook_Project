<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useRouter } from 'vue-router'
import {
  FileText, CalendarDays, Users, CheckSquare,
  BookOpen, Lightbulb, ArrowRight, Loader2, Table2,
} from 'lucide-vue-next'
import { useNotesStore } from '@/store/notes'

const router  = useRouter()
const store   = useNotesStore()
const title   = ref('')
const loading = ref(false)
const error   = ref('')
const selected = ref('blank')

// ── Templates ─────────────────────────────────────────────────────────────────
const templates = [
  {
    id:    'blank',
    icon:  FileText,
    label: 'Blank',
    hint:  'Clean slate',
    title: '',
    content: '',
  },
  {
    id:    'journal',
    icon:  CalendarDays,
    label: 'Daily Journal',
    hint:  'Reflect on your day',
    title: () => `Journal — ${new Date().toLocaleDateString(undefined, { month: 'long', day: 'numeric', year: 'numeric' })}`,
    content: JSON.stringify({
      type: 'doc',
      content: [
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'How was today?' }] },
        { type: 'paragraph' },
        { type: 'heading', attrs: { level: 3 }, content: [{ type: 'text', text: 'Highlights' }] },
        { type: 'bulletList', content: [{ type: 'listItem', content: [{ type: 'paragraph' }] }] },
        { type: 'heading', attrs: { level: 3 }, content: [{ type: 'text', text: 'Gratitude' }] },
        { type: 'bulletList', content: [{ type: 'listItem', content: [{ type: 'paragraph' }] }] },
        { type: 'heading', attrs: { level: 3 }, content: [{ type: 'text', text: "Tomorrow's focus" }] },
        { type: 'bulletList', content: [{ type: 'listItem', content: [{ type: 'paragraph' }] }] },
      ],
    }),
  },
  {
    id:    'meeting',
    icon:  Users,
    label: 'Meeting Notes',
    hint:  'Capture discussions',
    title: '',
    content: JSON.stringify({
      type: 'doc',
      content: [
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Attendees' }] },
        { type: 'bulletList', content: [{ type: 'listItem', content: [{ type: 'paragraph' }] }] },
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Agenda' }] },
        { type: 'bulletList', content: [{ type: 'listItem', content: [{ type: 'paragraph' }] }] },
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Discussion' }] },
        { type: 'paragraph' },
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Action Items' }] },
        { type: 'bulletList', content: [{ type: 'listItem', content: [{ type: 'paragraph' }] }] },
      ],
    }),
  },
  {
    id:    'todo',
    icon:  CheckSquare,
    label: 'Todo List',
    hint:  'Track tasks',
    title: '',
    content: JSON.stringify({
      type: 'doc',
      content: [
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Tasks' }] },
        {
          type: 'bulletList',
          content: [1, 2, 3].map(() => ({
            type: 'listItem',
            content: [{ type: 'paragraph' }],
          })),
        },
      ],
    }),
  },
  {
    id:    'research',
    icon:  Lightbulb,
    label: 'Research',
    hint:  'Organise ideas',
    title: '',
    content: JSON.stringify({
      type: 'doc',
      content: [
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Overview' }] },
        { type: 'paragraph' },
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Key Points' }] },
        { type: 'bulletList', content: [{ type: 'listItem', content: [{ type: 'paragraph' }] }] },
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Sources' }] },
        { type: 'bulletList', content: [{ type: 'listItem', content: [{ type: 'paragraph' }] }] },
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Conclusions' }] },
        { type: 'paragraph' },
      ],
    }),
  },
  {
    id:    'reading',
    icon:  BookOpen,
    label: 'Book Notes',
    hint:  'Capture insights',
    title: '',
    content: JSON.stringify({
      type: 'doc',
      content: [
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Summary' }] },
        { type: 'paragraph' },
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Key Quotes' }] },
        { type: 'blockquote', content: [{ type: 'paragraph' }] },
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'My Takeaways' }] },
        { type: 'bulletList', content: [{ type: 'listItem', content: [{ type: 'paragraph' }] }] },
      ],
    }),
  },
  {
    id:    'spreadsheet',
    icon:  Table2,
    label: 'Spreadsheet',
    hint:  'Table-based data',
    title: '',
    content: JSON.stringify({
      type: 'doc',
      content: [
        { type: 'heading', attrs: { level: 2 }, content: [{ type: 'text', text: 'Data Table' }] },
        { type: 'paragraph' },
        {
          type: 'table',
          content: {
            type: 'table_row',
            content: [
              { type: 'table_cell', content: [{ type: 'paragraph', content: [{ type: 'text', text: 'Item' }] }], attrs: { colspan: 1, rowspan: 1 } },
              { type: 'table_cell', content: [{ type: 'paragraph', content: [{ type: 'text', text: 'Value' }] }], attrs: { colspan: 1, rowspan: 1 } },
              { type: 'table_cell', content: [{ type: 'paragraph', content: [{ type: 'text', text: 'Notes' }] }], attrs: { colspan: 1, rowspan: 1 } },
            ],
          },
        },
        {
          type: 'table',
          content: {
            type: 'table_row',
            content: [
              { type: 'table_cell', content: [{ type: 'paragraph' }], attrs: { colspan: 1, rowspan: 1 } },
              { type: 'table_cell', content: [{ type: 'paragraph' }], attrs: { colspan: 1, rowspan: 1 } },
              { type: 'table_cell', content: [{ type: 'paragraph' }], attrs: { colspan: 1, rowspan: 1 } },
            ],
          },
        },
        {
          type: 'table',
          content: {
            type: 'table_row',
            content: [
              { type: 'table_cell', content: [{ type: 'paragraph' }], attrs: { colspan: 1, rowspan: 1 } },
              { type: 'table_cell', content: [{ type: 'paragraph' }], attrs: { colspan: 1, rowspan: 1 } },
              { type: 'table_cell', content: [{ type: 'paragraph' }], attrs: { colspan: 1, rowspan: 1 } },
            ],
          },
        },
        {
          type: 'table',
          content: {
            type: 'table_row',
            content: [
              { type: 'table_cell', content: [{ type: 'paragraph' }], attrs: { colspan: 1, rowspan: 1 } },
              { type: 'table_cell', content: [{ type: 'paragraph' }], attrs: { colspan: 1, rowspan: 1 } },
              { type: 'table_cell', content: [{ type: 'paragraph' }], attrs: { colspan: 1, rowspan: 1 } },
            ],
          },
        },
      ],
    }),
  },
]

// When a template with a title fn is picked, prefill the title (if title is still empty)
watch(selected, (id) => {
  const tpl = templates.find(t => t.id === id)
  if (!tpl) return
  if (typeof tpl.title === 'function') {
    title.value = tpl.title()
  } else if (tpl.title && !title.value) {
    title.value = tpl.title
  }
})

const activeTemplate = computed(() => templates.find(t => t.id === selected.value)!)
const titleLen = computed(() => title.value.length)
const canCreate = computed(() => title.value.trim().length > 0 && !loading.value)

async function handleCreate() {
  if (!canCreate.value) return
  error.value   = ''
  loading.value = true
  try {
    const payload: { title: string; content?: string } = { title: title.value.trim() }
    if (activeTemplate.value.content) payload.content = activeTemplate.value.content
    const note = await store.createNote(payload)
    router.push(`/app/notes/${note._id}/edit`)
  } catch {
    error.value = 'Something went wrong. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-full flex flex-col items-center justify-center py-10 px-6">
    <div class="w-full max-w-2xl">

      <!-- Heading -->
      <div class="text-center mb-8">
        <h1 class="font-display text-3xl font-bold text-ink-900 dark:text-ink-50 mb-1.5">
          New note
        </h1>
        <p class="text-sm text-ink-400 dark:text-ink-500 font-ui">
          Give it a title, pick a template, start writing.
        </p>
      </div>

      <!-- Title input -->
      <div class="mb-8">
        <div class="relative">
          <input
            v-model="title"
            type="text"
            autofocus
            maxlength="200"
            placeholder="Note title…"
            @keydown.enter="handleCreate"
            class="w-full px-5 py-4 text-2xl font-display font-semibold rounded-2xl border-2 border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-900 text-ink-900 dark:text-ink-50 placeholder-ink-200 dark:placeholder-ink-700 focus:outline-none focus:border-amber-400 dark:focus:border-amber-500 transition-all shadow-sm"
          />
          <!-- Character count -->
          <span
            class="absolute right-4 bottom-3.5 text-xs font-ui tabular-nums transition-opacity"
            :class="titleLen > 180 ? 'text-amber-500 opacity-100' : 'text-ink-300 dark:text-ink-700 opacity-0 group-focus-within:opacity-100'"
            :style="{ opacity: titleLen > 0 ? 1 : 0 }"
          >
            {{ titleLen }}/200
          </span>
        </div>
        <p class="text-xs text-ink-400 dark:text-ink-600 font-ui mt-2 ml-1">
          Press <kbd class="px-1.5 py-0.5 rounded bg-ink-100 dark:bg-ink-800 text-ink-600 dark:text-ink-400 font-mono text-xs border border-ink-200 dark:border-ink-700">Enter</kbd> to create instantly
        </p>
      </div>

      <!-- Templates -->
      <div class="mb-8">
        <p class="text-xs font-ui font-semibold uppercase tracking-wider text-ink-400 dark:text-ink-600 mb-3">
          Start from a template
        </p>
        <div class="grid grid-cols-3 gap-3">
          <button
            v-for="tpl in templates"
            :key="tpl.id"
            type="button"
            @click="selected = tpl.id"
            class="group relative flex flex-col items-start gap-2 p-4 rounded-xl border-2 text-left transition-all duration-150"
            :class="selected === tpl.id
              ? 'border-amber-400 dark:border-amber-500 bg-amber-50 dark:bg-amber-950/30 shadow-sm shadow-amber-200/50 dark:shadow-amber-900/30'
              : 'border-ink-100 dark:border-ink-800 bg-white dark:bg-ink-900 hover:border-ink-300 dark:hover:border-ink-600 hover:shadow-sm'"
          >
            <!-- Selected indicator -->
            <div
              class="absolute top-2.5 right-2.5 w-2 h-2 rounded-full transition-all"
              :class="selected === tpl.id ? 'bg-amber-500 scale-100' : 'scale-0'"
            />

            <div
              class="flex items-center justify-center w-8 h-8 rounded-lg transition-colors"
              :class="selected === tpl.id
                ? 'bg-amber-100 dark:bg-amber-900/50 text-amber-600 dark:text-amber-400'
                : 'bg-ink-100 dark:bg-ink-800 text-ink-500 dark:text-ink-400 group-hover:bg-ink-200 dark:group-hover:bg-ink-700'"
            >
              <component :is="tpl.icon" :size="16" />
            </div>

            <div>
              <p class="text-sm font-ui font-semibold text-ink-800 dark:text-ink-200 leading-none mb-0.5">
                {{ tpl.label }}
              </p>
              <p class="text-xs font-ui text-ink-400 dark:text-ink-600">{{ tpl.hint }}</p>
            </div>
          </button>
        </div>
      </div>

      <!-- Error -->
      <p v-if="error" class="text-sm text-red-600 dark:text-red-400 font-ui mb-4 text-center">
        {{ error }}
      </p>

      <!-- Actions -->
      <div class="flex items-center gap-3">
        <button
          @click="handleCreate"
          :disabled="!canCreate"
          class="flex items-center gap-2 px-7 py-3 rounded-xl font-ui font-semibold text-sm transition-all disabled:opacity-40 disabled:cursor-not-allowed"
          :class="canCreate
            ? 'bg-amber-500 hover:bg-amber-600 text-ink-950 shadow-md shadow-amber-500/25 hover:shadow-lg hover:shadow-amber-500/30 hover:-translate-y-px'
            : 'bg-amber-500 text-ink-950'"
        >
          <Loader2 v-if="loading" :size="15" class="animate-spin" />
          <ArrowRight v-else :size="15" />
          {{ loading ? 'Creating…' : 'Create & Write' }}
        </button>

        <button
          type="button"
          @click="router.back()"
          class="px-5 py-3 text-ink-500 dark:text-ink-400 hover:text-ink-800 dark:hover:text-ink-200 font-ui text-sm transition-colors"
        >
          Cancel
        </button>
      </div>
    </div>
  </div>
</template>
