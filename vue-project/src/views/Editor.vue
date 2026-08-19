<script setup lang="ts">
import { onMounted, ref, onUnmounted } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { EditorContent } from '@tiptap/vue-3'
import {
  Loader2, Star, Pin, ArrowLeft, ChevronDown, FileDown, FileSpreadsheet,
  History, Sparkles, Palette, FileText, Code2, Upload, Check, Download, Share2,
  Paperclip, BarChart3
} from 'lucide-vue-next'
import { useNotesStore } from '../store/notes'
import { useToast } from '../composable/useToast'
import { useWritebookEditor } from '../composable/Userwritebookeditor'
import { useExportImport } from '../composable/useExportImport'
import { defineAsyncComponent } from 'vue'

const EditorToolbar = defineAsyncComponent(() => import('../components/EditorToolbar.vue'))
const RevisionHistoryDrawer = defineAsyncComponent(() => import('../components/RevisionHistoryDrawer.vue'))
const TemplateGalleryModal = defineAsyncComponent(() => import('../components/TemplateGalleryModal.vue'))
const ShareModal = defineAsyncComponent(() => import('../components/ShareModal.vue'))
const AttachmentsDrawer = defineAsyncComponent(() => import('../components/AttachmentsDrawer.vue'))
const NoteStatsDrawer = defineAsyncComponent(() => import('../components/NoteStatsDrawer.vue'))

const route = useRoute()
const store = useNotesStore()
const toast = useToast()
const { exportMarkdown, exportPlainText, exportHTML, parseImportFile } = useExportImport()

const noteId       = route.params.noteId as string
const noteTitle    = ref('')
const isFavorite   = ref(false)
const isPinned     = ref(false)
const noteColor    = ref<string | null>(null)
const isPublicNote = ref(false)
const noteSlug     = ref<string | null>(null)
const hasPassword  = ref(false)
const viewCount    = ref(0)
const rawContent   = ref('')
const noteCreatedAt= ref('')
const noteUpdatedAt= ref('')
const lastSavedAt  = ref<Date | null>(null)
const savedLabel   = ref('Saved')
let   titleTimer:  ReturnType<typeof setTimeout>
let   clockTimer:  ReturnType<typeof setInterval>

const showHistoryDrawer     = ref(false)
const showTemplateModal     = ref(false)
const showShareModal        = ref(false)
const showAttachmentsDrawer = ref(false)
const showStatsDrawer       = ref(false)
const showColorPicker       = ref(false)
const showExportMenu        = ref(false)
const fileInputRef          = ref<HTMLInputElement | null>(null)

const COLOR_OPTIONS = [
  { id: null, label: 'Default', bg: 'bg-ink-200 dark:bg-ink-700' },
  { id: 'amber', label: 'Amber', bg: 'bg-amber-400' },
  { id: 'emerald', label: 'Emerald', bg: 'bg-emerald-400' },
  { id: 'indigo', label: 'Indigo', bg: 'bg-indigo-400' },
  { id: 'rose', label: 'Rose', bg: 'bg-rose-400' },
  { id: 'sky', label: 'Sky', bg: 'bg-sky-400' },
  { id: 'violet', label: 'Violet', bg: 'bg-violet-400' },
  { id: 'orange', label: 'Orange', bg: 'bg-orange-400' },
  { id: 'slate', label: 'Slate', bg: 'bg-slate-400' },
]

// ── Save status label (updates every 30s) ─────────────────────────────────
function updateSavedLabel() {
  if (!lastSavedAt.value) return
  const diff  = Date.now() - lastSavedAt.value.getTime()
  const mins  = Math.floor(diff / 60_000)
  if (mins < 1)  { savedLabel.value = 'Saved just now'; return }
  if (mins < 60) { savedLabel.value = `Saved ${mins}m ago`; return }
  const hours = Math.floor(mins / 60)
  if (hours < 24) { savedLabel.value = `Saved ${hours}h ago`; return }
  savedLabel.value = `Saved ${Math.floor(hours / 24)}d ago`
}

// ── Content autosave ──────────────────────────────────────────────────────
async function handleSave(content: string) {
  rawContent.value = content
  await store.saveNote(noteId, { content })
  lastSavedAt.value = new Date()
  updateSavedLabel()
}

const { editor, isSaving, setContent } = useWritebookEditor('', handleSave)

onMounted(async () => {
  const note         = await store.fetchNote(noteId)
  noteTitle.value    = note.title
  isFavorite.value   = note.isFavorite
  isPinned.value     = !!note.isPinned
  noteColor.value    = note.color ?? null
  isPublicNote.value = !!note.isPublic
  noteSlug.value     = note.slug ?? null
  hasPassword.value  = !!note.hasPassword
  viewCount.value    = note.viewCount ?? 0
  rawContent.value   = note.content
  noteCreatedAt.value= note.createdAt
  noteUpdatedAt.value= note.updatedAt
  setContent(note.content)

  // initialise saved label from note's server updatedAt
  lastSavedAt.value = new Date(note.updatedAt)
  updateSavedLabel()

  // refresh label every 30 seconds
  clockTimer = setInterval(updateSavedLabel, 30_000)
})

onUnmounted(() => clearInterval(clockTimer))

// ── Title autosave ────────────────────────────────────────────────────────
function scheduleTitleSave() {
  clearTimeout(titleTimer)
  titleTimer = setTimeout(async () => {
    const trimmed = noteTitle.value.trim()
    if (trimmed) {
      await store.saveNote(noteId, { title: trimmed })
      lastSavedAt.value = new Date()
      updateSavedLabel()
    }
  }, 900)
}

function onTitleKeydown(e: KeyboardEvent) {
  if (e.key === 'Enter') {
    e.preventDefault()
    editor.value?.commands.focus()
  }
}

// ── Favorite & Pin toggle ──────────────────────────────────────────────────
async function toggleFavorite() {
  isFavorite.value = !isFavorite.value
  await store.saveNote(noteId, { isFavorite: isFavorite.value })
  lastSavedAt.value = new Date()
  updateSavedLabel()
}

async function togglePin() {
  isPinned.value = !isPinned.value
  await store.saveNote(noteId, { isPinned: isPinned.value })
  lastSavedAt.value = new Date()
  updateSavedLabel()
}

async function selectNoteColor(color: string | null) {
  noteColor.value = color
  showColorPicker.value = false
  await store.saveNote(noteId, { color })
  lastSavedAt.value = new Date()
  updateSavedLabel()
}

// ── Revision restored callback ─────────────────────────────────────────────
function onRevisionRestored(restoredContent: string, restoredTitle: string) {
  noteTitle.value = restoredTitle
  setContent(restoredContent)
  lastSavedAt.value = new Date()
  updateSavedLabel()
}

// ── Export functions ───────────────────────────────────────────────────────
function handleExportMD() {
  const content = editor.value?.getJSON() ? JSON.stringify(editor.value?.getJSON()) : ''
  exportMarkdown(noteTitle.value, content)
  showExportMenu.value = false
}

function handleExportTXT() {
  const content = editor.value?.getJSON() ? JSON.stringify(editor.value?.getJSON()) : ''
  exportPlainText(noteTitle.value, content)
  showExportMenu.value = false
}

function handleExportHTML() {
  const html = editor.value?.getHTML() || ''
  exportHTML(noteTitle.value, html)
  showExportMenu.value = false
}

async function exportToPDF() {
  showExportMenu.value = false
  const { default: jsPDF } = await import('jspdf')
  const { default: autoTable } = await import('jspdf-autotable')
  const doc = new jsPDF()

  // Title
  doc.setFontSize(20)
  doc.setTextColor(26, 26, 26)
  doc.text(noteTitle.value || 'Untitled', 20, 20)

  let yPos = 35
  let hadTables = false

  if (editor.value?.state.schema.nodes.table) {
    editor.value?.state.doc.descendants((node) => {
      if (node.type.name === 'table') {
        const headRows: any[][] = []
        const bodyRows: any[][] = []
        let isHeader = true

        node.descendants((rowNode) => {
          if (rowNode.type.name === 'table_row') {
            const row: any[] = []
            rowNode.descendants((cell) => {
              if (cell.type.name === 'table_cell' || cell.type.name === 'table_header') {
                let cellText = ''
                cell.descendants((inner) => {
                  if (inner.isText) cellText += inner.text
                })
                row.push(cellText)
              }
            })
            if (isHeader) {
              headRows.push(row)
              isHeader = false
            } else {
              bodyRows.push(row)
            }
          }
        })

        autoTable(doc, {
          head: headRows.length > 0 ? headRows : [bodyRows[0] || []],
          body: headRows.length > 0 ? bodyRows : bodyRows.slice(1),
          startY: yPos,
          margin: { left: 20, right: 20 },
          theme: 'grid',
          headStyles: { fillColor: [45, 45, 45], textColor: [255, 255, 255] },
          alternateRowStyles: { fillColor: [245, 245, 245] },
        })
        // @ts-ignore
        yPos = doc.lastAutoTable?.finalY + 15 || yPos + 30
        hadTables = true
      }
    })
  }

  // Plain text if no tables
  if (!hadTables) {
    const content = editor.value?.getText() || ''
    if (content.trim()) {
      doc.setFontSize(12)
      doc.setTextColor(80, 80, 80)
      const lines = doc.splitTextToSize(content, 170)
      doc.text(lines, 20, yPos)
    }
  }

  doc.save(`${noteTitle.value || 'note'}.pdf`)
}

async function exportToExcel() {
  showExportMenu.value = false
  const XLSX = await import('xlsx')
  let data: any[][] = []

  if (editor.value?.state.schema.nodes.table) {
    editor.value?.state.doc.descendants((node) => {
      if (node.type.name === 'table') {
        node.descendants((rowNode) => {
          if (rowNode.type.name === 'table_row') {
            const row: any[] = []
            rowNode.descendants((cell) => {
              if (cell.type.name === 'table_cell' || cell.type.name === 'table_header') {
                let cellText = ''
                cell.descendants((inner) => {
                  if (inner.isText) cellText += inner.text
                })
                row.push(cellText)
              }
            })
            data.push(row)
          }
        })
      }
    })
  }

  // Fallback: plain text
  if (data.length === 0) {
    const text = editor.value?.getText() || ''
    const lines = text.split('\n').filter(l => l.trim())
    data = lines.map(line => [line])
  }

  const ws = XLSX.utils.aoa_to_sheet(data)
  const wb = XLSX.utils.book_new()
  XLSX.utils.book_append_sheet(wb, ws, 'Notes')
  XLSX.writeFile(wb, `${noteTitle.value || 'note'}.xlsx`)
}

// ── File Import ───────────────────────────────────────────────────────────
async function onFileSelected(e: Event) {
  const input = e.target as HTMLInputElement
  if (!input.files || input.files.length === 0) return
  const file = input.files[0]
  try {
    const result = await parseImportFile(file)
    noteTitle.value = result.title
    setContent(result.content)
    await store.saveNote(noteId, { title: result.title, content: result.content })
    lastSavedAt.value = new Date()
    updateSavedLabel()
  } finally {
    input.value = ''
  }
}

// ── Image click handling ──────────────────────────────────────────────────
function handleEditorClick(e: MouseEvent) {
  const target = e.target as HTMLElement
  if (target.tagName === 'IMG' && editor.value) {
    const pos = editor.value.view.posAtDOM(target, 0)
    if (pos !== null) {
      const $pos = editor.value.state.doc.resolve(pos)
      if ($pos.parent.type.name === 'image') {
        const from = pos
        const to = pos + $pos.parent.nodeSize
        editor.value.commands.setTextSelection({ from, to })
      }
    }
  }
}
</script>

<template>
  <div class="h-screen flex flex-col bg-white dark:bg-ink-950">

    <!-- ── Top bar ────────────────────────────────────────── -->
    <header class="flex items-center justify-between px-3 sm:px-6 py-2.5 sm:py-3 bg-white dark:bg-ink-950 shrink-0">
      <!-- Left: back + save status -->
      <div class="flex items-center gap-2 sm:gap-3">
        <RouterLink
          :to="`/app/notes/${noteId}`"
          class="p-1.5 -ml-1 text-ink-400 dark:text-ink-600 hover:text-ink-700 dark:hover:text-ink-300 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
          title="Back to note"
        >
          <ArrowLeft :size="16" />
        </RouterLink>

        <span class="text-xs sm:text-sm font-ui text-ink-400 dark:text-ink-600 flex items-center gap-1.5 truncate max-w-30 sm:max-w-none">
          <Loader2 v-if="isSaving" :size="12" class="animate-spin text-amber-500 shrink-0" />
          {{ isSaving ? 'Saving…' : savedLabel }}
        </span>
      </div>

      <!-- Right actions: Share, Templates, Attachments, Insights, Revisions, Color, Pin, Star, Export -->
      <div class="flex items-center gap-1">
        <!-- Share to Web Button -->
        <button
          @click="showShareModal = true"
          class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-ink-200 dark:border-ink-800 hover:bg-ink-100 dark:hover:bg-ink-800 text-xs font-ui text-ink-600 dark:text-ink-300 transition-colors cursor-pointer"
          :class="isPublicNote ? 'border-amber-400 text-amber-600 dark:text-amber-400 bg-amber-50/40 dark:bg-amber-950/20' : ''"
          title="Share to web"
        >
          <Share2 :size="14" :class="isPublicNote ? 'text-amber-500' : ''" />
          <span class="hidden sm:inline">{{ isPublicNote ? 'Shared' : 'Share' }}</span>
        </button>

        <!-- Starter Templates Button -->
        <button
          @click="showTemplateModal = true"
          class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-ink-200 dark:border-ink-800 hover:bg-ink-100 dark:hover:bg-ink-800 text-xs font-ui text-ink-600 dark:text-ink-300 transition-colors cursor-pointer"
          title="Browse templates"
        >
          <Sparkles :size="14" class="text-amber-500" />
          <span class="hidden sm:inline">Templates</span>
        </button>

        <!-- Attachments Drawer Button -->
        <button
          @click="showAttachmentsDrawer = true"
          class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-ink-200 dark:border-ink-800 hover:bg-ink-100 dark:hover:bg-ink-800 text-xs font-ui text-ink-600 dark:text-ink-300 transition-colors cursor-pointer"
          title="Files & Attachments"
        >
          <Paperclip :size="14" />
          <span class="hidden sm:inline">Files</span>
        </button>

        <!-- Document Stats / Insights Button -->
        <button
          @click="showStatsDrawer = true"
          class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-ink-200 dark:border-ink-800 hover:bg-ink-100 dark:hover:bg-ink-800 text-xs font-ui text-ink-600 dark:text-ink-300 transition-colors cursor-pointer"
          title="Note statistics & outline"
        >
          <BarChart3 :size="14" />
          <span class="hidden sm:inline">Stats</span>
        </button>

        <!-- Version History Button -->
        <button
          @click="showHistoryDrawer = true"
          class="flex items-center gap-1 px-2.5 py-1.5 rounded-lg border border-ink-200 dark:border-ink-800 hover:bg-ink-100 dark:hover:bg-ink-800 text-xs font-ui text-ink-600 dark:text-ink-300 transition-colors cursor-pointer"
          title="Version history"
        >
          <History :size="14" />
          <span class="hidden sm:inline">History</span>
        </button>

        <!-- Note Color Picker Dropdown -->
        <div class="relative">
          <button
            @click="showColorPicker = !showColorPicker"
            class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors text-ink-400 dark:text-ink-500 hover:text-ink-700 dark:hover:text-ink-200 cursor-pointer"
            title="Note color theme"
          >
            <Palette :size="16" />
          </button>

          <!-- Color palette popup -->
          <div
            v-if="showColorPicker"
            class="absolute right-0 top-full mt-1.5 p-2 bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-800 rounded-xl shadow-xl z-50 flex items-center gap-1.5"
          >
            <button
              v-for="c in COLOR_OPTIONS"
              :key="c.id || 'default'"
              @click="selectNoteColor(c.id)"
              class="w-5 h-5 rounded-full flex items-center justify-center transition-transform hover:scale-110"
              :class="[c.bg, noteColor === c.id ? 'ring-2 ring-amber-500 ring-offset-1 dark:ring-offset-ink-900' : '']"
              :title="c.label"
            >
              <Check v-if="noteColor === c.id" :size="11" class="text-white drop-shadow-xs" />
            </button>
          </div>
        </div>

        <!-- Pin Toggle -->
        <button
          @click="togglePin"
          class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors cursor-pointer"
          :title="isPinned ? 'Unpin note' : 'Pin note to top'"
        >
          <Pin
            :size="16"
            :class="isPinned
              ? 'text-amber-500 fill-amber-500 rotate-45 transition-transform'
              : 'text-ink-300 dark:text-ink-700 hover:text-amber-500'"
          />
        </button>

        <!-- Favorite Toggle -->
        <button
          @click="toggleFavorite"
          class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors cursor-pointer"
          :title="isFavorite ? 'Remove from favorites' : 'Add to favorites'"
        >
          <Star
            :size="16"
            :class="isFavorite
              ? 'text-amber-500 fill-amber-500'
              : 'text-ink-300 dark:text-ink-700 hover:text-amber-400'"
          />
        </button>

        <!-- Import Button (hidden input) -->
        <input
          ref="fileInputRef"
          type="file"
          accept=".md,.txt,.markdown"
          class="hidden"
          @change="onFileSelected"
        />
        <button
          @click="fileInputRef?.click()"
          class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors text-ink-300 dark:text-ink-700 hover:text-ink-700 dark:hover:text-ink-300 cursor-pointer"
          title="Import Markdown/Text file"
        >
          <Upload :size="16" />
        </button>

        <!-- Export Menu Dropdown -->
        <div class="relative">
          <button
            @click="showExportMenu = !showExportMenu"
            class="flex items-center gap-0.5 p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors text-ink-400 dark:text-ink-500 hover:text-amber-500 cursor-pointer"
            title="Export options"
          >
            <Download :size="16" />
            <ChevronDown :size="13" />
          </button>

          <!-- Export dropdown menu -->
          <div
            v-if="showExportMenu"
            class="absolute right-0 top-full mt-1.5 w-48 bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-800 rounded-xl shadow-xl z-50 py-1.5 overflow-hidden text-xs font-ui"
          >
            <button
              @click="handleExportMD"
              class="w-full px-3.5 py-2 text-left hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-700 dark:text-ink-200 flex items-center gap-2"
            >
              <Code2 :size="14" class="text-amber-500" />
              <span>Export as Markdown (.md)</span>
            </button>
            <button
              @click="exportToPDF"
              class="w-full px-3.5 py-2 text-left hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-700 dark:text-ink-200 flex items-center gap-2"
            >
              <FileDown :size="14" class="text-rose-500" />
              <span>Export as PDF (.pdf)</span>
            </button>
            <button
              @click="handleExportHTML"
              class="w-full px-3.5 py-2 text-left hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-700 dark:text-ink-200 flex items-center gap-2"
            >
              <FileText :size="14" class="text-sky-500" />
              <span>Export as HTML (.html)</span>
            </button>
            <button
              @click="exportToExcel"
              class="w-full px-3.5 py-2 text-left hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-700 dark:text-ink-200 flex items-center gap-2"
            >
              <FileSpreadsheet :size="14" class="text-emerald-500" />
              <span>Export to Excel (.xlsx)</span>
            </button>
            <button
              @click="handleExportTXT"
              class="w-full px-3.5 py-2 text-left hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-700 dark:text-ink-200 flex items-center gap-2"
            >
              <FileText :size="14" class="text-ink-400" />
              <span>Export as Plain Text (.txt)</span>
            </button>
          </div>
        </div>
      </div>
    </header>

    <!-- Thin divider -->
    <div class="h-px bg-ink-100 dark:bg-ink-800 shrink-0" />

    <!-- ── Toolbar ────────────────────────────────────────── -->
    <div class="px-3 sm:px-6 py-1.5 sm:py-2 border-b border-ink-100 dark:border-ink-800 bg-white dark:bg-ink-950 shrink-0 overflow-x-auto">
      <EditorToolbar :editor="editor" />
    </div>

    <!-- ── Scrollable content ─────────────────────────────── -->
    <div class="flex-1 overflow-y-auto bg-white dark:bg-ink-950">
      <div class="max-w-2xl mx-auto px-4 sm:px-8 pt-6 sm:pt-10 pb-24">

        <!-- Editable title -->
        <input
          v-model="noteTitle"
          @input="scheduleTitleSave"
          @keydown="onTitleKeydown"
          type="text"
          placeholder="Untitled"
          class="w-full mb-6 sm:mb-8 text-2xl sm:text-4xl font-display font-bold text-ink-950 dark:text-ink-50 bg-transparent border-none outline-none placeholder-ink-200 dark:placeholder-ink-700 leading-tight"
        />

        <!-- Tiptap content -->
        <EditorContent :editor="editor" class="min-h-100" @click="handleEditorClick" />
      </div>
    </div>

    <!-- ── Modals & Drawers ───────────────────────────────── -->
    <RevisionHistoryDrawer
      :is-open="showHistoryDrawer"
      :note-id="noteId"
      @close="showHistoryDrawer = false"
      @restored="onRevisionRestored"
    />

    <TemplateGalleryModal
      :is-open="showTemplateModal"
      @close="showTemplateModal = false"
    />

    <ShareModal
      :is-open="showShareModal"
      :note-id="noteId"
      :initial-slug="noteSlug"
      :initial-is-public="isPublicNote"
      :initial-has-password="hasPassword"
      :view-count="viewCount"
      @close="showShareModal = false"
    />

    <AttachmentsDrawer
      :is-open="showAttachmentsDrawer"
      :note-id="noteId"
      @close="showAttachmentsDrawer = false"
    />

    <NoteStatsDrawer
      :is-open="showStatsDrawer"
      :note-title="noteTitle"
      :note-content="rawContent"
      :created-at="noteCreatedAt"
      :updated-at="noteUpdatedAt"
      @close="showStatsDrawer = false"
    />
  </div>
</template>
