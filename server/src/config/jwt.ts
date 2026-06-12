import { SignJWT, jwtVerify } from 'jose'

const ACCESS_SECRET  = new TextEncoder().encode(process.env.JWT_ACCESS_SECRET  ?? 'change-me-access')
const REFRESH_SECRET = new TextEncoder().encode(process.env.JWT_REFRESH_SECRET ?? 'change-me-refresh')

export async function signAccessToken(userId: string): Promise<string> {
  return new SignJWT({ sub: userId })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('15m')
    .sign(ACCESS_SECRET)
}

export async function signRefreshToken(userId: string): Promise<string> {
  return new SignJWT({ sub: userId })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(REFRESH_SECRET)
}

export async function verifyAccessToken(token: string): Promise<string> {
  const { payload } = await jwtVerify(token, ACCESS_SECRET)
  return payload.sub as string
}

export async function verifyRefreshToken(token: string): Promise<string> {
  const { payload } = await jwtVerify(token, REFRESH_SECRET)
  return payload.sub as string
}
