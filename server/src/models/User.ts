import mongoose, { Schema, type Document } from 'mongoose'
import bcrypt from 'bcryptjs'

export interface IUser extends Document {
  name:      string
  email:     string
  password:  string
  avatar?:   string
  bio?:      string
  createdAt: Date
  updatedAt: Date
  comparePassword(candidate: string): Promise<boolean>
}

const userSchema = new Schema<IUser>(
  {
    name:     { type: String, required: true, trim: true, maxlength: 80 },
    email:    { type: String, required: true, unique: true, lowercase: true, trim: true },
    password: { type: String, required: true, minlength: 8, select: false },
    avatar:   { type: String },
    bio:      { type: String, maxlength: 500 },
  },
  { timestamps: true }
)

// Hash password before save
userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next()
  this.password = await bcrypt.hash(this.password, 12)
  next()
})

userSchema.methods.comparePassword = async function (candidate: string): Promise<boolean> {
  return bcrypt.compare(candidate, this.password)
}

// Strip password from JSON output
userSchema.set('toJSON', {
  transform: (_doc, ret) => {
    const { password, ...rest } = ret
    return rest
  },
})

export const User = mongoose.model<IUser>('User', userSchema)
