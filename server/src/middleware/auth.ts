import type { Context, Next } from 'hono'
import { verifyAccessToken } from '../config/jwt.js'
import { User } from '../models/User.js'

export async function authMiddleware(c: Context, next: Next) {
  const header = c.req.header('Authorization')
  if (!header?.startsWith('Bearer ')) {
    return c.json({ success: false, message: 'Unauthorised' }, 401)
  }

  const token = header.slice(7)
  try {
    const userId = await verifyAccessToken(token)
    const user   = await User.findById(userId).select('-password')
    if (!user) return c.json({ success: false, message: 'User not found' }, 401)

    c.set('user', user)
    await next()
  } catch {
    return c.json({ success: false, message: 'Invalid or expired token' }, 401)
  }
}
