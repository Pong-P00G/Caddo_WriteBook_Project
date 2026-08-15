<script setup lang="ts">
import { onMounted, ref, onUnmounted } from 'vue'
import { useRoute, RouterLink } from 'vue-router'
import { EditorContent } from '@tiptap/vue-3'
import { Loader2, Star, ArrowLeft, ChevronDown, FileDown, FileSpreadsheet } from 'lucide-vue-next'
import { useNotesStore } from '../store/notes'
import { useWritebookEditor } from '../composable/Userwritebookeditor'
import { defineAsyncComponent } from 'vue'
const EditorToolbar = defineAsyncComponent(() => import('../components/EditorToolbar.vue'))

const route = useRoute()
const store = useNotesStore()

const noteId       = route.params.noteId as string
const noteTitle    = ref('')
const isFavorite   = ref(false)
const lastSavedAt  = ref<Date | null>(null)
const savedLabel   = ref('Saved')
let   titleTimer:  ReturnType<typeof setTimeout>
let   clockTimer:  ReturnType<typeof setInterval>

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
  await store.saveNote(noteId, { content })
  lastSavedAt.value = new Date()
  updateSavedLabel()
}

const { editor, isSaving, setContent } = useWritebookEditor('', handleSave)

onMounted(async () => {
  const note      = await store.fetchNote(noteId)
  noteTitle.value = note.title
  isFavorite.value = note.isFavorite
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

// ── Favorite toggle ───────────────────────────────────────────────────────
async function toggleFavorite() {
  isFavorite.value = !isFavorite.value
  await store.saveNote(noteId, { isFavorite: isFavorite.value })
  lastSavedAt.value = new Date()
  updateSavedLabel()
}

// ── Export functions ───────────────────────────────────────────────────────
async function exportToPDF() {
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

// ── Image click handling ──────────────────────────────────────────────────
function handleEditorClick(e: MouseEvent) {
  const target = e.target as HTMLElement
  if (target.tagName === 'IMG' && editor.value) {
    // Find the position of the image in the document
    const pos = editor.value.view.posAtDOM(target, 0)
    if (pos !== null) {
      // Set selection to cover the image node
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
    <header class="flex items-center justify-between px-6 py-3 bg-white dark:bg-ink-950 shrink-0">
      <!-- Left: back + save status -->
      <div class="flex items-center gap-3">
        <RouterLink
          :to="`/app/notes/${noteId}`"
          class="text-ink-400 dark:text-ink-600 hover:text-ink-700 dark:hover:text-ink-300 transition-colors"
          title="Back to note"
        >
          <ArrowLeft :size="16" />
        </RouterLink>

        <span class="text-sm font-ui text-ink-400 dark:text-ink-600 flex items-center gap-1.5">
          <Loader2 v-if="isSaving" :size="12" class="animate-spin text-amber-500" />
          {{ isSaving ? 'Saving…' : savedLabel }}
        </span>
      </div>

      <!-- Right: star + chevron + export -->
      <div class="flex items-center gap-1.5">
        <button
          @click="exportToExcel"
          class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors text-ink-300 dark:text-ink-700 hover:text-amber-500"
          title="Export to Excel"
        >
          <FileSpreadsheet :size="16" />
        </button>
        <button
          @click="exportToPDF"
          class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors text-ink-300 dark:text-ink-700 hover:text-amber-500"
          title="Export to PDF"
        >
          <FileDown :size="16" />
        </button>
        <button
          @click="toggleFavorite"
          class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
          :title="isFavorite ? 'Remove from favorites' : 'Add to favorites'"
        >
          <Star
            :size="16"
            :class="isFavorite
              ? 'text-amber-500 fill-amber-500'
              : 'text-ink-300 dark:text-ink-700 hover:text-amber-400'"
          />
        </button>
        <button class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors text-ink-300 dark:text-ink-700 hover:text-ink-600 dark:hover:text-ink-400">
          <ChevronDown :size="16" />
        </button>
      </div>
    </header>

    <!-- Thin divider -->
    <div class="h-px bg-ink-100 dark:bg-ink-800 shrink-0" />

    <!-- ── Toolbar ────────────────────────────────────────── -->
    <div class="px-6 py-2 border-b border-ink-100 dark:border-ink-800 bg-white dark:bg-ink-950 shrink-0">
      <EditorToolbar :editor="editor" />
    </div>

    <!-- ── Scrollable content ─────────────────────────────── -->
    <div class="flex-1 overflow-y-auto bg-white dark:bg-ink-950">
      <div class="max-w-2xl mx-auto px-8 pt-10 pb-24">

        <!-- Editable title -->
        <input
          v-model="noteTitle"
          @input="scheduleTitleSave"
          @keydown="onTitleKeydown"
          type="text"
          placeholder="Untitled"
          class="w-full mb-8 text-4xl font-display font-bold text-ink-950 dark:text-ink-50 bg-transparent border-none outline-none placeholder-ink-200 dark:placeholder-ink-700 leading-tight"
        />

        <!-- Tiptap content -->
        <EditorContent :editor="editor" class="min-h-100" @click="handleEditorClick" />
      </div>
    </div>
  </div>
</template>
