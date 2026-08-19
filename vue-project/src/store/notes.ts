import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '../api/Api'
import type { Note, NoteRevision, ApiResponse } from './types/interface'

export const useNotesStore = defineStore('notes', () => {
  const notes       = ref<Note[]>([])
  const activeNote  = ref<Note | null>(null)
  const revisions   = ref<NoteRevision[]>([])
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

  async function saveNote(noteId: string, payload: Partial<Note> & { changeSummary?: string }) {
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

  async function togglePin(noteId: string) {
    const note = notes.value.find(n => n._id === noteId) ?? activeNote.value
    if (!note) return
    return saveNote(noteId, { isPinned: !note.isPinned })
  }

  async function setNoteColor(noteId: string, color: string | null) {
    return saveNote(noteId, { color })
  }

  async function fetchRevisions(noteId: string) {
    const { data } = await api.get<ApiResponse<NoteRevision[]>>(`/notes/${noteId}/revisions`)
    revisions.value = data.data
    return data.data
  }

  async function fetchRevisionDetail(noteId: string, revisionId: string) {
    const { data } = await api.get<ApiResponse<NoteRevision>>(`/notes/${noteId}/revisions/${revisionId}`)
    return data.data
  }

  async function createRevision(noteId: string, changeSummary: string) {
    const { data } = await api.post<ApiResponse<NoteRevision>>(`/notes/${noteId}/revisions`, { changeSummary })
    revisions.value.unshift(data.data)
    return data.data
  }

  async function restoreRevision(noteId: string, revisionId: string) {
    const { data } = await api.post<ApiResponse<Note>>(`/notes/${noteId}/revisions/${revisionId}/restore`)
    const idx = notes.value.findIndex(n => n._id === noteId)
    if (idx !== -1) notes.value[idx] = data.data
    if (activeNote.value?._id === noteId) activeNote.value = data.data
    await fetchRevisions(noteId)
    return data.data
  }

  async function updateShareSettings(noteId: string, payload: { isPublic: boolean; slug?: string; password?: string | null }) {
    const { data } = await api.post<ApiResponse<{ _id: string; isPublic: boolean; slug: string; hasPassword: boolean; viewCount: number }>>(
      `/notes/${noteId}/share`,
      payload
    )
    if (activeNote.value?._id === noteId) {
      activeNote.value.isPublic = data.data.isPublic
      activeNote.value.slug = data.data.slug
      activeNote.value.hasPassword = data.data.hasPassword
      activeNote.value.viewCount = data.data.viewCount
    }
    const idx = notes.value.findIndex(n => n._id === noteId)
    if (idx !== -1) {
      notes.value[idx].isPublic = data.data.isPublic
      notes.value[idx].slug = data.data.slug
      notes.value[idx].hasPassword = data.data.hasPassword
      notes.value[idx].viewCount = data.data.viewCount
    }
    return data.data
  }

  async function fetchPublicNote(slug: string, password?: string) {
    loading.value = true
    try {
      const headers = password ? { 'x-share-password': password } : {}
      const { data } = await api.get<ApiResponse<Note>>(`/notes/slug/${slug}`, { headers })
      return data.data
    } finally {
      loading.value = false
    }
  }

  async function verifyPublicPassword(slug: string, password: string) {
    const { data } = await api.post<ApiResponse<Note>>(`/notes/slug/${slug}/verify`, { password })
    return data.data
  }

  return {
    notes, activeNote, revisions, loading,
    fetchNotes, fetchNote, createNote, saveNote, deleteNote, toggleFavorite,
    togglePin, setNoteColor, fetchRevisions, fetchRevisionDetail, createRevision, restoreRevision,
    updateShareSettings, fetchPublicNote, verifyPublicPassword,
  }
})
