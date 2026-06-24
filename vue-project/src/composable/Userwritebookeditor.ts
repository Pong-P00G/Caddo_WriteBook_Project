import { useEditor } from '@tiptap/vue-3'
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
import { ref, onBeforeUnmount } from 'vue'

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
      Image.configure({ inline: false, allowBase64: true }),
      Link.configure({ openOnClick: false }),
      Underline,
      Highlight.configure({ multicolor: true }),
      TextAlign.configure({ types: ['heading', 'paragraph'] }),
      Subscript,
      Superscript,
      TaskList,
      TaskItem.configure({ nested: true }),
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