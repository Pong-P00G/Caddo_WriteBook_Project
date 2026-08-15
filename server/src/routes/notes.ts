import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { authMiddleware } from "../middleware/auth.js";
import { Note } from "../models/Note.js";
import type { IUser } from "../models/User.js";
import { CacheManager } from "../config/cache.js";

type Variables = { user: IUser };

const notes = new Hono<{ Variables: Variables }>();

// Public route — no auth
notes.get("/slug/:slug", async (c) => {
  const slug = c.req.param("slug");
  const cacheKey = `public:slug:${slug}`;
  const cached = CacheManager.get(cacheKey);
  if (cached) {
    c.header("X-Cache", "HIT");
    return c.json({ success: true, data: cached });
  }

  const note = await Note.findOne({
    slug,
    isDeleted: false,
  }).lean();

  if (!note) return c.json({ success: false, error: "Note not found" }, 404);
  
  CacheManager.set(cacheKey, note, 1000 * 60 * 10); // 10 mins for public slug
  c.header("X-Cache", "MISS");
  return c.json({ success: true, data: note });
});

// All routes below require auth
notes.use("*", authMiddleware);

const createSchema = z.object({
  title: z.string().min(1).max(200).default("Untitled"),
  content: z.string().optional().default(""),
  workspaceId: z.string().optional(),
  folderId: z.string().optional(),
  tagIds: z.array(z.string()).optional().default([]),
});

const updateSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  content: z.string().optional(),
  folderId: z.string().nullable().optional(),
  tagIds: z.array(z.string()).optional(),
  isFavorite: z.boolean().optional(),
});

// GET /notes — list user notes (cached & optimized)
notes.get("/", async (c) => {
  const user = c.get("user") as IUser;
  const userIdStr = String(user._id);
  const { folderId, workspaceId, search } = c.req.query();
  
  const cacheKey = `user:${userIdStr}:notes:list:${folderId || ""}:${workspaceId || ""}:${search || ""}`;
  const cached = CacheManager.get(cacheKey);
  if (cached) {
    c.header("X-Cache", "HIT");
    return c.json({ success: true, data: cached });
  }

  const filter: Record<string, unknown> = {
    userId: user._id,
    isDeleted: false,
  };
  if (folderId) filter.folderId = folderId;
  if (workspaceId) filter.workspaceId = workspaceId;
  if (search) {
    // Prefer text index if available, fallback to regex search
    filter.$or = [
      { title: { $regex: search, $options: "i" } },
      { content: { $regex: search, $options: "i" } },
    ];
  }

  const noteList = await Note.find(filter)
    .populate("folderId", "name")
    .populate("workspaceId", "name icon")
    .sort({ updatedAt: -1 })
    .lean();

  CacheManager.set(cacheKey, noteList);
  c.header("X-Cache", "MISS");
  return c.json({ success: true, data: noteList });
});

// GET /notes/favorites (cached & optimized)
notes.get("/favorites", async (c) => {
  const user = c.get("user") as IUser;
  const userIdStr = String(user._id);
  const cacheKey = `user:${userIdStr}:notes:favorites`;
  
  const cached = CacheManager.get(cacheKey);
  if (cached) {
    c.header("X-Cache", "HIT");
    return c.json({ success: true, data: cached });
  }

  const noteList = await Note.find({
    userId: user._id,
    isFavorite: true,
    isDeleted: false,
  })
    .sort({ updatedAt: -1 })
    .lean();

  CacheManager.set(cacheKey, noteList);
  c.header("X-Cache", "MISS");
  return c.json({ success: true, data: noteList });
});

// GET /notes/trash (cached & optimized)
notes.get("/trash", async (c) => {
  const user = c.get("user") as IUser;
  const userIdStr = String(user._id);
  const cacheKey = `user:${userIdStr}:notes:trash`;

  const cached = CacheManager.get(cacheKey);
  if (cached) {
    c.header("X-Cache", "HIT");
    return c.json({ success: true, data: cached });
  }

  const noteList = await Note.find({ userId: user._id, isDeleted: true })
    .sort({ deletedAt: -1 })
    .lean();

  CacheManager.set(cacheKey, noteList);
  c.header("X-Cache", "MISS");
  return c.json({ success: true, data: noteList });
});

// POST /notes — create
notes.post("/", zValidator("json", createSchema), async (c) => {
  const user = c.get("user") as IUser;
  const payload = c.req.valid("json");
  const note = await Note.create({ ...payload, userId: user._id });

  // Invalidate user cache on creation
  CacheManager.invalidateUser(String(user._id));

  return c.json({ success: true, data: note }, 201);
});

// GET /notes/:id (cached & optimized)
notes.get("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const id = c.req.param("id");
  const userIdStr = String(user._id);
  const cacheKey = `user:${userIdStr}:note:${id}`;

  const cached = CacheManager.get(cacheKey);
  if (cached) {
    c.header("X-Cache", "HIT");
    return c.json({ success: true, data: cached });
  }

  const note = await Note.findOne({ _id: id, userId: user._id })
    .populate("folderId", "name")
    .populate("workspaceId", "name icon")
    .lean();

  if (!note) return c.json({ success: false, error: "Note not found" }, 404);

  CacheManager.set(cacheKey, note);
  c.header("X-Cache", "MISS");
  return c.json({ success: true, data: note });
});

// PATCH /notes/:id
notes.patch("/:id", zValidator("json", updateSchema), async (c) => {
  const user = c.get("user") as IUser;
  const id = c.req.param("id");
  const payload = c.req.valid("json");

  const note = await Note.findOneAndUpdate(
    { _id: id, userId: user._id },
    { ...payload, $inc: { version: 1 } },
    { new: true },
  ).lean();

  if (!note) return c.json({ success: false, error: "Note not found" }, 404);

  // Invalidate cache
  CacheManager.invalidateUser(String(user._id));

  return c.json({ success: true, data: note });
});

// DELETE /notes/:id  — soft delete
notes.delete("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const id = c.req.param("id");

  const note = await Note.findOneAndUpdate(
    { _id: id, userId: user._id },
    { isDeleted: true, deletedAt: new Date() },
    { new: true },
  ).lean();

  if (!note) return c.json({ success: false, error: "Note not found" }, 404);

  // Invalidate cache
  CacheManager.invalidateUser(String(user._id));

  return c.json({ success: true, data: note });
});

// POST /notes/:id/restore
notes.post("/:id/restore", async (c) => {
  const user = c.get("user") as IUser;
  const id = c.req.param("id");

  const note = await Note.findOneAndUpdate(
    { _id: id, userId: user._id },
    { isDeleted: false, deletedAt: null },
    { new: true },
  ).lean();

  if (!note) return c.json({ success: false, error: "Note not found" }, 404);

  // Invalidate cache
  CacheManager.invalidateUser(String(user._id));

  return c.json({ success: true, data: note });
});

// DELETE /notes/:id/permanent — hard delete
notes.delete("/:id/permanent", async (c) => {
  const user = c.get("user") as IUser;
  const id = c.req.param("id");

  const note = await Note.findOneAndDelete({
    _id: id,
    userId: user._id,
    isDeleted: true,
  }).lean();

  if (!note)
    return c.json(
      { success: false, error: "Note not found or not in trash" },
      404,
    );

  // Invalidate cache
  CacheManager.invalidateUser(String(user._id));

  return c.json({ success: true, data: null });
});

export default notes;
