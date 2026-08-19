import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import bcrypt from "bcryptjs";
import { authMiddleware } from "../middleware/auth.js";
import { Note } from "../models/Note.js";
import { NoteRevision } from "../models/NoteRevision.js";
import type { IUser } from "../models/User.js";
import { CacheManager } from "../config/cache.js";

type Variables = { user: IUser };

const notes = new Hono<{ Variables: Variables }>();

// ── Public routes — no auth ─────────────────────────────────────────────
// GET /notes/slug/:slug — get public note
notes.get("/slug/:slug", async (c) => {
  const slug = c.req.param("slug");
  const providedPassword = c.req.header("x-share-password") || c.req.query("password");

  const note = await Note.findOne({
    slug,
    isDeleted: false,
    isPublic: true,
  })
    .populate("userId", "name avatar bio")
    .populate("folderId", "name")
    .lean();

  if (!note) return c.json({ success: false, error: "Public note not found or access is disabled" }, 404);

  // If password protected
  if (note.sharePassword) {
    if (!providedPassword) {
      return c.json({
        success: true,
        isProtected: true,
        data: {
          _id: note._id,
          title: note.title,
          slug: note.slug,
          isProtected: true,
          author: note.userId,
          updatedAt: note.updatedAt,
        },
      });
    }

    const isMatch = await bcrypt.compare(providedPassword, note.sharePassword);
    if (!isMatch) {
      return c.json({ success: false, isProtected: true, error: "Invalid password" }, 401);
    }
  }

  // Increment view count asynchronously
  Note.findByIdAndUpdate(note._id, { $inc: { viewCount: 1 } }).exec();

  const { sharePassword, ...safeNote } = note;
  return c.json({
    success: true,
    isProtected: false,
    data: {
      ...safeNote,
      hasPassword: !!sharePassword,
      author: note.userId,
    },
  });
});

// POST /notes/slug/:slug/verify — verify password for protected note
notes.post("/slug/:slug/verify", zValidator("json", z.object({ password: z.string() })), async (c) => {
  const slug = c.req.param("slug");
  const { password } = c.req.valid("json");

  const note = await Note.findOne({
    slug,
    isDeleted: false,
    isPublic: true,
  })
    .populate("userId", "name avatar bio")
    .populate("folderId", "name")
    .lean();

  if (!note) return c.json({ success: false, error: "Note not found" }, 404);

  if (!note.sharePassword) {
    const { sharePassword: _, ...safeNote } = note;
    return c.json({ success: true, data: safeNote });
  }

  const isMatch = await bcrypt.compare(password, note.sharePassword);
  if (!isMatch) {
    return c.json({ success: false, error: "Incorrect password" }, 401);
  }

  Note.findByIdAndUpdate(note._id, { $inc: { viewCount: 1 } }).exec();

  const { sharePassword: _, ...safeNote } = note;
  return c.json({
    success: true,
    data: {
      ...safeNote,
      hasPassword: true,
      author: note.userId,
    },
  });
});

// All routes below require auth
notes.use("*", authMiddleware);

const createSchema = z.object({
  title: z.string().min(1).max(200).default("Untitled"),
  content: z.string().optional().default(""),
  workspaceId: z.string().optional(),
  folderId: z.string().optional(),
  tagIds: z.array(z.string()).optional().default([]),
  isPinned: z.boolean().optional().default(false),
  color: z.string().nullable().optional(),
});

const updateSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  content: z.string().optional(),
  folderId: z.string().nullable().optional(),
  tagIds: z.array(z.string()).optional(),
  isFavorite: z.boolean().optional(),
  isPinned: z.boolean().optional(),
  color: z.string().nullable().optional(),
  changeSummary: z.string().optional(),
});

// GET /notes — list user notes (cached & optimized, pinned first)
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
    filter.$or = [
      { title: { $regex: search, $options: "i" } },
      { content: { $regex: search, $options: "i" } },
    ];
  }

  const noteList = await Note.find(filter)
    .populate("folderId", "name")
    .populate("workspaceId", "name icon")
    .sort({ isPinned: -1, updatedAt: -1 })
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
    .sort({ isPinned: -1, updatedAt: -1 })
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

  // Record initial snapshot
  await NoteRevision.create({
    noteId: note._id,
    userId: user._id,
    title: note.title,
    content: note.content,
    changeSummary: "Initial version",
  });

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
  const { changeSummary, ...payload } = c.req.valid("json");

  // Fetch current note before updating to verify changes and record revision
  const existingNote = await Note.findOne({ _id: id, userId: user._id });
  if (!existingNote) return c.json({ success: false, error: "Note not found" }, 404);

  const isContentChanged = payload.content !== undefined && payload.content !== existingNote.content;
  const isTitleChanged = payload.title !== undefined && payload.title !== existingNote.title;

  const note = await Note.findOneAndUpdate(
    { _id: id, userId: user._id },
    { ...payload, $inc: { version: 1 } },
    { new: true },
  ).lean();

  if (!note) return c.json({ success: false, error: "Note not found" }, 404);

  // If content or title changed significantly, record a revision snapshot (throttled by 2 mins unless summary provided)
  if (isContentChanged || isTitleChanged || changeSummary) {
    const lastRev = await NoteRevision.findOne({ noteId: id, userId: user._id }).sort({ createdAt: -1 });
    const timeSinceLastRev = lastRev ? Date.now() - new Date(lastRev.createdAt).getTime() : Infinity;
    
    // Save new revision if explicit summary provided OR more than 2 minutes since last snapshot
    if (changeSummary || timeSinceLastRev > 2 * 60 * 1000) {
      await NoteRevision.create({
        noteId: note._id,
        userId: user._id,
        title: note.title,
        content: note.content,
        changeSummary: changeSummary || "Auto-saved edit",
      });
    }
  }

  // Invalidate cache
  CacheManager.invalidateUser(String(user._id));

  return c.json({ success: true, data: note });
});

// ── Revision Endpoints ──────────────────────────────────────────────────
// GET /notes/:id/revisions — list all revision history for note
notes.get("/:id/revisions", async (c) => {
  const user = c.get("user") as IUser;
  const noteId = c.req.param("id");

  const revisions = await NoteRevision.find({ noteId, userId: user._id })
    .select("title changeSummary createdAt")
    .sort({ createdAt: -1 })
    .lean();

  return c.json({ success: true, data: revisions });
});

// GET /notes/:id/revisions/:revisionId — get specific revision details
notes.get("/:id/revisions/:revisionId", async (c) => {
  const user = c.get("user") as IUser;
  const { id: noteId, revisionId } = c.req.param();

  const revision = await NoteRevision.findOne({
    _id: revisionId,
    noteId,
    userId: user._id,
  }).lean();

  if (!revision) {
    return c.json({ success: false, error: "Revision not found" }, 404);
  }

  return c.json({ success: true, data: revision });
});

// POST /notes/:id/revisions — create manual revision checkpoint
notes.post("/:id/revisions", zValidator("json", z.object({ changeSummary: z.string().min(1).default("Manual checkpoint") })), async (c) => {
  const user = c.get("user") as IUser;
  const noteId = c.req.param("id");
  const { changeSummary } = c.req.valid("json");

  const note = await Note.findOne({ _id: noteId, userId: user._id });
  if (!note) return c.json({ success: false, error: "Note not found" }, 404);

  const revision = await NoteRevision.create({
    noteId: note._id,
    userId: user._id,
    title: note.title,
    content: note.content,
    changeSummary,
  });

  return c.json({ success: true, data: revision }, 201);
});

// POST /notes/:id/revisions/:revisionId/restore — restore revision
notes.post("/:id/revisions/:revisionId/restore", async (c) => {
  const user = c.get("user") as IUser;
  const { id: noteId, revisionId } = c.req.param();

  const revision = await NoteRevision.findOne({
    _id: revisionId,
    noteId,
    userId: user._id,
  });

  if (!revision) {
    return c.json({ success: false, error: "Revision not found" }, 404);
  }

  const currentNote = await Note.findOne({ _id: noteId, userId: user._id });
  if (!currentNote) {
    return c.json({ success: false, error: "Note not found" }, 404);
  }

  // Snapshot current state before restoring
  await NoteRevision.create({
    noteId: currentNote._id,
    userId: user._id,
    title: currentNote.title,
    content: currentNote.content,
    changeSummary: `Before restoring revision from ${new Date(revision.createdAt).toLocaleString()}`,
  });

  // Restore note
  currentNote.title = revision.title;
  currentNote.content = revision.content;
  currentNote.version += 1;
  await currentNote.save();

  // Invalidate cache
  CacheManager.invalidateUser(String(user._id));

  return c.json({ success: true, data: currentNote });
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

// POST /notes/:id/share — configure sharing options
const shareSchema = z.object({
  isPublic: z.boolean(),
  slug: z.string().min(3).max(64).regex(/^[a-z0-9-_]+$/i, "Slug must contain only alphanumeric characters, dashes, or underscores").optional(),
  password: z.string().nullable().optional(),
});

notes.post("/:id/share", zValidator("json", shareSchema), async (c) => {
  const user = c.get("user") as IUser;
  const id = c.req.param("id");
  const { isPublic, slug, password } = c.req.valid("json");

  const note = await Note.findOne({ _id: id, userId: user._id });
  if (!note) return c.json({ success: false, error: "Note not found" }, 404);

  note.isPublic = isPublic;

  if (isPublic) {
    if (slug && slug !== note.slug) {
      const existing = await Note.findOne({ slug: slug.toLowerCase(), _id: { $ne: note._id } });
      if (existing) {
        return c.json({ success: false, error: "This custom link is already taken. Please try another." }, 400);
      }
      note.slug = slug.toLowerCase();
    } else if (!note.slug) {
      const randomSuffix = Math.random().toString(36).substring(2, 8);
      const safeTitle = (note.title || "note")
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, "-")
        .replace(/^-|-$/g, "")
        .slice(0, 30) || "note";
      note.slug = `${safeTitle}-${randomSuffix}`;
    }

    if (password !== undefined) {
      if (password && password.trim().length > 0) {
        note.sharePassword = await bcrypt.hash(password.trim(), 10);
      } else if (password === null || password === "") {
        note.sharePassword = null;
      }
    }
  }

  await note.save();

  // Invalidate cache
  CacheManager.invalidateUser(String(user._id));

  return c.json({
    success: true,
    data: {
      _id: note._id,
      isPublic: note.isPublic,
      slug: note.slug,
      hasPassword: !!note.sharePassword,
      viewCount: note.viewCount,
    },
  });
});

export default notes;
