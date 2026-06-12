import mongoose, { Schema, type Document } from 'mongoose'

export interface IChapter extends Document {
  bookId:    mongoose.Types.ObjectId
  title:     string
  content:   string   // Tiptap JSON (stringified)
  order:     number
  wordCount: number
  createdAt: Date
  updatedAt: Date
}

const chapterSchema = new Schema<IChapter>(
  {
    bookId:    { type: Schema.Types.ObjectId, ref: 'Book', required: true, index: true },
    title:     { type: String, required: true, trim: true, maxlength: 200 },
    content:   { type: String, default: '' },
    order:     { type: Number, default: 0 },
    wordCount: { type: Number, default: 0 },
  },
  { timestamps: true }
)

chapterSchema.index({ bookId: 1, order: 1 })

export const Chapter = mongoose.model<IChapter>('Chapter', chapterSchema)
