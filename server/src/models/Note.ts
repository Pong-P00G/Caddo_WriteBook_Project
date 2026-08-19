import mongoose, { Schema, type Document } from "mongoose";

export interface INote extends Document {
  userId: mongoose.Types.ObjectId;
  workspaceId?: mongoose.Types.ObjectId | null;
  folderId: mongoose.Types.ObjectId | null; // Null if at workspace root
  title: string;
  content: string; // Raw Markdown
  tagIds: mongoose.Types.ObjectId[]; // Array of Tag ObjectIds
  isFavorite: boolean;
  isPinned: boolean;
  color?: string | null;
  isPublic: boolean;
  sharePassword?: string | null;
  viewCount: number;
  isDeleted: boolean;
  deletedAt: Date | null;
  version: number;
  slug?: string | null;
  createdAt: Date;
  updatedAt: Date;
}

const NoteSchema = new Schema<INote>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    workspaceId: {
      type: Schema.Types.ObjectId,
      ref: "Workspace",
      required: false,
      default: null,
      index: true,
    },
    folderId: {
      type: Schema.Types.ObjectId,
      ref: "Folder",
      default: null,
      index: true,
    },
    title: { type: String, required: true, default: "Untitled" },
    content: { type: String, default: "" },
    tagIds: [{ type: Schema.Types.ObjectId, ref: "Tag" }],
    isFavorite: { type: Boolean, default: false, index: true },
    isPinned: { type: Boolean, default: false, index: true },
    color: { type: String, default: null },
    isPublic: { type: Boolean, default: false, index: true },
    sharePassword: { type: String, default: null },
    viewCount: { type: Number, default: 0 },
    isDeleted: { type: Boolean, default: false, index: true },
    deletedAt: { type: Date, default: null },
    version: { type: Number, default: 0 },
    slug: { type: String, default: null, index: true, sparse: true, unique: true },
  },
  { timestamps: true },
);

NoteSchema.index({
  userId: 1,
  workspaceId: 1,
  folderId: 1,
  isDeleted: 1,
  isPinned: -1,
  updatedAt: -1,
});
NoteSchema.index({ userId: 1, isPinned: -1, updatedAt: -1 });
NoteSchema.index({ userId: 1, isFavorite: 1, isDeleted: 1, updatedAt: -1 });
NoteSchema.index({ userId: 1, isDeleted: 1, deletedAt: -1 });
NoteSchema.index({ userId: 1, tagIds: 1 });
NoteSchema.index({ title: "text", content: "text" });

export const Note = mongoose.model<INote>("Note", NoteSchema);
