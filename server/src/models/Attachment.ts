import mongoose, {type Document, Schema } from "mongoose";

export interface IAttachment extends Document {
    userId: mongoose.Types.ObjectId;
    noteId: mongoose.Types.ObjectId | null; // null if uploaded but not yet attached to a note
    filename: string;
    url: string; // e.g., S3 URL or local path
    mimeType: string;
    size: number; // in bytes
    createdAt: Date;
  }
  
  const AttachmentSchema = new Schema<IAttachment>(
    {
      userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
      noteId: { type: Schema.Types.ObjectId, ref: 'Note', default: null, index: true },
      filename: { type: String, required: true },
      url: { type: String, required: true },
      mimeType: { type: String, required: true },
      size: { type: Number, required: true },
    },
    { timestamps: true }
  );
  
  export const Attachment = mongoose.model<IAttachment>('Attachment', AttachmentSchema);