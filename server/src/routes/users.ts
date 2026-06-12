import { Hono } from 'hono'
import { z } from 'zod'
import { zValidator } from '@hono/zod-validator'
import { authMiddleware } from '../middleware/auth.js'
import { User } from '../models/User.js'
import type { IUser } from '../models/User.js'

const users = new Hono()

// GET /users/me
users.get('/me', authMiddleware, async (c) => {
  const user = c.get('user') as IUser
  return c.json({ success: true, data: user })
})

// PATCH /users/me
const updateSchema = z.object({
  name:   z.string().min(1).max(80).optional(),
  bio:    z.string().max(500).optional(),
  avatar: z.string().url().optional(),
})

users.patch('/me', authMiddleware, zValidator('json', updateSchema), async (c) => {
  const user    = c.get('user') as IUser
  const payload = c.req.valid('json')
  const updated = await User.findByIdAndUpdate(user._id, payload, { new: true, runValidators: true })
  return c.json({ success: true, data: updated })
})

export default users
