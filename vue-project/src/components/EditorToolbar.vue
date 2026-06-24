<script setup lang="ts">
import type { Editor } from '@tiptap/vue-3'
import {
  Bold, Italic, Underline, Strikethrough, Code, Code2, Heading1, Heading2,
  Heading3, List, ListOrdered, Quote, Minus, Undo, Redo, Link2, AlignLeft,
  AlignCenter, AlignRight, AlignJustify, Highlighter, Subscript, Superscript,
  CheckSquare
} from 'lucide-vue-next'

const props = defineProps<{ editor: Editor | undefined }>()

function setLink() {
  const prev = props.editor?.getAttributes('link').href ?? ''
  const url  = window.prompt('Enter URL', prev)
  if (url === null) return
  if (!url) {
    props.editor?.chain().focus().unsetLink().run()
    return
  }
  props.editor?.chain().focus().setLink({ href: url }).run()
}

function setHighlight() {
  const color = window.prompt('Enter highlight color (e.g., #ffff00, yellow)', '#ffff00')
  if (color === null) return
  if (!color) {
    props.editor?.chain().focus().unsetHighlight().run()
    return
  }
  props.editor?.chain().focus().toggleHighlight({ color }).run()
}

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
  { icon: CheckSquare,   title: 'Checklist',                action: () => props.editor?.chain().focus().toggleTaskList().run(),              isActive: () => !!props.editor?.isActive('taskList') },
  { icon: Quote,         title: 'Blockquote',             action: () => props.editor?.chain().focus().toggleBlockquote().run(),             isActive: () => !!props.editor?.isActive('blockquote') },
  { icon: Minus,         title: 'Divider',                action: () => props.editor?.chain().focus().setHorizontalRule().insertContentAt(props.editor.state.selection.anchor, { type: 'paragraph' }).focus().run(),            isActive: () => false },
  null,
  { icon: AlignLeft,     title: 'Align left',             action: () => props.editor?.chain().focus().setTextAlign('left').run(),           isActive: () => props.editor?.isActive({ textAlign: 'left' }) },
  { icon: AlignCenter,   title: 'Align center',           action: () => props.editor?.chain().focus().setTextAlign('center').run(),         isActive: () => props.editor?.isActive({ textAlign: 'center' }) },
  { icon: AlignRight,    title: 'Align right',            action: () => props.editor?.chain().focus().setTextAlign('right').run(),          isActive: () => props.editor?.isActive({ textAlign: 'right' }) },
  { icon: AlignJustify,  title: 'Justify',                action: () => props.editor?.chain().focus().setTextAlign('justify').run(),        isActive: () => props.editor?.isActive({ textAlign: 'justify' }) },
  null,
  { icon: Highlighter,   title: 'Highlight',              action: setHighlight,                                                             isActive: () => !!props.editor?.isActive('highlight') },
  { icon: Subscript,     title: 'Subscript',              action: () => props.editor?.chain().focus().toggleSubscript().run(),              isActive: () => !!props.editor?.isActive('subscript') },
  { icon: Superscript,   title: 'Superscript',            action: () => props.editor?.chain().focus().toggleSuperscript().run(),            isActive: () => !!props.editor?.isActive('superscript') },
  null,
  { icon: Link2,         title: 'Link',                   action: setLink,                                                                  isActive: () => !!props.editor?.isActive('link') },
  null,
  { icon: Undo,          title: 'Undo (Ctrl+Z)',          action: () => props.editor?.chain().focus().undo().run(),                        isActive: () => false },
  { icon: Redo,          title: 'Redo (Ctrl+Shift+Z)',    action: () => props.editor?.chain().focus().redo().run(),                        isActive: () => false },
]
</script>

<template>
  <div class="flex items-center gap-0.5 flex-wrap">
    <template v-for="(tool, i) in tools" :key="i">
      <div v-if="tool === null" class="w-px h-4 bg-ink-200 dark:bg-ink-700 mx-1.5" />
      <button
        v-else
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
</template>