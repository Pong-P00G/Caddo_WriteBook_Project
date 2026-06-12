import { Hono } from 'hono'
import { getCookie, setCookie, deleteCookie } from 'hono/cookie'
import { zValidator } from '@hono/zod-validator'
import { z } from 'zod'
import { User } from '../models/User.js'
import { signAccessToken, signRefreshToken, verifyRefreshToken } from '../config/jwt.js'

const auth = new Hono()

const registerSchema = z.object({
  name:     z.string().min(1).max(80),
  email:    z.string().email(),
  password: z.string().min(8),
})

const loginSchema = z.object({
  email:    z.string().email(),
  password: z.string().min(1),
})

// POST /auth/register
auth.post('/register', zValidator('json', registerSchema), async (c) => {
  const { name, email, password } = c.req.valid('json')

  const existing = await User.findOne({ email })
  if (existing) return c.json({ success: false, message: 'Email already registered' }, 409)

  const user         = await User.create({ name, email, password })
  const accessToken  = await signAccessToken(user.id)
  const refreshToken = await signRefreshToken(user.id)

  setCookie(c, 'wb_refresh', refreshToken, {
    httpOnly: true, secure: process.env.NODE_ENV === 'production',
    sameSite: 'Strict', maxAge: 60 * 60 * 24 * 7, path: '/',
  })

  return c.json({ accessToken, user }, 201)
})

// POST /auth/login
auth.post('/login', zValidator('json', loginSchema), async (c) => {
  const { email, password } = c.req.valid('json')

  const user = await User.findOne({ email }).select('+password')
  if (!user || !(await user.comparePassword(password))) {
    return c.json({ success: false, message: 'Invalid credentials' }, 401)
  }

  const accessToken  = await signAccessToken(user.id)
  const refreshToken = await signRefreshToken(user.id)

  setCookie(c, 'wb_refresh', refreshToken, {
    httpOnly: true, secure: process.env.NODE_ENV === 'production',
    sameSite: 'Strict', maxAge: 60 * 60 * 24 * 7, path: '/',
  })

  return c.json({ accessToken, user })
})

// POST /auth/refresh
auth.post('/refresh', async (c) => {
  const token = getCookie(c, 'wb_refresh')
  if (!token) return c.json({ success: false, message: 'No refresh token' }, 401)

  try {
    const userId      = await verifyRefreshToken(token)
    const accessToken = await signAccessToken(userId)
    return c.json({ accessToken })
  } catch {
    return c.json({ success: false, message: 'Invalid refresh token' }, 401)
  }
})

// POST /auth/logout
auth.post('/logout', (c) => {
  deleteCookie(c, 'wb_refresh', { path: '/' })
  return c.json({ success: true })
})

export default auth
