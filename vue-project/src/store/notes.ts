import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '../api/Api'
import type { Note, ApiResponse } from './types/interface'

export const useNotesStore = defineStore('notes', () => {
  const notes       = ref<Note[]>([])
  const activeNote  = ref<Note | null>(null)
  const loading     = ref(false)

  async function fetchNotes(params?: { folderId?: string; workspaceId?: string; search?: string }) {
    loading.value = true
    try {
      const { data } = await api.get<ApiResponse<Note[]>>('/notes', { params })
      notes.value = data.data
    } finally {
      loading.value = false
    }
  }

  async function fetchNote(noteId: string) {
    loading.value = true
    try {
      const { data } = await api.get<ApiResponse<Note>>(`/notes/${noteId}`)
      activeNote.value = data.data
      return data.data
    } finally {
      loading.value = false
    }
  }

  async function createNote(payload: Partial<Note>) {
    const { data } = await api.post<ApiResponse<Note>>('/notes', payload)
    notes.value.unshift(data.data)
    return data.data
  }

  async function saveNote(noteId: string, payload: Partial<Note>) {
    const { data } = await api.patch<ApiResponse<Note>>(`/notes/${noteId}`, payload)
    const idx = notes.value.findIndex(n => n._id === noteId)
    if (idx !== -1) notes.value[idx] = data.data
    if (activeNote.value?._id === noteId) activeNote.value = data.data
    return data.data
  }

  async function deleteNote(noteId: string) {
    await api.delete(`/notes/${noteId}`)
    notes.value = notes.value.filter(n => n._id !== noteId)
    if (activeNote.value?._id === noteId) activeNote.value = null
  }

  async function toggleFavorite(noteId: string) {
    const note = notes.value.find(n => n._id === noteId) ?? activeNote.value
    if (!note) return
    return saveNote(noteId, { isFavorite: !note.isFavorite })
  }

  return {
    notes, activeNote, loading,
    fetchNotes, fetchNote, createNote, saveNote, deleteNote, toggleFavorite,
  }
})
