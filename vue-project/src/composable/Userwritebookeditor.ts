import { useEditor, Editor } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Placeholder from '@tiptap/extension-placeholder'
import CharacterCount from '@tiptap/extension-character-count'
import Image from '@tiptap/extension-image'
import Link from '@tiptap/extension-link'
import Underline from '@tiptap/extension-underline'
import Highlight from '@tiptap/extension-highlight'
import TextAlign from '@tiptap/extension-text-align'
import Subscript from '@tiptap/extension-subscript'
import Superscript from '@tiptap/extension-superscript'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import Table from '@tiptap/extension-table'
import TableRow from '@tiptap/extension-table-row'
import TableCell from '@tiptap/extension-table-cell'
import TableHeader from '@tiptap/extension-table-header'
import { Extension } from '@tiptap/core'
import { ref, onBeforeUnmount } from 'vue'

// Custom extension to handle image keyboard deletion
const ImageExtension = Extension.create({
  name: 'imageExtension',

  addKeyboardShortcuts() {
    return {
      Delete: () => {
        if (this.editor.isActive('image')) {
          this.editor.commands.deleteNode('image')
          return true
        }
        return false
      },
      Backspace: () => {
        if (this.editor.isActive('image')) {
          this.editor.commands.deleteNode('image')
          return true
        }
        return false
      },
    }
  },
})

export function useWritebookEditor(
  initialContent: string = '',
  onUpdate?: (content: string) => void
) {
  const wordCount     = ref(0)
  const isSaving      = ref(false)
  let autosaveTimer: ReturnType<typeof setTimeout>

  const editor = useEditor({
    content: initialContent || '',
    extensions: [
      StarterKit.configure({
        heading: { levels: [1, 2, 3] },
      }),
      Placeholder.configure({
        placeholder: 'Begin your chapter…',
      }),
      CharacterCount,
      Image.configure({
        inline: false,
        allowBase64: true,
        HTMLAttributes: {
          class: 'cursor-pointer',
        },
      }),
      Link.configure({ openOnClick: false }),
      Underline,
      Highlight.configure({ multicolor: true }),
      TextAlign.configure({ types: ['heading', 'paragraph'] }),
      Subscript,
      Superscript,
      TaskList,
      TaskItem.configure({ nested: true }),
      Table.configure({ resizable: false }),
      TableRow,
      TableCell,
      TableHeader,
      ImageExtension,
    ],
    editorProps: {
      attributes: { class: 'tiptap min-h-[400px] p-0' },
    },
    onUpdate({ editor }) {
      wordCount.value = editor.storage.characterCount.words()
      if (onUpdate) {
        clearTimeout(autosaveTimer)
        autosaveTimer = setTimeout(() => {
          isSaving.value = true
          onUpdate(JSON.stringify(editor.getJSON()))
          setTimeout(() => { isSaving.value = false }, 600)
        }, 1500)
      }
    },
  })

  onBeforeUnmount(() => {
    clearTimeout(autosaveTimer)
    editor.value?.destroy()
  })

  function setContent(content: string) {
    if (!editor.value) return
    const parsed = content ? JSON.parse(content) : ''
    editor.value.commands.setContent(parsed, { emitUpdate: false })
    wordCount.value = editor.value.storage.characterCount.words()
  }

  return { editor, wordCount, isSaving, setContent }
}