# Caddo Note Tracking Project

A full-stack note tracking application with mobile, web, and server components. Built with Flutter, Vue.js, and Node.js/TypeScript.

## 📱 Project Structure

```
Caddo_Note_Tacking_Project/
├── mobile/          # Flutter mobile app (iOS, Android, Web, Linux, macOS, Windows)
├── server/          # Node.js/TypeScript API server
└── vue-project/     # Vue 3 web application
```

## 🏗️ Architecture

### Mobile App (`mobile/`)
- **Framework**: Flutter
- **State Management**: Riverpod
- **Networking**: Dio
- **Storage**: Flutter Secure Storage, Shared Preferences
- **UI Components**: Material Design, Lucide Icons, Google Fonts
- **Platforms**: iOS, Android, Web, Linux, macOS, Windows

**Key Dependencies:**
- `flutter_riverpod`: State management
- `dio`: HTTP client
- `flutter_secure_storage`: Secure credential storage
- `image_picker`: Image selection
- `intl`: Internationalization

### Server (`server/`)
- **Framework**: Hono (lightweight web framework)
- **Runtime**: Node.js with TypeScript
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT with Jose
- **Validation**: Zod for schema validation
- **Security**: bcryptjs for password hashing
- **Caching**: LRU Cache

**Key Dependencies:**
- `hono`: Web framework
- `mongoose`: MongoDB ODM
- `jose`: JWT handling
- `zod`: Schema validation
- `bcryptjs`: Password encryption

### Web App (`vue-project/`)
- **Framework**: Vue 3
- **Build Tool**: Vite
- **Styling**: Tailwind CSS
- **Editor**: Tiptap (rich text editor)
- **HTTP Client**: Axios
- **Date Handling**: date-fns
- **Export**: jsPDF for document generation

**Key Dependencies:**
- `vue 3`: Frontend framework
- `@tiptap/vue-3`: Rich text editor
- `tailwindcss`: Utility-first CSS
- `axios`: HTTP client
- `pinia`: State management (implied from structure)
- `vue-router`: Routing

## 🚀 Getting Started

### Prerequisites
- **Mobile**: Flutter SDK (^3.12.2)
- **Server**: Node.js (v18+), MongoDB
- **Web**: Node.js (v18+)

### Installation & Setup

#### Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

#### Server
```bash
cd server
npm install
npm run dev          # Development with hot reload
npm run build        # Build TypeScript
npm start            # Run production build
```

#### Web App
```bash
cd vue-project
npm install
npm run dev          # Development server (Vite)
npm run build        # Production build
npm run preview      # Preview production build
```

## 📝 Development

### Environment Setup

#### Server Environment Variables
Create a `.env` file in the `server/` directory:
```
DATABASE_URL=mongodb://localhost:27017/caddo
JWT_SECRET=your_jwt_secret_key
PORT=3000
NODE_ENV=development
```

#### Web App Environment
Create a `.env.local` file in `vue-project/`:
```
VITE_API_URL=http://localhost:3000/api
```

### Scripts

**Mobile:**
- `flutter run`: Run on connected device/emulator
- `flutter test`: Run tests

**Server:**
- `npm run dev`: Start development server with hot reload
- `npm run build`: Compile TypeScript to JavaScript
- `npm start`: Start production server
- `npm run lint`: Run ESLint

**Web:**
- `npm run dev`: Start Vite dev server
- `npm run build`: Build for production
- `npm run type-check`: Run TypeScript type checking
- `npm run preview`: Preview production build

## 🔐 Features

### Authentication
- Secure JWT-based authentication
- Password hashing with bcryptjs
- Secure token storage in mobile app
- Session management

### Note Management
- Create, read, update, delete notes
- Rich text editing with Tiptap
- Image attachment support
- Note categories/organization

### User Features
- User authentication and profiles
- Avatar uploads
- Settings management
- Cross-platform synchronization

## 📁 Project Structure Details

### Mobile App (`lib/`)
```
lib/
├── main.dart           # App entry point
├── core/
│   ├── api/           # API client configuration
│   ├── models/        # Data models
│   ├── theme/         # App theming
│   └── widgets/       # Reusable widgets
└── features/
    ├── auth/          # Authentication feature
    ├── notes/         # Notes feature
    └── settings/      # Settings feature
```

### Server (`src/`)
```
src/
├── index.ts           # Server entry point
├── config/            # Configuration files
├── middleware/        # Hono middleware
├── models/            # Mongoose models
└── routes/            # API routes
```

### Web App (`src/`)
```
src/
├── main.ts            # App entry point
├── App.vue            # Root component
├── api/               # API client services
├── assets/            # Static assets
├── components/        # Vue components
├── composable/        # Vue composables
├── routes/            # Vue Router configuration
├── store/             # State management
└── views/             # Page components
```

## 🔗 API Integration

### Base URL
- Development: `http://localhost:3000/api`
- Production: `https://api.example.com`

### Authentication Flow
1. User registers/logs in via web or mobile
2. Server returns JWT token
3. Token stored securely (secure storage on mobile, localStorage on web)
4. Token included in subsequent API requests

## 📦 Build & Deployment

### Mobile
```bash
cd mobile
flutter build apk       # Android APK
flutter build ios       # iOS app
flutter build web       # Web build
```

### Server
```bash
cd server
npm run build
npm start
```

### Web
```bash
cd vue-project
npm run build
# Deploy dist/ folder to hosting service
```

## 🛠️ Technologies Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend (Mobile) | Flutter | Cross-platform mobile UI |
| Frontend (Web) | Vue 3 + Vite | Modern web application |
| Backend | Hono + Node.js | API server |
| Database | MongoDB | Data persistence |
| Authentication | JWT + bcryptjs | Secure auth |
| State Management | Riverpod (Mobile), Pinia (Web) | State handling |
| Styling | Tailwind CSS (Web) | Utility-first CSS |
| Rich Text | Tiptap | Advanced text editing |

## 📚 Documentation

Refer to individual README.md files in each folder:
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
