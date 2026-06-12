import { Hono } from 'hono'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'
import { authMiddleware } from '../middleware/auth.js'
import { Book } from '../models/Book.js'
import { Chapter } from '../models/Chapter.js'
import type { IUser } from '../models/User.js'

const books = new Hono()

// ── helpers ──────────────────────────────────────────────
function countWords(text: string): number {
  return text.replace(/<[^>]+>/g, ' ').trim().split(/\s+/).filter(Boolean).length
}

// ── Book CRUD ────────────────────────────────────────────

// GET /books/mine  (auth)
books.get('/mine', authMiddleware, async (c) => {
  const user = c.get('user') as IUser
  const myBooks = await Book.find({ author: user._id }).sort({ updatedAt: -1 }).lean()

  // Attach chapters summary
  const bookIds  = myBooks.map(b => b._id)
  const chapters = await Chapter.find({ bookId: { $in: bookIds } }).select('bookId order title wordCount').lean()
  const byBook   = chapters.reduce<Record<string, typeof chapters>>((acc, ch) => {
    const id = String(ch.bookId)
    acc[id]  = acc[id] ?? []
    acc[id].push(ch)
    return acc
  }, {})

  const result = myBooks.map(b => ({
    ...b,
    chapters: (byBook[String(b._id)] ?? []).sort((a, b) => a.order - b.order),
  }))

  return c.json({ success: true, data: result })
})

// GET /books/slug/:slug  (public — only published)
books.get('/slug/:slug', async (c) => {
  const book = await Book.findOne({
    slug: c.req.param('slug'),
    status: 'published',
    visibility: { $in: ['public', 'unlisted'] },
  }).populate('author', 'name avatar').lean()

  if (!book) return c.json({ success: false, message: 'Not found' }, 404)

  const chapters = await Chapter.find({ bookId: book._id }).sort({ order: 1 }).lean()
  return c.json({ success: true, data: { ...book, chapters } })
})

// GET /books/:id  (auth)
books.get('/:id', authMiddleware, async (c) => {
  const user = c.get('user') as IUser
  const book = await Book.findOne({ _id: c.req.param('id'), author: user._id }).lean()
  if (!book) return c.json({ success: false, message: 'Not found' }, 404)

  const chapters = await Chapter.find({ bookId: book._id }).sort({ order: 1 }).lean()
  return c.json({ success: true, data: { ...book, chapters } })
})

// POST /books  (auth)
const createBookSchema = z.object({
  title:       z.string().min(1).max(200),
  description: z.string().max(1000).optional(),
  visibility:  z.enum(['private', 'unlisted', 'public']).optional(),
  tags:        z.array(z.string()).optional(),
})

books.post('/', authMiddleware, zValidator('json', createBookSchema), async (c) => {
  const user    = c.get('user') as IUser
  const payload = c.req.valid('json')
  const book    = await Book.create({ ...payload, author: user._id })
  return c.json({ success: true, data: book }, 201)
})

// PATCH /books/:id  (auth)
const updateBookSchema = createBookSchema.partial().extend({
  status: z.enum(['draft', 'published', 'archived']).optional(),
})

books.patch('/:id', authMiddleware, zValidator('json', updateBookSchema), async (c) => {
  const user = c.get('user') as IUser
  const book = await Book.findOneAndUpdate(
    { _id: c.req.param('id'), author: user._id },
    c.req.valid('json'),
    { new: true, runValidators: true }
  )
  if (!book) return c.json({ success: false, message: 'Not found' }, 404)
  return c.json({ success: true, data: book })
})

// DELETE /books/:id  (auth)
books.delete('/:id', authMiddleware, async (c) => {
  const user = c.get('user') as IUser
  const book = await Book.findOneAndDelete({ _id: c.req.param('id'), author: user._id })
  if (!book) return c.json({ success: false, message: 'Not found' }, 404)
  await Chapter.deleteMany({ bookId: book._id })
  return c.json({ success: true })
})

// ── Chapter routes ────────────────────────────────────────

// GET /books/:bookId/chapters/:chapterId
books.get('/:bookId/chapters/:chapterId', authMiddleware, async (c) => {
  const user = c.get('user') as IUser
  const book = await Book.findOne({ _id: c.req.param('bookId'), author: user._id })
  if (!book) return c.json({ success: false, message: 'Not found' }, 404)

  const chapter = await Chapter.findOne({ _id: c.req.param('chapterId'), bookId: book._id })
  if (!chapter) return c.json({ success: false, message: 'Chapter not found' }, 404)

  return c.json({ success: true, data: chapter })
})

// POST /books/:bookId/chapters
books.post('/:bookId/chapters', authMiddleware, async (c) => {
  const user = c.get('user') as IUser
  const body = await c.req.json<{ title: string }>()
  const book = await Book.findOne({ _id: c.req.param('bookId'), author: user._id })
  if (!book) return c.json({ success: false, message: 'Not found' }, 404)

  const count   = await Chapter.countDocuments({ bookId: book._id })
  const chapter = await Chapter.create({
    bookId: book._id,
    title:  body.title ?? 'Untitled Chapter',
    order:  count,
  })

  return c.json({ success: true, data: chapter }, 201)
})

// PATCH /books/:bookId/chapters/reorder
books.patch('/:bookId/chapters/reorder', authMiddleware, async (c) => {
  const user = c.get('user') as IUser
  const body = await c.req.json<{ orderedIds: string[] }>()
  const book = await Book.findOne({ _id: c.req.param('bookId'), author: user._id })
  if (!book) return c.json({ success: false, message: 'Not found' }, 404)

  await Promise.all(
    body.orderedIds.map((id, idx) =>
      Chapter.findByIdAndUpdate(id, { order: idx })
    )
  )
  return c.json({ success: true })
})

// PATCH /books/:bookId/chapters/:chapterId
books.patch('/:bookId/chapters/:chapterId', authMiddleware, async (c) => {
  const user = c.get('user') as IUser
  const body = await c.req.json<{ content?: string; title?: string }>()
  const book = await Book.findOne({ _id: c.req.param('bookId'), author: user._id })
  if (!book) return c.json({ success: false, message: 'Not found' }, 404)

  const update: Record<string, unknown> = {}
  if (body.title   !== undefined) update.title     = body.title
  if (body.content !== undefined) {
    update.content   = body.content
    update.wordCount = countWords(body.content)
  }

  const chapter = await Chapter.findOneAndUpdate(
    { _id: c.req.param('chapterId'), bookId: book._id },
    update,
    { new: true }
  )
  if (!chapter) return c.json({ success: false, message: 'Chapter not found' }, 404)

  // Recalculate book word count
  const agg = await Chapter.aggregate<{ total: number }>([
    { $match: { bookId: book._id } },
    { $group: { _id: null, total: { $sum: '$wordCount' } } },
  ])
  await Book.findByIdAndUpdate(book._id, { wordCount: agg[0]?.total ?? 0 })

  return c.json({ success: true, data: chapter })
})

// DELETE /books/:bookId/chapters/:chapterId
books.delete('/:bookId/chapters/:chapterId', authMiddleware, async (c) => {
  const user = c.get('user') as IUser
  const book = await Book.findOne({ _id: c.req.param('bookId'), author: user._id })
  if (!book) return c.json({ success: false, message: 'Not found' }, 404)

  await Chapter.findOneAndDelete({ _id: c.req.param('chapterId'), bookId: book._id })
  return c.json({ success: true })
})

export default books
