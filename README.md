# Caddo — WriteBook

A full-stack note-taking and writing application with mobile, web, and server components. Built with Flutter, Vue 3, and Hono/Node.js.

## 📱 Project Structure

```
Caddo_Note_Tacking_Project/
├── mobile/          # Flutter mobile app (iOS, Android, Web, Linux, macOS, Windows)
├── server/          # Hono + Node.js/TypeScript API server
└── vue-project/     # Vue 3 web application
```

---

## 🏗️ Architecture

### Mobile App (`mobile/`)

| | |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.12.2) |
| **State Management** | Riverpod |
| **Networking** | Dio |
| **Storage** | Flutter Secure Storage, Shared Preferences |
| **UI** | Material Design, Lucide Icons, Google Fonts |
| **Platforms** | iOS, Android, Web, Linux, macOS, Windows |

**Key Dependencies:**
- `flutter_riverpod` — State management
- `dio` — HTTP client
- `flutter_secure_storage` — Secure credential storage
- `shared_preferences` — Local key-value storage
- `image_picker` — Image selection
- `cached_network_image` — Image caching & loading
- `flutter_slidable` — Swipe-to-action list items
- `shimmer` — Loading skeleton effects
- `intl` — Internationalization & date formatting
- `google_fonts` — Custom typography
- `lucide_icons_flutter` — Icon set

---

### Server (`server/`)

| | |
|---|---|
| **Framework** | Hono (lightweight web framework) |
| **Runtime** | Node.js with TypeScript |
| **Database** | MongoDB with Mongoose |
| **Authentication** | JWT via Jose |
| **Validation** | Zod schema validation |
| **Security** | bcryptjs password hashing |
| **Caching** | LRU Cache |
| **Dev Server** | tsx (watch mode) |

**Key Dependencies:**
- `hono` + `@hono/node-server` — Web framework & Node adapter
- `mongoose` — MongoDB ODM
- `jose` — JWT token handling
- `zod` + `@hono/zod-validator` — Schema validation
- `bcryptjs` — Password encryption
- `lru-cache` — In-memory response caching
- `dotenv` — Environment variable management

**API Routes:**
| Route Module | Description |
|---|---|
| `auth` | Registration, login, JWT token management |
| `users` | User profiles & avatar uploads |
| `notes` | CRUD operations, rich-text content |
| `folders` | Folder organization |
| `tags` | Tag management |
| `workspaces` | Workspace isolation |
| `attachments` | File attachments |
| `settings` | User preferences & settings |

**Data Models:**
`User` · `Note` · `NoteRevision` · `Folder` · `Tag` · `Workspace` · `Attachment` · `UserSetting`

---

### Web App (`vue-project/`)

| | |
|---|---|
| **Framework** | Vue 3 (Composition API) |
| **Build Tool** | Vite 8 |
| **Styling** | Tailwind CSS 4 |
| **Rich Text Editor** | Tiptap 3 (extensive extensions) |
| **HTTP Client** | Axios |
| **State Management** | Pinia 3 |
| **Routing** | Vue Router 5 |
| **Icons** | Lucide Vue Next, Heroicons |
| **Date Handling** | date-fns |
| **Export** | jsPDF, jspdf-autotable, xlsx |
| **TypeScript** | TypeScript 6 |

**Key Dependencies:**
- `vue` 3 + `vue-router` 5 — Frontend framework & routing
- `pinia` 3 — State management
- `@tiptap/vue-3` + 17 extensions — Rich text editor with tables, images, links, task lists, text styling, character count, and more
- `axios` — HTTP client
- `tailwindcss` 4 + `@tailwindcss/vite` — Utility-first CSS
- `lucide-vue-next` + `@heroicons/vue` — Icon libraries
- `date-fns` — Date formatting & manipulation
- `jspdf` + `jspdf-autotable` — PDF export
- `xlsx` — Excel/spreadsheet export

**Tiptap Editor Extensions:**
Character Count · Color · Highlight · Image · Link · Placeholder · Subscript · Superscript · Table (+ Cell, Header, Row) · Task Item · Task List · Text Align · Text Style · Underline

---

## 🔐 Features

### Authentication & Users
- Secure JWT-based authentication (register / login)
- Password hashing with bcryptjs
- Secure token storage (Secure Storage on mobile, localStorage on web)
- User profiles with avatar uploads
- Per-user settings and preferences

### Note Management
- Create, read, update, and delete notes
- Rich text editing with Tiptap (bold, italic, underline, headings, lists, code blocks, links, images, tables, task lists, text color, highlight, alignment, subscript/superscript)
- **Revision history** — track and restore previous versions
- **Note statistics** — word count, character count, reading time
- **Note sharing** — public shareable links
- **Templates** — pre-built note templates via template gallery

### Organization
- **Workspaces** — isolate projects and contexts
- **Folders** — hierarchical folder structure
- **Tags** — label and filter notes with tags
- **Attachments** — file attachments on notes
- **Trash** — soft-delete with recovery

### Productivity
- **Command Palette** — quick navigation and actions (⌘K)
- **Keyboard Shortcuts** — comprehensive shortcut support
- **Dark Mode** — system-aware theme toggle
- **Export / Import** — PDF and Excel export, data import
- **Virtual Scrolling** — performant long note lists
- **Toast Notifications** — non-intrusive feedback

### Cross-Platform
- Responsive web interface
- Mobile apps for iOS, Android, and desktop platforms
- Synchronized data across all clients

---

## 📁 Project Structure Details

### Mobile App (`mobile/lib/`)
```
lib/
├── main.dart              # App entry point
├── core/
│   ├── api/               # API client configuration (Dio)
│   ├── models/            # Data models
│   ├── theme/             # App theming
│   └── widgets/           # Reusable widgets
└── features/
    ├── auth/              # Authentication screens & logic
    ├── notes/             # Notes feature
    └── settings/          # Settings feature
```

### Server (`server/src/`)
```
src/
├── index.ts               # Server entry point (Hono app)
├── config/
│   ├── db.ts              # MongoDB connection
│   ├── jwt.ts             # JWT configuration
│   └── cache.ts           # LRU Cache setup
├── middleware/
│   └── auth.ts            # Authentication middleware
├── models/
│   ├── User.ts            # User model
│   ├── Note.ts            # Note model
│   ├── NoteRevision.ts    # Revision history model
│   ├── Folder.ts          # Folder model
│   ├── Tag.ts             # Tag model
│   ├── Workspace.ts       # Workspace model
│   ├── Attachment.ts      # Attachment model
│   └── UserSetting.ts     # User settings model
└── routes/
    ├── auth.ts            # Auth routes
    ├── users.ts           # User routes
    ├── notes.ts           # Note CRUD routes
    ├── folders.ts         # Folder routes
    ├── tags.ts            # Tag routes
    ├── workspaces.ts      # Workspace routes
    ├── attachments.ts     # Attachment routes
    └── settings.ts        # Settings routes
```

### Web App (`vue-project/src/`)
```
src/
├── main.ts                # App entry point
├── App.vue                # Root component
├── api/
│   └── Api.ts             # Axios client configuration
├── assets/                # Static assets & styles
├── components/
│   ├── Sidebar.vue              # Main navigation sidebar
│   ├── NoteCard.vue             # Note list card component
│   ├── EditorToolbar.vue        # Rich text editor toolbar
│   ├── CommandPaletteModal.vue  # Command palette (⌘K)
│   ├── KeyboardShortcutsModal.vue
│   ├── ShareModal.vue           # Note sharing dialog
│   ├── TemplateGalleryModal.vue # Note templates
│   ├── AttachmentsDrawer.vue    # Attachments panel
│   ├── NoteStatsDrawer.vue      # Word/char count stats
│   ├── RevisionHistoryDrawer.vue # Version history
│   ├── ToastContainer.vue       # Toast notification layer
│   ├── Toastnotification.vue    # Individual toast
│   ├── Header.vue               # Page header
│   └── layout/                  # Layout components
├── composable/
│   ├── Darkmode.ts              # Dark mode toggle
│   ├── Userwritebookeditor.ts   # Editor logic composable
│   ├── useExportImport.ts       # PDF/Excel export & import
│   └── useToast.ts              # Toast notification composable
├── composables/
│   └── useVirtualScroll.ts      # Virtual scrolling for lists
├── routes/
│   └── index.ts                 # Vue Router configuration
├── store/
│   ├── auth.ts                  # Auth store (Pinia)
│   ├── notes.ts                 # Notes store (Pinia)
│   ├── sidebar.ts               # Sidebar state store
│   └── types/
│       └── interface.ts         # TypeScript interfaces
└── views/
    ├── auth/
    │   ├── Login.vue            # Login page
    │   └── Register.vue         # Registration page
    ├── HomeViews.vue            # Home / dashboard
    ├── AllNotes.vue             # All notes listing
    ├── Notes.vue                # Notes view
    ├── NoteDetail.vue           # Single note detail
    ├── NewNote.vue              # Create new note
    ├── Editor.vue               # Full editor view
    ├── Folder.vue               # Folder view
    ├── Workspace.vue            # Workspace view
    ├── Trash.vue                # Trash / deleted notes
    ├── Profile.vue              # User profile
    ├── ProfileSettings.vue      # Profile & app settings
    ├── Settings.vue             # Settings page
    ├── ReadViews.vue            # Read-only note view
    ├── PublicNoteView.vue       # Shared public note
    └── NotFoundView.vue         # 404 page
```

---

## 🚀 Getting Started

### Prerequisites

| Component | Requirement |
|---|---|
| Mobile | Flutter SDK (^3.12.2) |
| Server | Node.js (^20.19.0 or ≥22.12.0), MongoDB |
| Web | Node.js (^20.19.0 or ≥22.12.0) |

### Installation & Setup

#### 1. Server
```bash
cd server
npm install

# Create .env file
cp .env.example .env   # or create manually (see below)

npm run dev             # Development with hot reload (tsx watch)
```

#### 2. Web App
```bash
cd vue-project
npm install
npm run dev             # Development server (Vite)
```

#### 3. Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

---

## 📝 Environment Setup

### Server `.env`
Create a `.env` file in the `server/` directory:
```env
DATABASE_URL=mongodb://localhost:27017/caddo
JWT_SECRET=your_jwt_secret_key
PORT=3000
NODE_ENV=development
```

### Web App `.env.local`
Create a `.env.local` file in `vue-project/`:
```env
VITE_API_URL=http://localhost:3000/api
```

---

## 📜 Available Scripts

### Mobile
| Command | Description |
|---|---|
| `flutter run` | Run on connected device/emulator |
| `flutter test` | Run tests |
| `flutter build apk` | Build Android APK |
| `flutter build ios` | Build iOS app |
| `flutter build web` | Build web version |

### Server
| Command | Description |
|---|---|
| `npm run dev` | Start development server with hot reload |
| `npm run build` | Compile TypeScript to JavaScript |
| `npm start` | Start production server |
| `npm run lint` | Run ESLint |

### Web App
| Command | Description |
|---|---|
| `npm run dev` | Start Vite dev server |
| `npm run build` | Type-check & build for production |
| `npm run build-only` | Build without type checking |
| `npm run type-check` | Run `vue-tsc` type checking |
| `npm run preview` | Preview production build |

---

## 🔗 API Overview

### Base URL
- **Development:** `http://localhost:3000/api`
- **Production:** Configure via environment variables

### Authentication Flow
1. User registers or logs in via web or mobile client
2. Server validates credentials and returns a JWT token
3. Token stored securely (Secure Storage on mobile, localStorage on web)
4. Token included as `Authorization: Bearer <token>` in subsequent requests

### API Endpoints
| Endpoint Group | Methods | Description |
|---|---|---|
| `/api/auth` | POST | Register, login |
| `/api/users` | GET, PUT | Profile, avatar |
| `/api/notes` | GET, POST, PUT, DELETE | Note CRUD & search |
| `/api/folders` | GET, POST, PUT, DELETE | Folder management |
| `/api/tags` | GET, POST, PUT, DELETE | Tag management |
| `/api/workspaces` | GET, POST, PUT, DELETE | Workspace management |
| `/api/attachments` | GET, POST, DELETE | File attachments |
| `/api/settings` | GET, PUT | User preferences |

---

## 🛠️ Technology Summary

| Layer | Technology | Version | Purpose |
|---|---|---|---|
| Frontend (Mobile) | Flutter | SDK ^3.12.2 | Cross-platform mobile UI |
| Frontend (Web) | Vue 3 + Vite | Vue 3.5, Vite 8 | Modern web application |
| Backend | Hono + Node.js | Hono 4.6 | Lightweight API server |
| Database | MongoDB + Mongoose | Mongoose 8.9 | Data persistence |
| Authentication | JWT (Jose) + bcryptjs | — | Secure auth |
| State Management | Riverpod (Mobile) / Pinia (Web) | — | State handling |
| Styling | Tailwind CSS 4 | — | Utility-first CSS |
| Rich Text Editor | Tiptap 3 | — | Advanced text editing |
| Export | jsPDF + xlsx | — | PDF & Excel generation |
| Icons | Lucide + Heroicons | — | UI icon sets |

---

## 📚 Documentation

Refer to individual README files in each subproject:
- [Mobile README](./mobile/README.md)
- [Server README](./server/README.md)
- [Web Project README](./vue-project/README.md)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly across platforms
4. Submit a pull request

## 📄 License

[Add your license information here]

## 📞 Support

For issues or questions, please open an issue in the repository.
