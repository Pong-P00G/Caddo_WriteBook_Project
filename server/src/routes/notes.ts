import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { authMiddleware } from "../middleware/auth.js";
import { Note } from "../models/Note.js";
import type { IUser } from "../models/User.js";

type Variables = { user: IUser };

const notes = new Hono<{ Variables: Variables }>();

// Public route — no auth
notes.get("/slug/:slug", async (c) => {
  const note = await Note.findOne({
    slug: c.req.param("slug"),
    isDeleted: false,
  });
  if (!note) return c.json({ success: false, error: "Note not found" }, 404);
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

// GET /notes — list user notes
notes.get("/", async (c) => {
  const user = c.get("user") as IUser;
  const { folderId, workspaceId, search } = c.req.query();
  const filter: Record<string, unknown> = {
    userId: user._id,
    isDeleted: false,
  };
  if (folderId) filter.folderId = folderId;
  if (workspaceId) filter.workspaceId = workspaceId;
  if (search) {
    filter.$or = [
      { title: { $regex: search, $options: "i" } },
      { content: { $regex: search, $options: "i" } },
    ];
  }
  const noteList = await Note.find(filter).sort({ updatedAt: -1 });
  return c.json({ success: true, data: noteList });
});

// GET /notes/favorites
notes.get("/favorites", async (c) => {
  const user = c.get("user") as IUser;
  const noteList = await Note.find({
    userId: user._id,
    isFavorite: true,
    isDeleted: false,
  }).sort({ updatedAt: -1 });
  return c.json({ success: true, data: noteList });
});

// GET /notes/trash
notes.get("/trash", async (c) => {
  const user = c.get("user") as IUser;
  const noteList = await Note.find({ userId: user._id, isDeleted: true }).sort({
    deletedAt: -1,
  });
  return c.json({ success: true, data: noteList });
});

// POST /notes — create
notes.post("/", zValidator("json", createSchema), async (c) => {
  const user = c.get("user") as IUser;
  const payload = c.req.valid("json");
  const note = await Note.create({ ...payload, userId: user._id });
  return c.json({ success: true, data: note }, 201);
});

// GET /notes/:id
notes.get("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const note = await Note.findOne({ _id: c.req.param("id"), userId: user._id });
  if (!note) return c.json({ success: false, error: "Note not found" }, 404);
  return c.json({ success: true, data: note });
});

// PATCH /notes/:id
notes.patch("/:id", zValidator("json", updateSchema), async (c) => {
  const user = c.get("user") as IUser;
  const payload = c.req.valid("json");
  const note = await Note.findOneAndUpdate(
    { _id: c.req.param("id"), userId: user._id },
    { ...payload, $inc: { version: 1 } },
    { new: true },
  );
  if (!note) return c.json({ success: false, error: "Note not found" }, 404);
  return c.json({ success: true, data: note });
});

// DELETE /notes/:id  — soft delete
notes.delete("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const note = await Note.findOneAndUpdate(
    { _id: c.req.param("id"), userId: user._id },
    { isDeleted: true, deletedAt: new Date() },
    { new: true },
  );
  if (!note) return c.json({ success: false, error: "Note not found" }, 404);
  return c.json({ success: true, data: note });
});

// POST /notes/:id/restore
notes.post("/:id/restore", async (c) => {
  const user = c.get("user") as IUser;
  const note = await Note.findOneAndUpdate(
    { _id: c.req.param("id"), userId: user._id },
    { isDeleted: false, deletedAt: null },
    { new: true },
  );
  if (!note) return c.json({ success: false, error: "Note not found" }, 404);
  return c.json({ success: true, data: note });
});

// DELETE /notes/:id/permanent — hard delete
notes.delete("/:id/permanent", async (c) => {
  const user = c.get("user") as IUser;
  const note = await Note.findOneAndDelete({
    _id: c.req.param("id"),
    userId: user._id,
    isDeleted: true,
  });
  if (!note)
    return c.json(
      { success: false, error: "Note not found or not in trash" },
      404,
    );
  return c.json({ success: true, data: null });
});

export default notes;
