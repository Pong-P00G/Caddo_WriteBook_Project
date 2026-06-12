<script setup lang="ts">
import type { Editor } from '@tiptap/vue-3'
import {
  Bold, Italic, Strikethrough, Code, Heading1, Heading2,
  Heading3, List, ListOrdered, Quote, Minus, Undo, Redo, Link2
} from 'lucide-vue-next'

const props = defineProps<{ editor: Editor | undefined }>()

function setLink() {
  const url = window.prompt('URL')
  if (!url || !props.editor) return
  props.editor.chain().focus().setLink({ href: url }).run()
}

const tools = [
  { icon: Bold,          action: () => props.editor?.chain().focus().toggleBold().run(),          isActive: () => props.editor?.isActive('bold') },
  { icon: Italic,        action: () => props.editor?.chain().focus().toggleItalic().run(),        isActive: () => props.editor?.isActive('italic') },
  { icon: Strikethrough, action: () => props.editor?.chain().focus().toggleStrike().run(),        isActive: () => props.editor?.isActive('strike') },
  { icon: Code,          action: () => props.editor?.chain().focus().toggleCode().run(),          isActive: () => props.editor?.isActive('code') },
  null, // separator
  { icon: Heading1,      action: () => props.editor?.chain().focus().toggleHeading({ level: 1 }).run(), isActive: () => props.editor?.isActive('heading', { level: 1 }) },
  { icon: Heading2,      action: () => props.editor?.chain().focus().toggleHeading({ level: 2 }).run(), isActive: () => props.editor?.isActive('heading', { level: 2 }) },
  { icon: Heading3,      action: () => props.editor?.chain().focus().toggleHeading({ level: 3 }).run(), isActive: () => props.editor?.isActive('heading', { level: 3 }) },
  null,
  { icon: List,          action: () => props.editor?.chain().focus().toggleBulletList().run(),    isActive: () => props.editor?.isActive('bulletList') },
  { icon: ListOrdered,   action: () => props.editor?.chain().focus().toggleOrderedList().run(),   isActive: () => props.editor?.isActive('orderedList') },
  { icon: Quote,         action: () => props.editor?.chain().focus().toggleBlockquote().run(),    isActive: () => props.editor?.isActive('blockquote') },
  { icon: Minus,         action: () => props.editor?.chain().focus().setHorizontalRule().run(),   isActive: () => false },
  { icon: Link2,         action: setLink,                                                         isActive: () => props.editor?.isActive('link') },
  null,
  { icon: Undo,          action: () => props.editor?.chain().focus().undo().run(),                isActive: () => false },
  { icon: Redo,          action: () => props.editor?.chain().focus().redo().run(),                isActive: () => false },
]
</script>

<template>
  <div class="flex items-center gap-0.5 flex-wrap">
    <template v-for="(tool, i) in tools" :key="i">
      <!-- Separator -->
      <div v-if="tool === null" class="w-px h-5 bg-ink-200 mx-1" />
      <!-- Button -->
      <button
        v-else
        @click="tool.action()"
        class="p-1.5 rounded hover:bg-ink-100 transition-colors"
        :class="tool.isActive() ? 'bg-ink-100 text-amber-700' : 'text-ink-500 hover:text-ink-800'"
      >
        <component :is="tool.icon" :size="15" />
      </button>
    </template>
  </div>
</template>