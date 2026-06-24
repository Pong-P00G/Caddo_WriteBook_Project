import mongoose, { Schema, Document } from 'mongoose';

export interface IWorkspace extends Document {
  userId: mongoose.Types.ObjectId;
  name: string;
  icon: string; // emoji or icon identifier
  color: string; // hex code for UI accent
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const WorkspaceSchema = new Schema<IWorkspace>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true, default: 'My Workspace' },
    icon: { type: String, default: '📁' },
    color: { type: String, default: '#3b82f6' },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

export const Workspace = mongoose.model<IWorkspace>('Workspace', WorkspaceSchema);