import mongoose , { type Document, Schema} from "mongoose";

export interface INoteRevision extends Document {
    noteId: mongoose.Types.ObjectId;
    userId: mongoose.Types.ObjectId;
    title: string; // Snapshot of title at this time
    content: string; // Snapshot of markdown at this time
    changeSummary: string; // Optional: e.g., "Auto-saved", "Manual revision"
    expireAt: Date| null ; // Dynamic expiration date
    createdAt: Date;
  }
  
  const NoteRevisionSchema = new Schema<INoteRevision>(
    {
      noteId: { type: Schema.Types.ObjectId, ref: 'Note', required: true, index: true },
      userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
      title: { type: String, required: true },
      content: { type: String, required: true },
      changeSummary: { type: String, default: 'Auto-saved' },
      expireAt: { type: Date, default: null }, // Null means "Never delete"
    },
    { timestamps: { createdAt: true, updatedAt: false } }
  );
  
  // TTL Index: expireAfterSeconds: 0 means "delete exactly at the date specified in expireAt"
  // Documents with expireAt: null or missing will be safely ignored by MongoDB.
  NoteRevisionSchema.index({ expireAt: 1 }, { expireAfterSeconds: 0 });
  
  export const NoteRevision = mongoose.model<INoteRevision>('NoteRevision', NoteRevisionSchema);