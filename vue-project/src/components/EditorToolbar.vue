<script setup lang="ts">
import type { Editor } from '@tiptap/vue-3'
import {
  Bold, Italic, Underline, Strikethrough, Code, Code2, Heading1, Heading2,
  Heading3, List, ListOrdered, Quote, Minus, Undo, Redo, AlignLeft,
  AlignCenter, AlignRight, AlignJustify, Highlighter, Subscript, Superscript,
  CheckSquare, Image, Link2, X, Check, ExternalLink, Trash2,
  ChevronLeft, ChevronRight, Table2, Plus, Minus as MinusIcon
} from 'lucide-vue-next'
import { ref, computed, watch, nextTick } from 'vue'

const props = defineProps<{ editor: Editor | undefined }>()

// ── Highlight colors ──────────────────────────────────────────────────────
const HIGHLIGHT_COLORS = [
  '#ffff00', '#ffcc00', '#ff9900', '#ff6666',
  '#66ff66', '#00ffff', '#6699ff', '#cc99ff',
  '#ff99cc', '#cccccc', '#ffffff', '#000000',
]
const IMAGE_ALIGN_OPTIONS = [
  { v: 'left', icon: AlignLeft },
  { v: 'center', icon: AlignCenter },
  { v: 'right', icon: AlignRight },
] as const
const showHighlightPopup = ref(false)
const selectedHighlightColor = ref('#ffff00')

// ── Table popup state ──────────────────────────────────────────────────────
const showTablePopup = ref(false)
const isTableActive = ref(false)

function checkTableSelection() {
  if (!props.editor) return false
  return props.editor.isActive('table')
}

function toggleTablePopup() {
  isTableActive.value = checkTableSelection()
  showTablePopup.value = !showTablePopup.value
  showLinkPopup.value = false
  showImagePopup.value = false
  showHighlightPopup.value = false
}

function closeTablePopup() {
  showTablePopup.value = false
}

function insertTable() {
  props.editor?.chain().focus().insertTable({ rows: 3, cols: 3, withHeaderRow: true }).run()
  showTablePopup.value = false
}

function addColumn() {
  props.editor?.chain().focus().addColumnAfter().run()
}

function deleteColumn() {
  props.editor?.chain().focus().deleteColumn().run()
}

function addRow() {
  props.editor?.chain().focus().addRowAfter().run()
}

function deleteRow() {
  props.editor?.chain().focus().deleteRow().run()
}

function toggleHeaderRow() {
  props.editor?.chain().focus().toggleHeaderRow().run()
}

function deleteTable() {
  props.editor?.chain().focus().deleteTable().run()
  showTablePopup.value = false
}

// ── Image popup state ──────────────────────────────────────────────────────
const showImagePopup = ref(false)
const imagePopupPos = ref({ top: 0, left: 0 })
const editingAlt = ref(false)
const altText = ref('')
const imageWidth = ref<'25%' | '50%' | '75%' | '100%'>('100%')
const imageAlign = ref<'left' | 'center' | 'right'>('center')
const isImageSelected = ref(false)

// Check if an image node is currently selected
function checkImageSelection() {
  if (!props.editor) return false
  const { from, to } = props.editor.state.selection
  // Check if selection is collapsed and inside an image
  const isImg = props.editor.isActive('image')
  // Also check if the selection range covers an image node
  const $from = props.editor.state.doc.resolve(from)
  const node = $from.parent
  if (node.type.name === 'image') {
    return true
  }
  return isImg
}

// ── Link popup state ───────────────────────────────────────────────────────
const showLinkPopup = ref(false)
const linkUrl = ref('')
const linkText = ref('')
const linkNewTab = ref(false)
const linkInputEl = ref<HTMLInputElement | null>(null)

// ── Image upload ───────────────────────────────────────────────────────────
const fileInput = ref<HTMLInputElement | null>(null)

function openImagePicker() {
  // If image is already selected, open the edit popup instead
  if (checkImageSelection()) {
    openImagePopup()
    return
  }
  fileInput.value?.click()
}

function handleImageUpload(event: Event) {
  const target = event.target as HTMLInputElement
  const file = target.files?.[0]
  if (!file || !props.editor) return

  if (!file.type.startsWith('image/')) {
    alert('Please select an image file.')
    return
  }

  const reader = new FileReader()
  reader.onload = (e) => {
    const base64 = e.target?.result as string
    props.editor?.chain().focus().setImage({ src: base64, alt: file.name }).run()
  }
  reader.readAsDataURL(file)
  target.value = ''
}

// ── Link functions ─────────────────────────────────────────────────────────
function openLinkPopup() {
  const { href, target } = props.editor?.getAttributes('link') ?? {}
  linkUrl.value = href ?? ''
  linkText.value = props.editor?.state.selection.empty ? '' : props.editor?.getText() ?? ''
  linkNewTab.value = target === '_blank'
  showLinkPopup.value = true
  showImagePopup.value = false
  nextTick(() => linkInputEl.value?.focus())
}

function applyLink() {
  if (!linkUrl.value.trim()) {
    props.editor?.chain().focus().unsetLink().run()
  } else {
    props.editor?.chain().focus().setLink({
      href: linkUrl.value,
      target: linkNewTab.value ? '_blank' : undefined,
    }).run()
  }
  closeLinkPopup()
}

function removeLink() {
  props.editor?.chain().focus().unsetLink().run()
  closeLinkPopup()
}

function closeLinkPopup() {
  showLinkPopup.value = false
  linkUrl.value = ''
  linkText.value = ''
  linkNewTab.value = false
}

// ── Image popup functions ──────────────────────────────────────────────────
function openImagePopup() {
  const attrs = props.editor?.getAttributes('image')
  if (!attrs) return
  altText.value = attrs.alt ?? ''
  imageWidth.value = (attrs.width === '25%' ? '25%' :
                      attrs.width === '50%' ? '50%' :
                      attrs.width === '75%' ? '75%' : '100%') as any
  imageAlign.value = (attrs.align === 'left' ? 'left' :
                      attrs.align === 'right' ? 'right' : 'center') as any
  showImagePopup.value = true
  showLinkPopup.value = false
}

function closeImagePopup() {
  showImagePopup.value = false
  editingAlt.value = false
}

function setImageWidth(w: typeof imageWidth.value) {
  imageWidth.value = w
  props.editor?.chain().focus().updateAttributes('image', { width: w }).run()
}

function setImageAlign(a: typeof imageAlign.value) {
  imageAlign.value = a
  props.editor?.chain().focus().updateAttributes('image', { align: a }).run()
}

function saveAltText() {
  props.editor?.chain().focus().updateAttributes('image', { alt: altText.value }).run()
  editingAlt.value = false
}

function deleteImage() {
  props.editor?.chain().focus().deleteNode('image').run()
  closeImagePopup()
}

// ── Track image and table selection ──────────────────────────────────────────
watch(() => props.editor?.state.selection, () => {
  if (!props.editor) return
  const { from, to } = props.editor.state.selection
  if (from === undefined || to === undefined) return

  isImageSelected.value = checkImageSelection()
  isTableActive.value = checkTableSelection()
  
  if (!isImageSelected.value && showImagePopup.value) {
    showImagePopup.value = false
  }
  
  if (!isTableActive.value && showTablePopup.value) {
    showTablePopup.value = false
  }
})
watch(() => props.editor?.state.selection, () => {
  if (!props.editor) return
  const { from, to } = props.editor.state.selection
  if (from === undefined || to === undefined) return

  isImageSelected.value = checkImageSelection()
  
  if (!isImageSelected.value && showImagePopup.value) {
    showImagePopup.value = false
  }
})

// ── Highlight functions ───────────────────────────────────────────────────
function toggleHighlightPopup() {
  showHighlightPopup.value = !showHighlightPopup.value
  showLinkPopup.value = false
  showImagePopup.value = false
}

function applyHighlight(color: string) {
  props.editor?.chain().focus().toggleHighlight({ color }).run()
  showHighlightPopup.value = false
}

function removeHighlight() {
  props.editor?.chain().focus().unsetHighlight().run()
  showHighlightPopup.value = false
}

// ── Toolbar tools ──────────────────────────────────────────────────────────
const tools = [
  { icon: Bold,          title: 'Bold (Ctrl+B)',          action: () => props.editor?.chain().focus().toggleBold().run(),                   isActive: () => !!props.editor?.isActive('bold') },
  { icon: Italic,        title: 'Italic (Ctrl+I)',        action: () => props.editor?.chain().focus().toggleItalic().run(),                 isActive: () => !!props.editor?.isActive('italic') },
  { icon: Underline,     title: 'Underline (Ctrl+U)',     action: () => props.editor?.chain().focus().toggleUnderline().run(),              isActive: () => !!props.editor?.isActive('underline') },
  { icon: Strikethrough, title: 'Strikethrough',          action: () => props.editor?.chain().focus().toggleStrike().run(),                 isActive: () => !!props.editor?.isActive('strike') },
  null,
  { icon: Code,          title: 'Inline code',            action: () => props.editor?.chain().focus().toggleCode().run(),                   isActive: () => !!props.editor?.isActive('code') },
  { icon: Code2,         title: 'Code block',             action: () => props.editor?.chain().focus().toggleCodeBlock().run(),              isActive: () => !!props.editor?.isActive('codeBlock') },
  null,
  { icon: Heading1,      title: 'Heading 1',              action: () => props.editor?.chain().focus().toggleHeading({ level: 1 }).run(),    isActive: () => !!props.editor?.isActive('heading', { level: 1 }) },
  { icon: Heading2,      title: 'Heading 2',              action: () => props.editor?.chain().focus().toggleHeading({ level: 2 }).run(),    isActive: () => !!props.editor?.isActive('heading', { level: 2 }) },
  { icon: Heading3,      title: 'Heading 3',              action: () => props.editor?.chain().focus().toggleHeading({ level: 3 }).run(),    isActive: () => !!props.editor?.isActive('heading', { level: 3 }) },
  null,
  { icon: List,          title: 'Bullet list',            action: () => props.editor?.chain().focus().toggleBulletList().run(),             isActive: () => !!props.editor?.isActive('bulletList') },
  { icon: ListOrdered,   title: 'Numbered list',          action: () => props.editor?.chain().focus().toggleOrderedList().run(),            isActive: () => !!props.editor?.isActive('orderedList') },
  { icon: CheckSquare,   title: 'Checklist',              action: () => props.editor?.chain().focus().toggleTaskList().run(),              isActive: () => !!props.editor?.isActive('taskList') },
  { icon: Quote,         title: 'Blockquote',             action: () => props.editor?.chain().focus().toggleBlockquote().run(),             isActive: () => !!props.editor?.isActive('blockquote') },
  { icon: Minus,         title: 'Divider',                action: () => props.editor?.chain().focus().setHorizontalRule().insertContentAt(props.editor.state.selection.anchor, { type: 'paragraph' }).focus().run(),            isActive: () => false },
  null,
  { icon: AlignLeft,     title: 'Align left',             action: () => props.editor?.chain().focus().setTextAlign('left').run(),           isActive: () => props.editor?.isActive({ textAlign: 'left' }) },
  { icon: AlignCenter,   title: 'Align center',           action: () => props.editor?.chain().focus().setTextAlign('center').run(),         isActive: () => props.editor?.isActive({ textAlign: 'center' }) },
  { icon: AlignRight,    title: 'Align right',            action: () => props.editor?.chain().focus().setTextAlign('right').run(),          isActive: () => props.editor?.isActive({ textAlign: 'right' }) },
  { icon: AlignJustify,  title: 'Justify',                action: () => props.editor?.chain().focus().setTextAlign('justify').run(),        isActive: () => props.editor?.isActive({ textAlign: 'justify' }) },
  null,
  { icon: Highlighter,   title: 'Highlight',              action: toggleHighlightPopup,                                                  isActive: () => !!props.editor?.isActive('highlight') },
  { icon: Subscript,     title: 'Subscript',              action: () => props.editor?.chain().focus().toggleSubscript().run(),              isActive: () => !!props.editor?.isActive('subscript') },
  { icon: Superscript,   title: 'Superscript',            action: () => props.editor?.chain().focus().toggleSuperscript().run(),            isActive: () => !!props.editor?.isActive('superscript') },
  null,
  { icon: Link2,         title: 'Link',                   action: openLinkPopup,                                                            isActive: () => !!props.editor?.isActive('link') },
  { icon: Image,         title: 'Insert / Edit image',    action: openImagePicker,                                                          isActive: () => isImageSelected.value },
  { icon: Table2,        title: 'Table options',            action: toggleTablePopup,                                                    isActive: () => isTableActive.value },
  null,
  { icon: Undo,          title: 'Undo (Ctrl+Z)',          action: () => props.editor?.chain().focus().undo().run(),                        isActive: () => false },
  { icon: Redo,          title: 'Redo (Ctrl+Shift+Z)',    action: () => props.editor?.chain().focus().redo().run(),                        isActive: () => false },
]
</script>

<template>
  <div class="relative">
    <div class="flex items-center gap-0.5 flex-wrap">
      <!-- Hidden file input for image upload -->
      <input
        ref="fileInput"
        type="file"
        accept="image/*"
        class="hidden"
        @change="handleImageUpload"
      />
      <template v-for="(tool, i) in tools">
        <div
          v-if="tool === null"
          :key="`separator-${i}`"
          class="w-px h-4 bg-ink-200 dark:bg-ink-700 mx-1.5"
        />
        <button
          v-else
          :key="`tool-${i}`"
          @click="tool.action()"
          :title="tool.title"
          class="p-1.5 rounded transition-colors"
          :class="tool.isActive()
            ? 'bg-amber-100 dark:bg-amber-900/40 text-amber-700 dark:text-amber-400'
            : 'text-ink-400 dark:text-ink-500 hover:bg-ink-100 dark:hover:bg-ink-800 hover:text-ink-800 dark:hover:text-ink-200'"
        >
          <component :is="tool.icon" :size="15" />
        </button>
      </template>
    </div>

    <!-- ── Link Popup ─────────────────────────────────────────────── -->
    <Transition name="popup">
      <div
        v-if="showLinkPopup"
        class="absolute top-full left-0 mt-2 w-72 bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-700 rounded-xl shadow-xl shadow-ink-900/10 dark:shadow-black/40 p-4 z-50"
      >
        <div class="flex items-center justify-between mb-3">
          <span class="text-sm font-semibold font-ui text-ink-800 dark:text-ink-100">Insert Link</span>
          <button @click="closeLinkPopup" class="p-1 rounded hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400">
            <X :size="14" />
          </button>
        </div>

        <!-- URL Input -->
        <div class="mb-3">
          <label class="block text-xs font-ui text-ink-500 dark:text-ink-400 mb-1">URL</label>
          <input
            ref="linkInputEl"
            v-model="linkUrl"
            type="url"
            placeholder="https://example.com"
            class="w-full px-3 py-2 text-sm rounded-lg border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-950 text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600 font-ui focus:outline-none focus:ring-2 focus:ring-amber-400"
            @keydown.enter="applyLink"
            @keydown.esc="closeLinkPopup"
          />
        </div>

        <!-- Link Text (optional) -->
        <div class="mb-3">
          <label class="block text-xs font-ui text-ink-500 dark:text-ink-400 mb-1">Link Text</label>
          <input
            v-model="linkText"
            type="text"
            placeholder="Display text"
            class="w-full px-3 py-2 text-sm rounded-lg border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-950 text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600 font-ui focus:outline-none focus:ring-2 focus:ring-amber-400"
            @keydown.enter="applyLink"
          />
        </div>

        <!-- Open in new tab -->
        <div class="mb-4 flex items-center gap-2">
          <button
            @click="linkNewTab = !linkNewTab"
            class="relative inline-flex h-5 w-9 items-center rounded-full transition-colors"
            :class="linkNewTab ? 'bg-amber-500' : 'bg-ink-200 dark:bg-ink-700'"
          >
            <span
              class="inline-block h-3.5 w-3.5 transform rounded-full bg-white shadow-sm transition-transform"
              :class="linkNewTab ? 'translate-x-5' : 'translate-x-1'"
            />
          </button>
          <span class="text-xs font-ui text-ink-600 dark:text-ink-400 flex items-center gap-1">
            <ExternalLink :size="12" />
            Open in new tab
          </span>
        </div>

        <!-- Actions -->
        <div class="flex items-center gap-2">
          <button
            v-if="props.editor?.isActive('link')"
            @click="removeLink"
            class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
          >
            <Trash2 :size="12" />
            Remove
          </button>
          <div class="flex-1" />
          <button
            @click="closeLinkPopup"
            class="px-3 py-1.5 text-xs font-ui text-ink-500 dark:text-ink-400 hover:bg-ink-100 dark:hover:bg-ink-800 rounded-lg transition-colors"
          >
            Cancel
          </button>
          <button
            @click="applyLink"
            class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui font-semibold bg-ink-900 dark:bg-amber-500 text-white dark:text-ink-950 hover:bg-ink-700 dark:hover:bg-amber-600 rounded-lg transition-colors"
          >
            <Check :size="12" />
            Apply
          </button>
        </div>
      </div>
    </Transition>

    <!-- ── Image Popup ────────────────────────────────────────────── -->
    <Transition name="popup">
      <div
        v-if="showImagePopup"
        class="absolute top-full left-0 mt-2 w-80 bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-700 rounded-xl shadow-xl shadow-ink-900/10 dark:shadow-black/40 p-4 z-50"
      >
        <div class="flex items-center justify-between mb-3">
          <span class="text-sm font-semibold font-ui text-ink-800 dark:text-ink-100">Image Options</span>
          <button @click="closeImagePopup" class="p-1 rounded hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400">
            <X :size="14" />
          </button>
        </div>

        <!-- Width selector -->
        <div class="mb-3">
          <label class="block text-xs font-ui text-ink-500 dark:text-ink-400 mb-1.5">Size</label>
          <div class="flex gap-1">
            <button
              v-for="w in ['25%', '50%', '75%', '100%']" :key="w"
              @click="setImageWidth(w)"
              class="flex-1 px-2 py-1.5 text-xs font-ui rounded-lg border transition-colors"
              :class="imageWidth === w
                ? 'bg-amber-100 dark:bg-amber-900/40 border-amber-300 dark:border-amber-700 text-amber-700 dark:text-amber-400'
                : 'border-ink-200 dark:border-ink-700 text-ink-600 dark:text-ink-400 hover:border-ink-300 dark:hover:border-ink-600'"
            >
              {{ w }}
            </button>
          </div>
        </div>

        <!-- Alignment selector -->
        <div class="mb-3">
          <label class="block text-xs font-ui text-ink-500 dark:text-ink-400 mb-1.5">Alignment</label>
          <div class="flex gap-1">
            <button
              v-for="a in IMAGE_ALIGN_OPTIONS"
              :key="a.v"
              @click="setImageAlign(a.v)"
              class="flex items-center justify-center gap-1 px-3 py-1.5 text-xs font-ui rounded-lg border transition-colors"
              :class="imageAlign === a.v
                ? 'bg-amber-100 dark:bg-amber-900/40 border-amber-300 dark:border-amber-700 text-amber-700 dark:text-amber-400'
                : 'border-ink-200 dark:border-ink-700 text-ink-600 dark:text-ink-400 hover:border-ink-300 dark:hover:border-ink-600'"
            >
              <component :is="a.icon" :size="13" />
            </button>
          </div>
        </div>

        <!-- Alt text -->
        <div class="mb-4">
          <label class="block text-xs font-ui text-ink-500 dark:text-ink-400 mb-1.5">Alt Text</label>
          <div v-if="!editingAlt" class="flex items-center gap-2">
            <span class="flex-1 text-xs font-ui text-ink-700 dark:text-ink-300 truncate">
              {{ altText || 'No alt text' }}
            </span>
            <button
              @click="editingAlt = true"
              class="text-xs font-ui text-amber-600 dark:text-amber-400 hover:underline"
            >
              Edit
            </button>
          </div>
          <div v-else class="flex gap-2">
            <input
              v-model="altText"
              type="text"
              placeholder="Describe the image..."
              class="flex-1 px-3 py-1.5 text-xs font-ui rounded-lg border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-950 text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600 focus:outline-none focus:ring-2 focus:ring-amber-400"
              @keydown.enter="saveAltText"
              @keydown.esc="editingAlt = false"
            />
            <button
              @click="saveAltText"
              class="p-1.5 rounded-lg bg-amber-500 hover:bg-amber-600 text-white"
            >
              <Check :size="12" />
            </button>
          </div>
        </div>

        <!-- Delete image -->
        <div class="pt-3 border-t border-ink-100 dark:border-ink-800">
          <button
            @click="deleteImage"
            class="flex items-center gap-1.5 w-full px-3 py-1.5 text-xs font-ui font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
          >
            <Trash2 :size="12" />
            Delete Image
          </button>
        </div>
      </div>
    </Transition>

    <!-- ── Highlight Popup ────────────────────────────────────────── -->
    <Transition name="popup">
      <div
        v-if="showHighlightPopup"
        class="absolute top-full left-0 mt-2 w-64 bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-700 rounded-xl shadow-xl shadow-ink-900/10 dark:shadow-black/40 p-4 z-50"
      >
        <div class="flex items-center justify-between mb-3">
          <span class="text-sm font-semibold font-ui text-ink-800 dark:text-ink-100">Highlight Color</span>
          <button @click="showHighlightPopup = false" class="p-1 rounded hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400">
            <X :size="14" />
          </button>
        </div>

        <!-- Color grid -->
        <div class="grid grid-cols-6 gap-2 mb-3">
          <button
            v-for="color in HIGHLIGHT_COLORS"
            :key="color"
            @click="applyHighlight(color)"
            class="w-8 h-8 rounded-lg transition-all hover:scale-110 active:scale-95"
            :style="{ backgroundColor: color }"
            :class="selectedHighlightColor === color ? 'ring-2 ring-amber-500 ring-offset-2' : 'ring-1 ring-ink-200 dark:ring-ink-700'"
          />
        </div>

        <!-- Remove highlight -->
        <button
          @click="removeHighlight"
          class="flex items-center gap-1.5 w-full px-3 py-1.5 text-xs font-ui font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
        >
          <X :size="12" />
          Remove Highlight
        </button>
      </div>
    </Transition>

    <!-- ── Table Popup ────────────────────────────────────────────── -->
    <Transition name="popup">
      <div
        v-if="showTablePopup"
        class="absolute top-full left-0 mt-2 w-72 bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-700 rounded-xl shadow-xl shadow-ink-900/10 dark:shadow-black/40 p-4 z-50"
      >
        <div class="flex items-center justify-between mb-3">
          <span class="text-sm font-semibold font-ui text-ink-800 dark:text-ink-100">
            {{ isTableActive ? 'Table Options' : 'Insert Table' }}
          </span>
          <button @click="closeTablePopup" class="p-1 rounded hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400">
            <X :size="14" />
          </button>
        </div>

        <!-- Insert new table (when no table is active) -->
        <div v-if="!isTableActive" class="space-y-3">
          <p class="text-xs font-ui text-ink-500 dark:text-ink-400">
            Insert a new 3x3 table with header row
          </p>
          <button
            @click="insertTable"
            class="flex items-center gap-2 w-full px-4 py-2 text-sm font-ui font-semibold bg-amber-500 hover:bg-amber-600 text-ink-950 rounded-lg transition-colors"
          >
            <Table2 :size="16" />
            Insert Table
          </button>
        </div>

        <!-- Table manipulation (when table is active) -->
        <div v-else class="space-y-3">
          <!-- Row controls -->
          <div>
            <label class="block text-xs font-ui text-ink-500 dark:text-ink-400 mb-2">Rows</label>
            <div class="flex items-center gap-2">
              <button
                @click="addRow"
                class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui text-ink-600 dark:text-ink-300 bg-ink-50 dark:bg-ink-800 hover:bg-ink-100 dark:hover:bg-ink-700 rounded-lg transition-colors"
              >
                <Plus :size="14" />
                Add Row
              </button>
              <button
                @click="deleteRow"
                class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 hover:bg-red-100 dark:hover:bg-red-900/40 rounded-lg transition-colors"
              >
                <MinusIcon :size="14" />
                Delete Row
              </button>
            </div>
          </div>

          <!-- Column controls -->
          <div>
            <label class="block text-xs font-ui text-ink-500 dark:text-ink-400 mb-2">Columns</label>
            <div class="flex items-center gap-2">
              <button
                @click="addColumn"
                class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui text-ink-600 dark:text-ink-300 bg-ink-50 dark:bg-ink-800 hover:bg-ink-100 dark:hover:bg-ink-700 rounded-lg transition-colors"
              >
                <Plus :size="14" />
                Add Column
              </button>
              <button
                @click="deleteColumn"
                class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 hover:bg-red-100 dark:hover:bg-red-900/40 rounded-lg transition-colors"
              >
                <MinusIcon :size="14" />
                Delete Column
              </button>
            </div>
          </div>

          <!-- Header row toggle -->
          <div>
            <button
              @click="toggleHeaderRow"
              class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui text-ink-600 dark:text-ink-300 bg-ink-50 dark:bg-ink-800 hover:bg-ink-100 dark:hover:bg-ink-700 rounded-lg transition-colors w-full"
            >
              <ChevronRight :size="14" />
              Toggle Header Row
            </button>
          </div>

          <!-- Delete table -->
          <div class="pt-2 border-t border-ink-100 dark:border-ink-800">
            <button
              @click="deleteTable"
              class="flex items-center gap-1.5 w-full px-3 py-1.5 text-xs font-ui font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
            >
              <Trash2 :size="12" />
              Delete Table
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.popup-enter-active,
.popup-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.popup-enter-from,
.popup-leave-to {
  opacity: 0;
  transform: translateY(-4px);
}
</style>