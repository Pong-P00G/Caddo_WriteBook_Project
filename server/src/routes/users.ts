import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { writeFile, mkdir } from "node:fs/promises";
import { join, extname } from "node:path";
import { authMiddleware } from "../middleware/auth.js";
import { User } from "../models/User.js";
import type { IUser } from "../models/User.js";

type Variables = { user: IUser };
const users = new Hono<{ Variables: Variables }>();

// GET /users/me
users.get("/me", authMiddleware, async (c) => {
  const user = c.get("user") as IUser;
  return c.json({ success: true, data: user });
});

// PATCH /users/me
const updateSchema = z.object({
  name: z.string().min(1).max(80).optional(),
  bio: z.string().max(500).optional(),
  avatar: z.string().optional(),
});

users.patch(
  "/me",
  authMiddleware,
  zValidator("json", updateSchema),
  async (c) => {
    const user = c.get("user") as IUser;
    const payload = c.req.valid("json");
    const updated = await User.findByIdAndUpdate(user._id, payload, {
      new: true,
      runValidators: true,
    });
    return c.json({ success: true, data: updated });
  },
);

// POST /users/me/avatar  — multipart image upload
users.post("/me/avatar", authMiddleware, async (c) => {
  const user = c.get("user") as IUser;

  let form: FormData;
  try {
    form = await c.req.formData();
  } catch {
    return c.json(
      { success: false, error: "Expected multipart/form-data" },
      400,
    );
  }

  const file = form.get("avatar");
  if (!file || !(file instanceof File)) {
    return c.json(
      { success: false, error: "No image file provided (field name: avatar)" },
      400,
    );
  }

  const allowedTypes = ["image/jpeg", "image/png", "image/webp", "image/gif"];
  if (!allowedTypes.includes(file.type)) {
    return c.json(
      { success: false, error: "Only JPEG, PNG, WebP, or GIF allowed" },
      400,
    );
  }
  if (file.size > 5 * 1024 * 1024) {
    return c.json(
      { success: false, error: "Image must be smaller than 5 MB" },
      400,
    );
  }

  const uploadDir = join(process.cwd(), "uploads", "avatars");
  await mkdir(uploadDir, { recursive: true });

  const ext = extname(file.name) || ".jpg";
  const filename = `${user._id}-${Date.now()}${ext}`;
  const filepath = join(uploadDir, filename);

  const buffer = Buffer.from(await file.arrayBuffer());
  await writeFile(filepath, buffer);

  const avatarPath = `/uploads/avatars/${filename}`;
  const updated = await User.findByIdAndUpdate(
    user._id,
    { avatar: avatarPath },
    { new: true },
  );

  return c.json({ success: true, data: updated });
});

export default users;
