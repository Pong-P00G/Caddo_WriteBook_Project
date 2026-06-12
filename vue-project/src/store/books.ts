import { defineStore } from 'pinia'
import { ref } from 'vue'
import api from '../api/Api'
import type { Book, Chapter } from './types/interface'

export const useBooksStore = defineStore('books', () => {
  const books        = ref<Book[]>([])
  const activeBook   = ref<Book | null>(null)
  const activeChapter = ref<Chapter | null>(null)
  const loading      = ref(false)

  // ── Books ──────────────────────────────────────────
  async function fetchMyBooks() {
    loading.value = true
    try {
      const { data } = await api.get<{ data: Book[] }>('/books/mine')
      books.value = data.data
    } finally {
      loading.value = false
    }
  }

  async function fetchBook(bookId: string) {
    loading.value = true
    try {
      const { data } = await api.get<{ data: Book }>(`/books/${bookId}`)
      activeBook.value = data.data
      return data.data
    } finally {
      loading.value = false
    }
  }

  async function createBook(payload: Partial<Book>) {
    const { data } = await api.post<{ data: Book }>('/books', payload)
    books.value.unshift(data.data)
    return data.data
  }

  async function updateBook(bookId: string, payload: Partial<Book>) {
    const { data } = await api.patch<{ data: Book }>(`/books/${bookId}`, payload)
    const idx = books.value.findIndex(b => b._id === bookId)
    if (idx !== -1) books.value[idx] = data.data
    if (activeBook.value?._id === bookId) activeBook.value = data.data
    return data.data
  }

  async function deleteBook(bookId: string) {
    await api.delete(`/books/${bookId}`)
    books.value = books.value.filter(b => b._id !== bookId)
  }

  // ── Chapters ──────────────────────────────────────
  async function fetchChapter(bookId: string, chapterId: string) {
    const { data } = await api.get<{ data: Chapter }>(`/books/${bookId}/chapters/${chapterId}`)
    activeChapter.value = data.data
    return data.data
  }

  async function createChapter(bookId: string, title: string) {
    const { data } = await api.post<{ data: Chapter }>(`/books/${bookId}/chapters`, { title })
    if (activeBook.value?._id === bookId) {
      activeBook.value.chapters.push(data.data)
    }
    return data.data
  }

  async function saveChapter(bookId: string, chapterId: string, content: string) {
    const { data } = await api.patch<{ data: Chapter }>(
      `/books/${bookId}/chapters/${chapterId}`,
      { content }
    )
    activeChapter.value = data.data
    return data.data
  }

  async function deleteChapter(bookId: string, chapterId: string) {
    await api.delete(`/books/${bookId}/chapters/${chapterId}`)
    if (activeBook.value?._id === bookId) {
      activeBook.value.chapters = activeBook.value.chapters.filter(c => c._id !== chapterId)
    }
  }

  async function reorderChapters(bookId: string, orderedIds: string[]) {
    await api.patch(`/books/${bookId}/chapters/reorder`, { orderedIds })
  }

  return {
    books, activeBook, activeChapter, loading,
    fetchMyBooks, fetchBook, createBook, updateBook, deleteBook,
    fetchChapter, createChapter, saveChapter, deleteChapter, reorderChapters,
  }
})