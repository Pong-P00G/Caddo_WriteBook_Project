# Writebook

A full-stack book writing & publishing platform built with **Vue 3 + TypeScript**, **Tailwind CSS**, **Hono**, and **MongoDB**.

---

## Stack

| Layer     | Technology                          |
|-----------|-------------------------------------|
| Frontend  | Vue 3, TypeScript, Vite             |
| Styling   | Tailwind CSS v3, custom design system |
| Editor    | Tiptap (rich text, autosave)        |
| State     | Pinia                               |
| Routing   | Vue Router 4                        |
| Backend   | Hono (on Node.js via @hono/node-server) |
| Database  | MongoDB via Mongoose                |
| Auth      | JWT (access + httpOnly refresh cookie) |

---

## Project Structure

```
writebook/
├── client/                     # Vue 3 frontend
│   ├── src/
│   │   ├── assets/             # Global CSS (Tailwind)
│   │   ├── components/
│   │   │   ├── books/          # BookCard
│   │   │   ├── editor/         # EditorToolbar
│   │   │   └── layout/         # AppSidebar, AppHeader
│   │   ├── composables/        # useWritebookEditor (Tiptap)
│   │   ├── layout/             # AppLayout (shell)
│   │   ├── router/             # Vue Router config
│   │   ├── stores/             # Pinia (auth, books)
│   │   ├── types/              # Shared TypeScript interfaces
│   │   ├── utils/              # Axios API client
│   │   └── views/              # Pages
│   ├── tailwind.config.ts
│   └── vite.config.ts
│
├── server/                     # Hono API
│   └── src/
│       ├── config/             # db.ts (MongoDB), jwt.ts
│       ├── middleware/         # auth.ts (JWT guard)
│       ├── models/             # User, Book, Chapter (Mongoose)
│       ├── routes/             # auth.ts, books.ts, users.ts
│       └── index.ts            # Entry point
│
└── package.json                # Workspaces root
```

---

## Getting Started

### Prerequisites

- Node.js ≥ 20
- MongoDB (local or Atlas)

### 1. Install dependencies

```bash
npm install
```

### 2. Configure the server

```bash
cp server/.env.example server/.env
# Edit server/.env — set MONGODB_URI and JWT secrets
```

### 3. Run in development

```bash
npm run dev
```

- Frontend: http://localhost:5173
- API: http://localhost:3000/api/v1

### 4. Build for production

```bash
npm run build
```

---

## API Reference

### Auth

| Method | Path                  | Auth | Description          |
|--------|-----------------------|------|----------------------|
| POST   | `/auth/register`      | No   | Create account       |
| POST   | `/auth/login`         | No   | Sign in              |
| POST   | `/auth/refresh`       | No   | Refresh access token |
| POST   | `/auth/logout`        | No   | Clear refresh cookie |

### Books

| Method | Path                              | Auth | Description               |
|--------|-----------------------------------|------|---------------------------|
| GET    | `/books/mine`                     | Yes  | List your books           |
| GET    | `/books/slug/:slug`               | No   | Get published book        |
| GET    | `/books/:id`                      | Yes  | Get book detail           |
| POST   | `/books`                          | Yes  | Create book               |
| PATCH  | `/books/:id`                      | Yes  | Update book               |
| DELETE | `/books/:id`                      | Yes  | Delete book               |
| GET    | `/books/:id/chapters/:chId`       | Yes  | Get chapter               |
| POST   | `/books/:id/chapters`             | Yes  | Create chapter            |
| PATCH  | `/books/:id/chapters/reorder`     | Yes  | Reorder chapters          |
| PATCH  | `/books/:id/chapters/:chId`       | Yes  | Save chapter content      |
| DELETE | `/books/:id/chapters/:chId`       | Yes  | Delete chapter            |

### Users

| Method | Path        | Auth | Description     |
|--------|-------------|------|-----------------|
| GET    | `/users/me` | Yes  | Get profile     |
| PATCH  | `/users/me` | Yes  | Update profile  |

---

## Key Features

- **Rich editor** — Tiptap with headings, blockquote, code, lists, links, images
- **Autosave** — debounced 1.5 s after each keystroke, visual "Saved" indicator
- **Chapter management** — create, reorder (drag handle ready), delete
- **Visibility control** — private / unlisted / public per book
- **JWT auth** — short-lived access token + httpOnly refresh cookie
- **Public reader** — `/read/:slug` renders Tiptap JSON to HTML
- **Word count** — tracked per chapter, aggregated to book level

---

## Customisation

### Design tokens (Tailwind)

Edit `client/tailwind.config.ts` to change:
- `colors.ink` — greyscale palette
- `colors.amber` — accent colour
- `colors.parchment` — page background
- `fontFamily` — display / body / mono / ui fonts

### Editor extensions

Add Tiptap extensions in `client/src/composables/useWritebookEditor.ts`.

### Auth strategy

Swap `jose` for any JWT library in `server/src/config/jwt.ts`.