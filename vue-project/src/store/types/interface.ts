// ─── User ──────────────────────────────────────────────
export interface User {
  _id: string;
  name: string;
  email: string;
  avatar?: string;
  bio?: string;
  createdAt: string;
}

// ─── Note ──────────────────────────────────────────────
export interface Note {
  _id: string;
  userId: string;
  workspaceId?: string | { _id: string; name: string; icon?: string } | null;
  folderId?: string | { _id: string; name: string } | null;
  title: string;
  content: string; // Tiptap JSON stringified
  slug?: string | null;
  tagIds: string[];
  tags?: Array<{ _id: string; name: string; color?: string } | string>;
  isFavorite: boolean;
  isDeleted: boolean;
  deletedAt?: string | null;
  version: number;
  createdAt: string;
  updatedAt: string;
}

// ─── Tag ──────────────────────────────────────────────
export interface Tag {
  _id: string;
  userId: string;
  name: string;
  color: string;
  icon?: string;
  createdAt: string;
  updatedAt: string;
}

// ─── Folder ───────────────────────────────────────────
export interface Folder {
  _id: string;
  userId: string;
  workspaceId: string;
  parentId?: string | null;
  name: string;
  icon?: string;
  order: number;
  isDeleted: boolean;
  createdAt: string;
  updatedAt: string;
}

// ─── Workspace ────────────────────────────────────────
export interface Workspace {
  _id: string;
  userId: string;
  name: string;
  icon?: string;
  color?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

// ─── API wrappers ──────────────────────────────────────
export interface ApiResponse<T> {
  success: boolean;
  data: T;
  message?: string;
  error?: string;
}

export interface PaginatedResponse<T> extends ApiResponse<T[]> {
  pagination: {
    page: number;
    limit: number;
    total: number;
    pages: number;
  };
}

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
  user: User;
}


