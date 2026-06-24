---
name: optimizecode
description: Writebox project-specific optimization skill. Use when fixing bugs, adding missing files, refactoring, or updating models in the Writebox markdown note-taking app (Vue 3 frontend + Hono/Node backend + MongoDB). Covers all known gaps, crash-level bugs, missing routes, model overlaps, and code patterns.
---

# Writebox — Optimize & Complete Codebase

Writebox is a minimal personal markdown note-taking app — think Obsidian/Notion but self-built and lightweight.
Stack: **Vue 3 + Vite + TypeScript + Pinia + Tiptap** (frontend) / **Hono v4 + Node + Mongoose + jose + Zod** (backend).

Core domain: **Notes** organized into **Folders** inside **Workspaces**, tagged with **Tags**.
There are NO books, NO chapters — every document is just a Note.

---

## Project Layout

```
Caddo_WriteBook_Project/
├── vue-project/          # Frontend (port 5001, proxies /api → localhost:3000)
│   └── src/
│       ├── api/Api.ts             # Axios instance, auto-refresh interceptor
│       ├── components/            # EditorToolbar, Header, Sidebar, AppLayout, Toastnotification (EMPTY)
│       ├── composable/            # useDarkMode, useWritebookEditor (Tiptap)
│       ├── routes/index.ts        # vue-router, nav guards
│       ├── store/                 # auth.ts, books.ts (MISNAMED — should be notes.ts), types/interface.ts
│       └── views/                 # HomeViews, Login, Register, Note, Books, NewBook, Editor,
│                                  # Library, ReadViews, Settings, NotFoundView
└── server/               # Backend (port 3000)
    └── src/
        ├── config/        # db.ts, jwt.ts
        ├── middleware/    # auth.ts
        ├── models/        # User, UserSetting, Workspace, Folder, Note, NoteRevision, Tag, Attachment
        └── routes/        # auth.ts ✅  users.ts ✅  books.ts ❌ MISSING (crash)
```

---

## Crash-Level Bugs — Fix These First

### 1. `server/src/routes/books.ts` is imported but does not exist — SERVER WON'T START
`index.ts` tries to import `./routes/books` which is missing.
**Fix**: Replace it with `./routes/notes`. Create `server/src/routes/notes.ts` for the Note model, then update the mount in `index.ts`:
```ts
// index.ts — replace
import booksRouter from './routes/books.js'
app.route('/books', booksRouter)

// with
import notesRouter from './routes/notes.js'
app.route('/notes', notesRouter)
```

### 2. `Note.vue` is an exact duplicate of `Books.vue`
`/app/note` renders `Note.vue` which tries to use `:bookId` param — crashes blank every time.
`Note.vue` should be the **main notes dashboard**: list all notes, recent edits, quick-create button. Rewrite it completely (see view guide below).

### 3. Wrong redirect in `NewBook.vue`
This view is misnamed — it creates a note, not a book. Rename the file to `NewNote.vue` and fix the redirect:
```ts
// WRONG
router.push(`/app/notes/${note._id}`)  // route doesn't exist

// CORRECT (after adding the note detail route)
router.push(`/app/notes/${note._id}`)  // only works once the route exists in index.ts
```
Also update `routes/index.ts` to register `/app/notes/:noteId` and `/app/notes/new`.

### 4. Editor route missing `name: 'editor'`
`AppLayout.vue` hides the header when `route.name === 'editor'`, but the editor route in `routes/index.ts` has no `name` property — so the header always overlaps the editor.
Add `name: 'editor'` to the note-edit route.

---

## What to Rename / Repurpose

The frontend has book-flavored names that need to become note-flavored:

| Current | Should Be | Action |
|---|---|---|
| `store/books.ts` | `store/notes.ts` | Rename + rewrite actions for Note model |
| `views/Books.vue` | `views/NoteDetail.vue` | Rename + rewrite — show single note with edit button |
| `views/NewBook.vue` | `views/NewNote.vue` | Rename + rewrite — create note form |
| `views/Note.vue` | `views/Notes.vue` (dashboard) | Rewrite completely as notes list |
| `views/Library.vue` | Keep or merge into Notes dashboard | Shows note grid — wire into router |
| `views/ReadViews.vue` | Keep as public shared-note reader | Already uses slug, keep it |
| `store/types/interface.ts` | Update interfaces | Replace `Book`/`Chapter` with `Note` |

---

## Missing Files to Create

### Backend

| File | What to build |
|---|---|
| `server/src/routes/notes.ts` | Full CRUD for the `Note` model. Protected by `authMiddleware`. Validate with Zod. See routes below. |
| `server/src/routes/tags.ts` | CRUD for `Tag` model. |
| `server/src/routes/workspaces.ts` | CRUD for `Workspace` model. |
| `server/src/routes/folders.ts` | CRUD for `Folder` model (nested via `parentId`, soft delete via `isDeleted`). |
| `server/src/routes/settings.ts` | `GET /settings/me`, `PATCH /settings/me` for `UserSetting`. |

### Frontend

| File | What to build |
|---|---|
| `src/components/Toastnotification.vue` | Toast/snackbar. Props: `message: string`, `type: 'success' \| 'error' \| 'info'`, `duration?: number`. Use `v-if` + CSS transition. |
| `src/composable/useToast.ts` | Global toast queue: `{ toasts, showToast(msg, type), removeToast(id) }`. Reactive array of `{ id, message, type }`. |
| `src/assets/Ui/NoteCard.vue` | Card used by the notes grid/library. Props: `note: Note`. Shows title, content preview (first 120 chars), tags, folder name, `formatDistanceToNow` date from `date-fns`. |
| `src/store/notes.ts` | Pinia store replacing `books.ts`. State: `notes[]`, `activeNote`, `loading`. Actions for full CRUD + search. |

---

## Notes Route — Full Spec

```
GET    /api/v1/notes                   list user notes (?folderId=&workspaceId=&tag=&search=)
POST   /api/v1/notes                   create note
GET    /api/v1/notes/:id               get note
PATCH  /api/v1/notes/:id               update note (title, content, tagIds, isFavorite, folderId)
DELETE /api/v1/notes/:id               soft delete (set isDeleted=true, deletedAt=now)
GET    /api/v1/notes/slug/:slug        public note by slug (no auth required)
GET    /api/v1/notes/favorites         list favorite notes
GET    /api/v1/notes/trash             list soft-deleted notes
POST   /api/v1/notes/:id/restore       unset isDeleted
DELETE /api/v1/notes/:id/permanent     hard delete (trash only)
```

All except `GET /notes/slug/:slug` require `authMiddleware`.

---

## Note Model (already exists at `server/src/models/Note.ts`)

Fields already there — **do not recreate**:
- `userId`, `workspaceId`, `folderId` (null = workspace root)
- `title`, `content` (Tiptap JSON string)
- `tagIds[]`, `isFavorite`, `isDeleted`, `deletedAt`, `version`
- Indexes: `(userId, workspaceId, folderId, isDeleted, updatedAt DESC)` + `(userId, tagIds)`

Add a `slug` field if you want public sharing (`GET /notes/slug/:slug`):
```ts
slug: { type: String, unique: true, sparse: true }
```
Auto-generate from `title` in a `pre('save')` hook (only when not already set).

---

## Frontend Store — `notes.ts` Pattern

```ts
// store/notes.ts
import { defineStore } from 'pinia'
import api from '@/api/Api'
import type { Note, ApiResponse, PaginatedResponse } from './types/interface'

export const useNotesStore = defineStore('notes', {
  state: () => ({
    notes: [] as Note[],
    activeNote: null as Note | null,
    loading: false,
  }),
  actions: {
    async fetchNotes(params?: { folderId?: string; workspaceId?: string }) {
      this.loading = true
      try {
        const res = await api.get<ApiResponse<Note[]>>('/notes', { params })
        this.notes = res.data.data
      } finally {
        this.loading = false
      }
    },
    async fetchNote(id: string) {
      const res = await api.get<ApiResponse<Note>>(`/notes/${id}`)
      this.activeNote = res.data.data
      return res.data.data
    },
    async createNote(payload: Partial<Note>) {
      const res = await api.post<ApiResponse<Note>>('/notes', payload)
      this.notes.unshift(res.data.data)
      return res.data.data
    },
    async saveNote(id: string, payload: Partial<Note>) {
      const res = await api.patch<ApiResponse<Note>>(`/notes/${id}`, payload)
      const idx = this.notes.findIndex(n => n._id === id)
      if (idx !== -1) this.notes[idx] = res.data.data
      this.activeNote = res.data.data
      return res.data.data
    },
    async deleteNote(id: string) {
      await api.delete(`/notes/${id}`)
      this.notes = this.notes.filter(n => n._id !== id)
    },
  },
})
```

---

## `types/interface.ts` — Target Shape

Replace `Book`/`Chapter` interfaces with:
```ts
export interface Note {
  _id: string
  userId: string
  workspaceId?: string
  folderId?: string | null
  title: string
  content: string         // Tiptap JSON string
  slug?: string
  tagIds: string[]
  isFavorite: boolean
  isDeleted: boolean
  deletedAt?: string
  version: number
  createdAt: string
  updatedAt: string
}

export interface Tag {
  _id: string
  userId: string
  name: string
  color: string
  icon?: string
}

export interface Folder {
  _id: string
  userId: string
  workspaceId: string
  parentId?: string | null
  name: string
  icon?: string
  order: number
}

export interface Workspace {
  _id: string
  userId: string
  name: string
  icon?: string
  color?: string
  isActive: boolean
}
```

---

## View Guide — What Each View Should Do

| View | Route | Purpose |
|---|---|---|
| `Notes.vue` (rewrite of `Note.vue`) | `/app/notes` | Dashboard: list all notes, search bar, filter by tag/folder, quick-create FAB |
| `NoteDetail.vue` (rewrite of `Books.vue`) | `/app/notes/:noteId` | Show single note metadata, tags, folder; link to editor |
| `NewNote.vue` (rewrite of `NewBook.vue`) | `/app/notes/new` | Create note form: title (required), select folder, select workspace, add tags |
| `Editor.vue` | `/app/notes/:noteId/edit` | Full-screen Tiptap editor, autosave, word count (already mostly correct) |
| `Library.vue` | `/app/library` | Note card grid — add this route; uses `NoteCard.vue` |
| `ReadViews.vue` | `/read/:slug` | Public shared note reader — keep as-is |
| `Settings.vue` | `/app/settings` | Already correct — calls `PATCH /users/me` |

---

## Router — Correct Route Definitions

```ts
// routes/index.ts — auth-required subtree
{
  path: '/app',
  component: AppLayout,
  meta: { requiresAuth: true },
  children: [
    { path: 'notes',              name: 'notes',       component: () => import('@/views/Notes.vue') },
    { path: 'notes/new',          name: 'new-note',    component: () => import('@/views/NewNote.vue') },
    { path: 'notes/:noteId',      name: 'note',        component: () => import('@/views/NoteDetail.vue') },
    { path: 'notes/:noteId/edit', name: 'editor',      component: () => import('@/views/Editor.vue') },
    { path: 'library',            name: 'library',     component: () => import('@/views/Library.vue') },
    { path: 'settings',           name: 'settings',    component: () => import('@/views/Settings.vue') },
  ]
}
```

`name: 'editor'` is required — `AppLayout.vue` checks it to hide the top header.

---

## Missing Features (Wired but Not Implemented)

### Dark mode toggle
`useDarkMode` composable exists but is never used anywhere. Wire it into `Sidebar.vue` or `Settings.vue`. The composable already handles `localStorage` + `document.documentElement.dataset.theme` — just call `toggle()` from a button.

### `date-fns` unused
In `dependencies` but never imported. Use it in `NoteCard.vue`:
```ts
import { formatDistanceToNow } from 'date-fns'
formatDistanceToNow(new Date(note.updatedAt), { addSuffix: true }) // "3 minutes ago"
```

### Drag-and-drop folder ordering
`Folder` model has an `order` field. If you add folder reordering in the sidebar, use `@vueuse/core` `useSortable` or `vue-draggable-plus`.

---

## Model Update Guide

When adding or changing Mongoose models:

1. **Always export a TypeScript interface** extending `Document`:
```ts
export interface INote extends Document {
  userId: mongoose.Types.ObjectId
  title: string
  content: string
  // ...
}
export const Note = mongoose.model<INote>('Note', noteSchema)
export default Note
```

2. **Mount the route in `index.ts`** — Hono does not auto-scan:
```ts
import notesRouter from './routes/notes.js'
app.route('/notes', notesRouter)
```

3. **Sync `vue-project/src/store/types/interface.ts`** whenever a model field changes. Frontend and backend types must stay in sync.

4. **Fix `User.preferences` / `UserSetting` overlap**:
   - `User.preferences` (theme, defaultView, fontSize) is embedded — fine for fast auth responses.
   - `UserSetting` holds the full settings (font family, spellcheck, autoSave, sidebar, revisions) — lazy-load on the Settings page.
   - Never write the same value to both; treat `UserSetting` as the source of truth for Settings page.

5. **Auto-create `UserSetting` on register** — add after user creation in `routes/auth.ts`:
```ts
await UserSetting.create({ userId: user._id })
```

---

## Backend Patterns to Follow

### Hono route structure
```ts
import { Hono } from 'hono'
import { zValidator } from '@hono/zod-validator'
import { z } from 'zod'
import { authMiddleware } from '../middleware/auth.js'
import Note from '../models/Note.js'
import type { IUser } from '../models/User.js'

const notes = new Hono()
notes.use('*', authMiddleware)

notes.get('/', async (c) => {
  const user = c.get('user') as IUser
  const { folderId, workspaceId } = c.req.query()
  const filter: Record<string, unknown> = { userId: user._id, isDeleted: false }
  if (folderId) filter.folderId = folderId
  if (workspaceId) filter.workspaceId = workspaceId
  const noteList = await Note.find(filter).sort({ updatedAt: -1 })
  return c.json({ success: true, data: noteList })
})

export default notes
```

### Hono Variables typing — fix untyped `c.get('user')`
```ts
// src/index.ts
import type { IUser } from './models/User.js'
type Variables = { user: IUser }
const app = new Hono<{ Variables: Variables }>()
// Pass the same generic to each sub-router too
const notes = new Hono<{ Variables: Variables }>()
```

### Response shape — always match `ApiResponse<T>`
```ts
return c.json({ success: true,  data: note }, 200)
return c.json({ success: false, error: 'Not found' }, 404)
return c.json({ success: false, error: 'Unauthorized' }, 401)
```

### JWT security — remove hardcoded fallback secrets
```ts
// config/jwt.ts — BEFORE (insecure)
const secret = process.env.JWT_ACCESS_SECRET ?? 'change-me-access'

// AFTER — fail fast in all environments
const secret = process.env.JWT_ACCESS_SECRET
if (!secret) throw new Error('JWT_ACCESS_SECRET env var is required')
```

---

## Tailwind Palette — Always Use These Tokens

| Token | Use |
|---|---|
| `text-ink-*` / `bg-ink-*` (50–950) | All neutral text and backgrounds |
| `bg-ink-950` | Sidebar background |
| `text-amber-*` / `bg-amber-*` | Accent, highlights, active states |
| `bg-parchment` | Main content area background |
| `font-display` | Headings (Playfair Display) |
| `font-body` | Body copy (Source Serif 4) |
| `font-mono` | Code blocks (JetBrains Mono) |
| `font-ui` | UI labels, buttons (Inter) |

Never use raw hex values. Always use these palette tokens.

---

## Tiptap Content Pattern

The editor stores and reads content as **Tiptap JSON** (not HTML, not plain Markdown).

```ts
// Writing — useWritebookEditor composable already handles this
editor.getJSON()  // returns object → JSON.stringify before storing

// Reading in ReadViews.vue / NoteDetail.vue
import { generateHTML } from '@tiptap/html'
import StarterKit from '@tiptap/starter-kit'
const html = generateHTML(JSON.parse(note.content), [StarterKit])
```

---

## Security Checklist

- [ ] Remove hardcoded JWT fallback secrets (`config/jwt.ts`)
- [ ] Move CORS allowed origins to an env var (currently hardcoded `localhost:5173`, `localhost:3001`)
- [ ] Refresh token not stored server-side — add a MongoDB TTL blocklist before shipping
- [ ] All note/folder/workspace routes: verify `userId` ownership before returning or mutating
- [ ] `Attachment.ts` model exists but has no route — do not expose until a storage provider is chosen

---

## Quick Reference: All API Endpoints (Target State)

```
POST   /api/v1/auth/register
POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout

GET    /api/v1/users/me
PATCH  /api/v1/users/me

GET    /api/v1/settings/me
PATCH  /api/v1/settings/me

GET    /api/v1/notes                       (auth, ?folderId=&workspaceId=&tag=&search=)
POST   /api/v1/notes                       (auth)
GET    /api/v1/notes/favorites             (auth)
GET    /api/v1/notes/trash                 (auth)
GET    /api/v1/notes/slug/:slug            (public)
GET    /api/v1/notes/:id                   (auth)
PATCH  /api/v1/notes/:id                   (auth)
DELETE /api/v1/notes/:id                   (auth — soft delete)
POST   /api/v1/notes/:id/restore           (auth)
DELETE /api/v1/notes/:id/permanent         (auth — hard delete from trash)

GET    /api/v1/workspaces                  (auth)
POST   /api/v1/workspaces                  (auth)
PATCH  /api/v1/workspaces/:id              (auth)
DELETE /api/v1/workspaces/:id              (auth)

GET    /api/v1/folders                     (auth, ?workspaceId=)
POST   /api/v1/folders                     (auth)
PATCH  /api/v1/folders/:id                 (auth)
DELETE /api/v1/folders/:id                 (auth — soft delete)

GET    /api/v1/tags                        (auth)
POST   /api/v1/tags                        (auth)
PATCH  /api/v1/tags/:id                    (auth)
DELETE /api/v1/tags/:id                    (auth)
```
