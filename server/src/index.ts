import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { cors } from 'hono/cors'
import { logger } from 'hono/logger'
import { prettyJSON } from 'hono/pretty-json'
import { connectDB } from './config/db.js'
import authRoutes   from './routes/auth.js'
import bookRoutes   from './routes/books.js'
import userRoutes   from './routes/users.js'

await connectDB()

const app = new Hono().basePath('/api/v1')

// ── Middleware ───────────────────────────────────────
app.use('*', logger())
app.use('*', prettyJSON())
app.use('*', cors({
  origin: ['http://localhost:5173', 'http://localhost:3001'],
  credentials: true,
  allowMethods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}))

// ── Routes ───────────────────────────────────────────
app.route('/auth',  authRoutes)
app.route('/books', bookRoutes)
app.route('/users', userRoutes)

// ── Health ───────────────────────────────────────────
app.get('/health', (c) => c.json({ status: 'ok', ts: Date.now() }))

// ── 404 ─────────────────────────────────────────────
app.notFound((c) => c.json({ success: false, message: 'Route not found' }, 404))

// ── Error handler ────────────────────────────────────
app.onError((err, c) => {
  console.error(err)
  return c.json({ success: false, message: err.message || 'Internal server error' }, 500)
})

const port = Number(process.env.PORT ?? 3000)
console.log(`🚀 Server running on http://localhost:${port}`)

serve({ fetch: app.fetch, port })
