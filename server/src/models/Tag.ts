import mongoose, { type Document, Schema} from "mongoose";

export interface ITag extends Document {
    userId: mongoose.Types.ObjectId;
    name: string;
    color: string;
    icon: string;
    createdAt: Date;
    updatedAt: Date;
  }
  
  const TagSchema = new Schema<ITag>(
    {
      userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
      name: { type: String, required: true, trim: true, lowercase: true },
      color: { type: String, default: '#94a3b8' },
      icon: { type: String, default: '🏷️' },
    },
    { timestamps: true }
  );
  
  // Ensure tag names are unique per user
  TagSchema.index({ userId: 1, name: 1 }, { unique: true });
  
  export const Tag = mongoose.model<ITag>('Tag', TagSchema);