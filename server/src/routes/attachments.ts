import { Hono } from "hono";
import { writeFile, mkdir, unlink } from "node:fs/promises";
import { join, extname } from "node:path";
import { existsSync } from "node:fs";
import { authMiddleware } from "../middleware/auth.js";
import { Attachment } from "../models/Attachment.js";
import type { IUser } from "../models/User.js";

type Variables = { user: IUser };
const attachments = new Hono<{ Variables: Variables }>();

attachments.use("*", authMiddleware);

// POST /attachments/upload — upload media/document
attachments.post("/upload", async (c) => {
  const user = c.get("user") as IUser;

  let form: FormData;
  try {
    form = await c.req.formData();
  } catch {
    return c.json({ success: false, error: "Expected multipart/form-data" }, 400);
  }

  const file = form.get("file");
  const noteId = form.get("noteId")?.toString() || null;

  if (!file || !(file instanceof File)) {
    return c.json({ success: false, error: "No file provided (field: file)" }, 400);
  }

  // Max 25 MB limit
  if (file.size > 25 * 1024 * 1024) {
    return c.json({ success: false, error: "File size exceeds 25 MB limit" }, 400);
  }

  const uploadDir = join(process.cwd(), "uploads", "attachments");
  await mkdir(uploadDir, { recursive: true });

  const originalName = file.name || "attachment";
  const ext = extname(originalName) || "";
  const randomSuffix = Math.random().toString(36).substring(2, 8);
  const safeFilename = `${Date.now()}-${randomSuffix}${ext}`;
  const filepath = join(uploadDir, safeFilename);

  const buffer = Buffer.from(await file.arrayBuffer());
  await writeFile(filepath, buffer);

  const url = `/uploads/attachments/${safeFilename}`;

  const doc = await Attachment.create({
    userId: user._id,
    noteId: noteId || null,
    filename: originalName,
    url,
    mimeType: file.type || "application/octet-stream",
    size: file.size,
  });

  return c.json({
    success: true,
    data: {
      _id: doc._id,
      noteId: doc.noteId,
      filename: doc.filename,
      url: doc.url,
      mimeType: doc.mimeType,
      size: doc.size,
      createdAt: doc.createdAt,
    },
  }, 201);
});

// GET /attachments/note/:noteId — list attachments for a note
attachments.get("/note/:noteId", async (c) => {
  const user = c.get("user") as IUser;
  const noteId = c.req.param("noteId");

  const list = await Attachment.find({
    noteId,
    userId: user._id,
  })
    .sort({ createdAt: -1 })
    .lean();

  return c.json({ success: true, data: list });
});

// DELETE /attachments/:id — delete attachment
attachments.delete("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const id = c.req.param("id");

  const item = await Attachment.findOneAndDelete({
    _id: id,
    userId: user._id,
  }).lean();

  if (!item) {
    return c.json({ success: false, error: "Attachment not found" }, 404);
  }

  // Attempt to delete physical file
  if (item.url) {
    const filename = item.url.replace("/uploads/attachments/", "");
    const filepath = join(process.cwd(), "uploads", "attachments", filename);
    if (existsSync(filepath)) {
      await unlink(filepath).catch(() => {});
    }
  }

  return c.json({ success: true, data: null });
});

export default attachments;
