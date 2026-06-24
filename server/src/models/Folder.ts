import mongoose, { type Document, Schema} from "mongoose";

export interface IFolder extends Document {
    userId: mongoose.Types.ObjectId;
    workspaceId: mongoose.Types.ObjectId;
    parentId: mongoose.Types.ObjectId | null; // For nested folders
    name: string;
    icon: string;
    order: number; // For manual sorting in the UI
    isDeleted: boolean;
    createdAt: Date;
    updatedAt: Date;
  }
  
  const FolderSchema = new Schema<IFolder>(
    {
      userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
      workspaceId: { type: Schema.Types.ObjectId, ref: 'Workspace', required: true, index: true },
      parentId: { type: Schema.Types.ObjectId, ref: 'Folder', default: null, index: true },
      name: { type: String, required: true, default: 'Untitled Folder' },
      icon: { type: String, default: '📂' },
      order: { type: Number, default: 0 },
      isDeleted: { type: Boolean, default: false, index: true },
    },
    { timestamps: true }
  );
  
  FolderSchema.index({ userId: 1, workspaceId: 1, parentId: 1, order: 1 });
  
  export const Folder = mongoose.model<IFolder>('Folder', FolderSchema);