import mongoose, { Schema, type Document } from 'mongoose'

export type BookStatus     = 'draft' | 'published' | 'archived'
export type BookVisibility = 'private' | 'unlisted' | 'public'

export interface IBook extends Document {
  title:       string
  slug:        string
  description: string
  cover?:      string
  author:      mongoose.Types.ObjectId
  status:      BookStatus
  visibility:  BookVisibility
  tags:        string[]
  wordCount:   number
  createdAt:   Date
  updatedAt:   Date
}

function slugify(title: string): string {
  return title
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '')
    .slice(0, 80)
}

const bookSchema = new Schema<IBook>(
  {
    title:       { type: String, required: true, trim: true, maxlength: 200 },
    slug:        { type: String, unique: true, index: true },
    description: { type: String, default: '', maxlength: 1000 },
    cover:       { type: String },
    author:      { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    status:      { type: String, enum: ['draft', 'published', 'archived'], default: 'draft' },
    visibility:  { type: String, enum: ['private', 'unlisted', 'public'], default: 'private' },
    tags:        [{ type: String, trim: true }],
    wordCount:   { type: Number, default: 0 },
  },
  { timestamps: true }
)

// Auto-generate unique slug from title
bookSchema.pre('save', async function (next) {
  if (!this.isModified('title') && this.slug) return next()
  const base = slugify(this.title)
  let slug   = base
  let n      = 1
  while (await (this.constructor as typeof mongoose.Model).findOne({ slug, _id: { $ne: this._id } })) {
    slug = `${base}-${n++}`
  }
  this.slug = slug
  next()
})

export const Book = mongoose.model<IBook>('Book', bookSchema)
