import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import dotenv from 'dotenv'
import cors from 'hono/cors'
import { dbConnect } from './Database/dbConnect.js'


dotenv.config()
const app = new Hono()
app.use('*',cors (
  origin : ['http://localhost:5173', 'http://localhost:3000'],
  allowHeaders: ['Content-Type', 'Authorization'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  exposedHeaders: ['Content-Type', 'Authorization'],
  credentials: true
  maxAge: 600,
))

dbConnect().then(() => {
  serve({
    fetch: app.fetch,
    port: process.env.PORT || 5002,
  }, (info) => {
    console.log(`Server running at ${info.port}`)
  })
}) .catch((error) => {
  console.error('Failed to connect to the database:', error),
  process.exit(1),
}