import mongoose, { type Document, Schema} from "mongoose";

export interface IUserSettings extends Document {
    userId: mongoose.Types.ObjectId;
    appearance: {
      theme: 'light' | 'dark' | 'system';
      fontSize: number;
      fontFamily: string;
      lineNumbers: boolean;
    };
    editor: {
      defaultView: 'editor' | 'preview' | 'split';
      spellcheck: boolean;
      autoSaveInterval: number; // in milliseconds
    };
    layout: {
      sidebarCollapsed: boolean;
      defaultWorkspaceId: mongoose.Types.ObjectId | null;
    };
    revisions: {
        retentionPeriod: '1m' | '3m' | '6m' | '1y' | 'never';
    };
    updatedAt: Date;
  }
  
  const UserSettingsSchema = new Schema<IUserSettings>(
    {
      userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, unique: true, index: true },
      appearance: {
        theme: { type: String, enum: ['light', 'dark', 'system'], default: 'system' },
        fontSize: { type: Number, default: 16 },
        fontFamily: { type: String, default: 'Inter, sans-serif' },
        lineNumbers: { type: Boolean, default: false },
      },
      editor: {
        defaultView: { type: String, enum: ['editor', 'preview', 'split'], default: 'editor' },
        spellcheck: { type: Boolean, default: true },
        autoSaveInterval: { type: Number, default: 2000 }, // 2 seconds
      },
      layout: {
        sidebarCollapsed: { type: Boolean, default: false },
        defaultWorkspaceId: { type: Schema.Types.ObjectId, ref: 'Workspace', default: null },
      },
      revisions: {
          retentionPeriod: { 
            type: String, 
            enum: ['1m', '3m', '6m', '1y', 'never'], 
            default: '3m' // default 3 months
          },
        },
    },
    { timestamps: { createdAt: false, updatedAt: true } }
  );
  
  export const UserSettings = mongoose.model<IUserSettings>('UserSettings', UserSettingsSchema);