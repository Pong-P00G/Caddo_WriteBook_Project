<script setup lang="ts">
import type { Editor } from '@tiptap/vue-3'
import {
  Bold, Italic, Underline, Strikethrough, Code, Code2, Heading1, Heading2,
  Heading3, List, ListOrdered, Quote, Minus, Undo, Redo, AlignLeft,
  AlignCenter, AlignRight, AlignJustify, Highlighter, Baseline, Subscript, Superscript,
  CheckSquare, Image, Link2, X, Check, ExternalLink, Trash2,
  ChevronLeft, ChevronRight, Table2, Plus, Minus as MinusIcon, Pipette, RotateCcw
} from 'lucide-vue-next'
import { ref, computed, watch, nextTick, onMounted, onUnmounted } from 'vue'

const props = defineProps<{ editor: Editor | undefined }>()
const toolbarRoot = ref<HTMLElement | null>(null)

// ── Text colors ───────────────────────────────────────────────────────────
const TEXT_COLORS = [
  // Neutrals / Monochrome
  '#000000', '#374151', '#4b5563', '#6b7280', '#9ca3af', '#ffffff',
  // Red / Rose
  '#ef4444', '#dc2626', '#b91c1c', '#991b1b', '#f43f5e', '#e11d48',
  // Orange / Amber
  '#f97316', '#ea580c', '#c2410c', '#f59e0b', '#d97706', '#b45309',
  // Yellow / Lime / Green
  '#eab308', '#ca8a04', '#84cc16', '#65a30d', '#22c55e', '#16a34a',
  // Teal / Cyan / Sky
  '#10b981', '#059669', '#14b8a6', '#0d9488', '#06b6d4', '#0284c7',
  // Blue / Indigo / Purple / Pink
  '#3b82f6', '#2563eb', '#1d4ed8', '#6366f1', '#4f46e5', '#8b5cf6',
  '#7c3aed', '#6d28d9', '#a855f7', '#9333ea', '#ec4899', '#db2777',
]

const showTextColorPopup = ref(false)
const customTextColor = ref('#000000')
const customTextHex = ref('000000')

function currentTextColor(): string | null {
  return props.editor?.getAttributes('textStyle').color || null
}

function toggleTextColorPopup() {
  const activeColor = currentTextColor()
  if (activeColor) {
    customTextColor.value = activeColor
    customTextHex.value = activeColor.replace('#', '')
  }
  showTextColorPopup.value = !showTextColorPopup.value
  showHighlightPopup.value = false
  showLinkPopup.value = false
  showImagePopup.value = false
  showTablePopup.value = false
}

function applyTextColor(color: string) {
  if (!color) return
  const hex = color.startsWith('#') ? color : `#${color}`
  props.editor?.chain().focus().setColor(hex).run()
  customTextColor.value = hex
  customTextHex.value = hex.replace('#', '')
}

function handleCustomTextPicker(e: Event) {
  const val = (e.target as HTMLInputElement).value
  applyTextColor(val)
}

function onHexInputChange() {
  let hex = customTextHex.value.trim()
  if (!hex.startsWith('#')) {
    hex = `#${hex}`
  }
  if (/^#([0-9A-Fa-f]{3}){1,2}$/.test(hex)) {
    customTextColor.value = hex
    props.editor?.chain().focus().setColor(hex).run()
  }
}

function applyCustomHex() {
  let hex = customTextHex.value.trim()
  if (!hex.startsWith('#')) {
    hex = `#${hex}`
  }
  if (/^#([0-9A-Fa-f]{3}){1,2}$/.test(hex)) {
    applyTextColor(hex)
    showTextColorPopup.value = false
  }
}

function removeTextColor() {
  props.editor?.chain().focus().unsetColor().run()
  showTextColorPopup.value = false
}

// ── Highlight colors ──────────────────────────────────────────────────────
const HIGHLIGHT_COLORS = [
  '#fef08a', '#fde047', '#facc15', '#fed7aa', '#fdba74', '#fb923c',
  '#fecaca', '#fca5a5', '#f87171', '#bbf7d0', '#86efac', '#4ade80',
  '#99f6e4', '#5eead4', '#2dd4bf', '#bae6fd', '#7dd3fc', '#38bdf8',
  '#c7d2fe', '#a5b4fc', '#818cf8', '#e9d5ff', '#d8b4fe', '#c084fc',
]
const showHighlightPopup = ref(false)
const customHighlightColor = ref('#fef08a')
const customHighlightHex = ref('fef08a')

function currentHighlightColor(): string | null {
  return props.editor?.getAttributes('highlight').color || null
}

function toggleHighlightPopup() {
  const active = currentHighlightColor()
  if (active) {
    customHighlightColor.value = active
    customHighlightHex.value = active.replace('#', '')
  }
  showHighlightPopup.value = !showHighlightPopup.value
  showTextColorPopup.value = false
  showLinkPopup.value = false
  showImagePopup.value = false
  showTablePopup.value = false
}

function applyHighlight(color: string) {
  if (!color) return
  const hex = color.startsWith('#') ? color : `#${color}`
  props.editor?.chain().focus().toggleHighlight({ color: hex }).run()
  customHighlightColor.value = hex
  customHighlightHex.value = hex.replace('#', '')
  showHighlightPopup.value = false
}

function handleCustomHighlightPicker(e: Event) {
  const val = (e.target as HTMLInputElement).value
  applyHighlight(val)
}

function onHighlightHexChange() {
  let hex = customHighlightHex.value.trim()
  if (!hex.startsWith('#')) {
    hex = `#${hex}`
  }
  if (/^#([0-9A-Fa-f]{3}){1,2}$/.test(hex)) {
    customHighlightColor.value = hex
  }
}

function applyCustomHighlightHex() {
  let hex = customHighlightHex.value.trim()
  if (!hex.startsWith('#')) {
    hex = `#${hex}`
  }
  if (/^#([0-9A-Fa-f]{3}){1,2}$/.test(hex)) {
    applyHighlight(hex)
  }
}

function removeHighlight() {
  props.editor?.chain().focus().unsetHighlight().run()
  showHighlightPopup.value = false
}

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
  showTextColorPopup.value = false
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
const IMAGE_ALIGN_OPTIONS = [
  { v: 'left', icon: AlignLeft },
  { v: 'center', icon: AlignCenter },
  { v: 'right', icon: AlignRight },
] as const
const showImagePopup = ref(false)
const editingAlt = ref(false)
const altText = ref('')
const imageWidth = ref<'25%' | '50%' | '75%' | '100%'>('100%')
const imageAlign = ref<'left' | 'center' | 'right'>('center')
const isImageSelected = ref(false)

// Check if an image node is currently selected
function checkImageSelection() {
  if (!props.editor) return false
  const { from } = props.editor.state.selection
  const isImg = props.editor.isActive('image')
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
  showTextColorPopup.value = false
  showImagePopup.value = false
  showHighlightPopup.value = false
  showTablePopup.value = false
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
  showTextColorPopup.value = false
  showLinkPopup.value = false
  showHighlightPopup.value = false
  showTablePopup.value = false
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

// ── Close popups on click outside ──────────────────────────────────────────
function handleDocumentClick(e: MouseEvent) {
  if (toolbarRoot.value && !toolbarRoot.value.contains(e.target as Node)) {
    showTextColorPopup.value = false
    showHighlightPopup.value = false
    showLinkPopup.value = false
    showImagePopup.value = false
    showTablePopup.value = false
  }
}

onMounted(() => {
  window.addEventListener('mousedown', handleDocumentClick)
})

onUnmounted(() => {
  window.removeEventListener('mousedown', handleDocumentClick)
})

// ── Track editor selection ────────────────────────────────────────────────
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

// ── Toolbar tools ──────────────────────────────────────────────────────────
interface ToolbarTool {
  icon: any
  title: string
  action: () => any
  isActive: () => boolean
  colorIndicator?: () => string | null | undefined
}

const tools = computed(() => {
  const list: (ToolbarTool | null)[] = [
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
    { icon: AlignLeft,     title: 'Align left',             action: () => props.editor?.chain().focus().setTextAlign('left').run(),           isActive: () => !!props.editor?.isActive({ textAlign: 'left' }) },
    { icon: AlignCenter,   title: 'Align center',           action: () => props.editor?.chain().focus().setTextAlign('center').run(),         isActive: () => !!props.editor?.isActive({ textAlign: 'center' }) },
    { icon: AlignRight,    title: 'Align right',            action: () => props.editor?.chain().focus().setTextAlign('right').run(),          isActive: () => !!props.editor?.isActive({ textAlign: 'right' }) },
    { icon: AlignJustify,  title: 'Justify',                action: () => props.editor?.chain().focus().setTextAlign('justify').run(),        isActive: () => !!props.editor?.isActive({ textAlign: 'justify' }) },
    null,
    { icon: Baseline,      title: 'Text color',             action: toggleTextColorPopup,                                                     isActive: () => !!props.editor?.isActive('textStyle'), colorIndicator: () => currentTextColor() },
    { icon: Highlighter,   title: 'Highlight text',         action: toggleHighlightPopup,                                                     isActive: () => !!props.editor?.isActive('highlight'), colorIndicator: () => currentHighlightColor() },
    { icon: Subscript,     title: 'Subscript',              action: () => props.editor?.chain().focus().toggleSubscript().run(),              isActive: () => !!props.editor?.isActive('subscript') },
    { icon: Superscript,   title: 'Superscript',            action: () => props.editor?.chain().focus().toggleSuperscript().run(),            isActive: () => !!props.editor?.isActive('superscript') },
    null,
    { icon: Link2,         title: 'Link',                   action: openLinkPopup,                                                            isActive: () => !!props.editor?.isActive('link') },
    { icon: Image,         title: 'Insert / Edit image',    action: openImagePicker,                                                          isActive: () => isImageSelected.value },
    { icon: Table2,        title: 'Table options',          action: toggleTablePopup,                                                         isActive: () => isTableActive.value },
    null,
    { icon: Undo,          title: 'Undo (Ctrl+Z)',          action: () => props.editor?.chain().focus().undo().run(),                        isActive: () => false },
    { icon: Redo,          title: 'Redo (Ctrl+Shift+Z)',    action: () => props.editor?.chain().focus().redo().run(),                        isActive: () => false },
  ]
  return list
})
</script>

<template>
  <div ref="toolbarRoot" class="relative">
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
        <!-- Separator -->
        <div
          v-if="tool === null"
          :key="`separator-${i}`"
          class="w-px h-4 bg-ink-200 dark:bg-ink-700 mx-1"
        />
        <!-- Toolbar button with styled tooltip -->
        <div
          v-else
          :key="`tool-${i}`"
          class="tooltip-wrapper"
        >
          <button
            @click="tool.action()"
            class="p-1.5 rounded transition-all duration-100 active:scale-90 relative flex flex-col items-center justify-center cursor-pointer"
            :class="tool.isActive()
              ? 'bg-amber-100 dark:bg-amber-900/40 text-amber-700 dark:text-amber-400'
              : 'text-ink-400 dark:text-ink-500 hover:bg-ink-100 dark:hover:bg-ink-800 hover:text-ink-800 dark:hover:text-ink-200'"
          >
            <component :is="tool.icon" :size="15" />
            <span
              v-if="tool.colorIndicator && tool.colorIndicator()"
              class="w-3.5 h-0.5 rounded-full mt-0.5 border border-black/10 dark:border-white/20"
              :style="{ backgroundColor: tool.colorIndicator()! }"
            />
          </button>
          <span class="tooltip">{{ tool.title }}</span>
        </div>
      </template>
    </div>

    <!-- ── Text Color Popup ───────────────────────────────────────── -->
    <Transition name="popup">
      <div
        v-if="showTextColorPopup"
        class="absolute top-full left-0 mt-2 w-72 max-w-[calc(100vw-2rem)] bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-700 rounded-xl shadow-xl shadow-ink-900/10 dark:shadow-black/40 p-4 z-50 animate-scale-in"
      >
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center gap-1.5">
            <Baseline :size="15" class="text-amber-600 dark:text-amber-400" />
            <span class="text-sm font-semibold font-ui text-ink-800 dark:text-ink-100">Text Color</span>
          </div>
          <button @click="showTextColorPopup = false" class="p-1 rounded hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400 cursor-pointer">
            <X :size="14" />
          </button>
        </div>

        <!-- Color presets grid -->
        <div class="mb-3">
          <label class="block text-[11px] font-ui font-medium uppercase tracking-wider text-ink-400 dark:text-ink-500 mb-1.5">
            Presets
          </label>
          <div class="grid grid-cols-6 gap-1.5">
            <button
              v-for="color in TEXT_COLORS"
              :key="color"
              @click="applyTextColor(color)"
              class="w-7 h-7 rounded-md transition-all hover:scale-110 active:scale-95 flex items-center justify-center relative cursor-pointer"
              :style="{ backgroundColor: color }"
              :class="currentTextColor() === color ? 'ring-2 ring-amber-500 ring-offset-2 ring-offset-white dark:ring-offset-ink-900' : 'ring-1 ring-ink-200/80 dark:ring-ink-700/80'"
              :title="color"
            >
              <Check
                v-if="currentTextColor() === color"
                :size="12"
                class="mix-blend-difference text-white"
              />
            </button>
          </div>
        </div>

        <!-- Custom Color Picker -->
        <div class="pt-3 border-t border-ink-100 dark:border-ink-800 mb-3">
          <label class="block text-[11px] font-ui font-medium uppercase tracking-wider text-ink-400 dark:text-ink-500 mb-1.5">
            Custom Color Picker
          </label>
          <div class="flex items-center gap-2">
            <!-- Native Color Picker Swatch Trigger -->
            <label class="relative w-8 h-8 shrink-0 rounded-lg overflow-hidden border border-ink-200 dark:border-ink-700 shadow-inner cursor-pointer hover:border-amber-400 transition-colors">
              <input
                type="color"
                :value="customTextColor"
                @input="handleCustomTextPicker"
                class="absolute -top-4 -left-4 w-16 h-16 cursor-pointer opacity-0"
              />
              <div
                class="w-full h-full rounded-lg flex items-center justify-center pointer-events-none"
                :style="{ backgroundColor: customTextColor }"
              >
                <Pipette :size="13" class="text-white drop-shadow mix-blend-difference" />
              </div>
            </label>

            <!-- Hex code input -->
            <div class="flex-1 flex items-center rounded-lg border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-950 px-2 py-1 focus-within:ring-2 focus-within:ring-amber-400">
              <span class="text-xs font-mono text-ink-400 select-none mr-1">#</span>
              <input
                type="text"
                v-model="customTextHex"
                placeholder="000000"
                maxlength="7"
                class="w-full text-xs font-mono bg-transparent text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600 focus:outline-none uppercase"
                @input="onHexInputChange"
                @keydown.enter="applyCustomHex"
              />
            </div>

            <button
              @click="applyCustomHex"
              class="px-3 py-1.5 text-xs font-ui font-semibold bg-amber-500 hover:bg-amber-600 active:scale-95 text-ink-950 rounded-lg transition-all cursor-pointer"
            >
              Apply
            </button>
          </div>
        </div>

        <!-- Remove / Reset Color -->
        <button
          @click="removeTextColor"
          class="flex items-center justify-center gap-1.5 w-full px-3 py-1.5 text-xs font-ui font-medium text-ink-600 dark:text-ink-400 hover:text-red-600 dark:hover:text-red-400 hover:bg-ink-50 dark:hover:bg-ink-800 rounded-lg transition-colors cursor-pointer"
        >
          <RotateCcw :size="12" />
          Reset to Default Color
        </button>
      </div>
    </Transition>

    <!-- ── Highlight Popup ────────────────────────────────────────── -->
    <Transition name="popup">
      <div
        v-if="showHighlightPopup"
        class="absolute top-full left-0 mt-2 w-72 max-w-[calc(100vw-2rem)] bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-700 rounded-xl shadow-xl shadow-ink-900/10 dark:shadow-black/40 p-4 z-50 animate-scale-in"
      >
        <div class="flex items-center justify-between mb-3">
          <div class="flex items-center gap-1.5">
            <Highlighter :size="15" class="text-amber-600 dark:text-amber-400" />
            <span class="text-sm font-semibold font-ui text-ink-800 dark:text-ink-100">Highlight Color</span>
          </div>
          <button @click="showHighlightPopup = false" class="p-1 rounded hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400 cursor-pointer">
            <X :size="14" />
          </button>
        </div>

        <!-- Color grid -->
        <div class="mb-3">
          <label class="block text-[11px] font-ui font-medium uppercase tracking-wider text-ink-400 dark:text-ink-500 mb-1.5">
            Presets
          </label>
          <div class="grid grid-cols-6 gap-1.5">
            <button
              v-for="color in HIGHLIGHT_COLORS"
              :key="color"
              @click="applyHighlight(color)"
              class="w-7 h-7 rounded-md transition-all hover:scale-110 active:scale-95 flex items-center justify-center relative cursor-pointer"
              :style="{ backgroundColor: color }"
              :class="currentHighlightColor() === color ? 'ring-2 ring-amber-500 ring-offset-2 ring-offset-white dark:ring-offset-ink-900' : 'ring-1 ring-ink-200/80 dark:ring-ink-700/80'"
              :title="color"
            >
              <Check
                v-if="currentHighlightColor() === color"
                :size="12"
                class="mix-blend-difference text-white"
              />
            </button>
          </div>
        </div>

        <!-- Custom Highlight Color Picker -->
        <div class="pt-3 border-t border-ink-100 dark:border-ink-800 mb-3">
          <label class="block text-[11px] font-ui font-medium uppercase tracking-wider text-ink-400 dark:text-ink-500 mb-1.5">
            Custom Color Picker
          </label>
          <div class="flex items-center gap-2">
            <label class="relative w-8 h-8 shrink-0 rounded-lg overflow-hidden border border-ink-200 dark:border-ink-700 shadow-inner cursor-pointer hover:border-amber-400 transition-colors">
              <input
                type="color"
                :value="customHighlightColor"
                @input="handleCustomHighlightPicker"
                class="absolute -top-4 -left-4 w-16 h-16 cursor-pointer opacity-0"
              />
              <div
                class="w-full h-full rounded-lg flex items-center justify-center pointer-events-none"
                :style="{ backgroundColor: customHighlightColor }"
              >
                <Pipette :size="13" class="text-white drop-shadow mix-blend-difference" />
              </div>
            </label>
            <div class="flex-1 flex items-center rounded-lg border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-950 px-2 py-1 focus-within:ring-2 focus-within:ring-amber-400">
              <span class="text-xs font-mono text-ink-400 select-none mr-1">#</span>
              <input
                type="text"
                v-model="customHighlightHex"
                placeholder="fef08a"
                maxlength="7"
                class="w-full text-xs font-mono bg-transparent text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600 focus:outline-none uppercase"
                @input="onHighlightHexChange"
                @keydown.enter="applyCustomHighlightHex"
              />
            </div>
            <button
              @click="applyCustomHighlightHex"
              class="px-3 py-1.5 text-xs font-ui font-semibold bg-amber-500 hover:bg-amber-600 active:scale-95 text-ink-950 rounded-lg transition-all cursor-pointer"
            >
              Apply
            </button>
          </div>
        </div>

        <!-- Remove highlight -->
        <button
          @click="removeHighlight"
          class="flex items-center justify-center gap-1.5 w-full px-3 py-1.5 text-xs font-ui font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors cursor-pointer"
        >
          <X :size="12" />
          Remove Highlight
        </button>
      </div>
    </Transition>

    <!-- ── Link Popup ─────────────────────────────────────────────── -->
    <Transition name="popup">
      <div
        v-if="showLinkPopup"
        class="absolute top-full left-0 mt-2 w-72 max-w-[calc(100vw-2rem)] bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-700 rounded-xl shadow-xl shadow-ink-900/10 dark:shadow-black/40 p-4 z-50 animate-scale-in"
      >
        <div class="flex items-center justify-between mb-3">
          <span class="text-sm font-semibold font-ui text-ink-800 dark:text-ink-100">Insert Link</span>
          <button @click="closeLinkPopup" class="p-1 rounded hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400 cursor-pointer">
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
            class="relative inline-flex h-5 w-9 items-center rounded-full transition-colors cursor-pointer"
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
            class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors cursor-pointer"
          >
            <Trash2 :size="12" />
            Remove
          </button>
          <div class="flex-1" />
          <button
            @click="closeLinkPopup"
            class="px-3 py-1.5 text-xs font-ui text-ink-500 dark:text-ink-400 hover:bg-ink-100 dark:hover:bg-ink-800 rounded-lg transition-colors cursor-pointer"
          >
            Cancel
          </button>
          <button
            @click="applyLink"
            class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui font-semibold bg-ink-900 dark:bg-amber-500 text-white dark:text-ink-950 hover:bg-ink-700 dark:hover:bg-amber-600 rounded-lg transition-colors cursor-pointer"
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
        class="absolute top-full left-0 mt-2 w-80 max-w-[calc(100vw-2rem)] bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-700 rounded-xl shadow-xl shadow-ink-900/10 dark:shadow-black/40 p-4 z-50 animate-scale-in"
      >
        <div class="flex items-center justify-between mb-3">
          <span class="text-sm font-semibold font-ui text-ink-800 dark:text-ink-100">Image Options</span>
          <button @click="closeImagePopup" class="p-1 rounded hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400 cursor-pointer">
            <X :size="14" />
          </button>
        </div>

        <!-- Width selector -->
        <div class="mb-3">
          <label class="block text-xs font-ui text-ink-500 dark:text-ink-400 mb-1.5">Size</label>
          <div class="flex gap-1">
            <button
              v-for="w in ['25%', '50%', '75%', '100%']" :key="w"
              @click="setImageWidth(w as any)"
              class="flex-1 px-2 py-1.5 text-xs font-ui rounded-lg border transition-colors cursor-pointer"
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
              @click="setImageAlign(a.v as any)"
              class="flex items-center justify-center gap-1 px-3 py-1.5 text-xs font-ui rounded-lg border transition-colors cursor-pointer"
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
              class="text-xs font-ui text-amber-600 dark:text-amber-400 hover:underline cursor-pointer"
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
              class="p-1.5 rounded-lg bg-amber-500 hover:bg-amber-600 text-white cursor-pointer"
            >
              <Check :size="12" />
            </button>
          </div>
        </div>

        <!-- Delete image -->
        <div class="pt-3 border-t border-ink-100 dark:border-ink-800">
          <button
            @click="deleteImage"
            class="flex items-center gap-1.5 w-full px-3 py-1.5 text-xs font-ui font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors cursor-pointer"
          >
            <Trash2 :size="12" />
            Delete Image
          </button>
        </div>
      </div>
    </Transition>

    <!-- ── Table Popup ────────────────────────────────────────────── -->
    <Transition name="popup">
      <div
        v-if="showTablePopup"
        class="absolute top-full left-0 mt-2 w-72 max-w-[calc(100vw-2rem)] bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-700 rounded-xl shadow-xl shadow-ink-900/10 dark:shadow-black/40 p-4 z-50 animate-scale-in"
      >
        <div class="flex items-center justify-between mb-3">
          <span class="text-sm font-semibold font-ui text-ink-800 dark:text-ink-100">
            {{ isTableActive ? 'Table Options' : 'Insert Table' }}
          </span>
          <button @click="closeTablePopup" class="p-1 rounded hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400 cursor-pointer">
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
            class="flex items-center gap-2 w-full px-4 py-2 text-sm font-ui font-semibold bg-amber-500 hover:bg-amber-600 text-ink-950 rounded-lg transition-colors cursor-pointer"
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
                class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui text-ink-600 dark:text-ink-300 bg-ink-50 dark:bg-ink-800 hover:bg-ink-100 dark:hover:bg-ink-700 rounded-lg transition-colors cursor-pointer"
              >
                <Plus :size="14" />
                Add Row
              </button>
              <button
                @click="deleteRow"
                class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 hover:bg-red-100 dark:hover:bg-red-900/40 rounded-lg transition-colors cursor-pointer"
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
                class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui text-ink-600 dark:text-ink-300 bg-ink-50 dark:bg-ink-800 hover:bg-ink-100 dark:hover:bg-ink-700 rounded-lg transition-colors cursor-pointer"
              >
                <Plus :size="14" />
                Add Column
              </button>
              <button
                @click="deleteColumn"
                class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 hover:bg-red-100 dark:hover:bg-red-900/40 rounded-lg transition-colors cursor-pointer"
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
              class="flex items-center gap-1.5 px-3 py-1.5 text-xs font-ui text-ink-600 dark:text-ink-300 bg-ink-50 dark:bg-ink-800 hover:bg-ink-100 dark:hover:bg-ink-700 rounded-lg transition-colors w-full cursor-pointer"
            >
              <ChevronRight :size="14" />
              Toggle Header Row
            </button>
          </div>

          <!-- Delete table -->
          <div class="pt-2 border-t border-ink-100 dark:border-ink-800">
            <button
              @click="deleteTable"
              class="flex items-center gap-1.5 w-full px-3 py-1.5 text-xs font-ui font-medium text-red-600 dark:text-red-400 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors cursor-pointer"
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