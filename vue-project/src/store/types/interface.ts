// ─── User ──────────────────────────────────────────────
export interface User {
  _id: string
  name: string
  email: string
  avatar?: string
  bio?: string
  createdAt: string
}

// ─── Book ──────────────────────────────────────────────
export type BookStatus = 'draft' | 'published' | 'archived'
export type BookVisibility = 'private' | 'unlisted' | 'public'

export interface Book {
  _id: string
  title: string
  slug: string
  description?: string
  cover?: string
  author: User | string
  status: BookStatus
  visibility: BookVisibility
  chapters: Chapter[]
  tags: string[]
  wordCount: number
  createdAt: string
  updatedAt: string
}

// ─── Chapter ───────────────────────────────────────────
export interface Chapter {
  _id: string
  bookId: string
  title: string
  content: string          // Tiptap JSON stringified
  order: number
  wordCount: number
  createdAt: string
  updatedAt: string
}

// ─── API wrappers ──────────────────────────────────────
export interface ApiResponse<T> {
  success: boolean
  data: T
  message?: string
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number
    limit: number
    total: number
    pages: number
  }
}

export interface AuthTokens {
  accessToken: string
  refreshToken: string
  user: User
}