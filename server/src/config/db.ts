import mongoose from 'mongoose'
import 'dotenv/config'

export async function connectDB() {
  const uri = process.env.MONGODB_URI
  if (!uri) throw new Error('MONGODB_URI environment variable is required')

  try {
    await mongoose.connect(uri)
    console.log('✅ MongoDB connected')
  } catch (err) {
    console.error('❌ MongoDB connection failed:', err)
    process.exit(1)
  }

  mongoose.connection.on('error', (err) => {
    console.error('MongoDB error:', err)
  })
}
