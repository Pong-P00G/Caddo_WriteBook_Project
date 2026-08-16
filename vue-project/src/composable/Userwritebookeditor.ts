import { useEditor, Editor } from '@tiptap/vue-3'
import StarterKit from '@tiptap/starter-kit'
import Placeholder from '@tiptap/extension-placeholder'
import CharacterCount from '@tiptap/extension-character-count'
import Image from '@tiptap/extension-image'
import Link from '@tiptap/extension-link'
import Underline from '@tiptap/extension-underline'
import Highlight from '@tiptap/extension-highlight'
import { TextStyle } from '@tiptap/extension-text-style'
import { Color } from '@tiptap/extension-color'
import TextAlign from '@tiptap/extension-text-align'
import Subscript from '@tiptap/extension-subscript'
import Superscript from '@tiptap/extension-superscript'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import { Table } from '@tiptap/extension-table'
import { TableRow } from '@tiptap/extension-table-row'
import { TableCell } from '@tiptap/extension-table-cell'
import { TableHeader } from '@tiptap/extension-table-header'
import { Extension } from '@tiptap/core'
import { ref, watch, onBeforeUnmount } from 'vue'

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

// Extension to handle Tab key pressing -> insert 4 spaces by default
const TabKeyExtension = Extension.create({
  name: 'tabKeyExtension',

  addKeyboardShortcuts() {
    return {
      Tab: () => {
        if (this.editor.isActive('listItem') || this.editor.isActive('taskItem')) {
          return false
        }
        return this.editor.commands.insertContent('    ')
      },
    }
  },
})

// Extension to guarantee Mod-z, Mod-Shift-z, and Mod-y keybinds for undo and redo
const UndoRedoExtension = Extension.create({
  name: 'undoRedoExtension',

  addKeyboardShortcuts() {
    return {
      'Mod-z': () => this.editor.commands.undo(),
      'Mod-y': () => this.editor.commands.redo(),
      'Mod-Shift-z': () => this.editor.commands.redo(),
      'Shift-Mod-z': () => this.editor.commands.redo(),
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
  let pendingContent: string | null = initialContent || null

  const editor = useEditor({
    content: initialContent || '',
    extensions: [
      StarterKit.configure({
        heading: { levels: [1, 2, 3] },
        link: false,
        underline: false,
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
      TextStyle,
      Color,
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
      TabKeyExtension,
      UndoRedoExtension,
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

  watch(editor, (ed) => {
    if (ed && pendingContent !== null) {
      setContent(pendingContent)
      pendingContent = null
    }
  }, { immediate: true })

  onBeforeUnmount(() => {
    clearTimeout(autosaveTimer)
    editor.value?.destroy()
  })

  function setContent(content: string) {
    if (!editor.value) {
      pendingContent = content
      return
    }

    try {
      let parsed: any;
      if (content && typeof content === 'string' && content.trim().startsWith('{')) {
        parsed = JSON.parse(content)
        // Unwrap double-encoded or stringified JSON inside paragraph nodes
        while (
          parsed &&
          typeof parsed === 'object' &&
          parsed.type === 'doc' &&
          Array.isArray(parsed.content) &&
          parsed.content.length === 1 &&
          parsed.content[0]?.type === 'paragraph' &&
          Array.isArray(parsed.content[0]?.content) &&
          parsed.content[0].content.length === 1 &&
          typeof parsed.content[0].content[0]?.text === 'string' &&
          parsed.content[0].content[0].text.trim().startsWith('{"type":"doc"')
        ) {
          try {
            parsed = JSON.parse(parsed.content[0].content[0].text.trim())
          } catch (_) {
            break
          }
        }
      } else if (content && typeof content === 'string') {
        // Strip any raw HTML tags like <color=...>, <mark...>, </mark>, </color>, <u>, <span>
        const cleaned = content.replace(/<\/?(?:color|mark|span|u)(?:\s+[^>]*)?>/gi, '')
        const lines = cleaned.split('\n')
        const nodes: any[] = []

        for (const line of lines) {
          const trimmed = line.trim()
          if (trimmed.startsWith('# ')) {
            nodes.push({
              type: 'heading',
              attrs: { level: 1 },
              content: [{ type: 'text', text: trimmed.substring(2) }]
            })
          } else if (trimmed.startsWith('## ')) {
            nodes.push({
              type: 'heading',
              attrs: { level: 2 },
              content: [{ type: 'text', text: trimmed.substring(3) }]
            })
          } else if (trimmed.startsWith('### ')) {
            nodes.push({
              type: 'heading',
              attrs: { level: 3 },
              content: [{ type: 'text', text: trimmed.substring(4) }]
            })
          } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
            nodes.push({
              type: 'bulletList',
              content: [
                {
                  type: 'listItem',
                  content: [
                    {
                      type: 'paragraph',
                      content: [{ type: 'text', text: trimmed.substring(2) }]
                    }
                  ]
                }
              ]
            })
          } else {
            nodes.push({
              type: 'paragraph',
              content: line ? [{ type: 'text', text: line }] : []
            })
          }
        }

        parsed = { type: 'doc', content: nodes.length ? nodes : [{ type: 'paragraph' }] }
      } else {
        parsed = { type: 'doc', content: [{ type: 'paragraph' }] }
      }

      editor.value.commands.setContent(parsed, { emitUpdate: false })
      wordCount.value = editor.value.storage.characterCount.words()
    } catch (e) {
      console.error('Failed to parse content:', e)
      const fallbackNodes = content 
        ? content.split('\n').map(line => ({ type: 'paragraph', content: line ? [{ type: 'text', text: line }] : [] }))
        : [{ type: 'paragraph' }]
      editor.value.commands.setContent({ type: 'doc', content: fallbackNodes }, { emitUpdate: false })
    }
  }

  return { editor, wordCount, isSaving, setContent }
}