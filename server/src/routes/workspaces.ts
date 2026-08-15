import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { authMiddleware } from "../middleware/auth.js";
import { Workspace } from "../models/Workspace.js";
import { Folder } from "../models/Folder.js";
import { Note } from "../models/Note.js";
import type { IUser } from "../models/User.js";
import { CacheManager } from "../config/cache.js";

type Variables = { user: IUser };

const workspaces = new Hono<{ Variables: Variables }>();
workspaces.use("*", authMiddleware);

const schema = z.object({
  name: z.string().min(1).max(100),
  icon: z.string().optional(),
  color: z.string().optional(),
});

workspaces.get("/", async (c) => {
  const user = c.get("user") as IUser;
  const userIdStr = String(user._id);
  const cacheKey = `user:${userIdStr}:workspaces:list`;

  const cached = CacheManager.get(cacheKey);
  if (cached) {
    c.header("X-Cache", "HIT");
    return c.json({ success: true, data: cached });
  }

  const list = await Workspace.find({ userId: user._id })
    .sort({ createdAt: 1 })
    .lean();

  CacheManager.set(cacheKey, list);
  c.header("X-Cache", "MISS");
  return c.json({ success: true, data: list });
});

workspaces.post("/", zValidator("json", schema), async (c) => {
  const user = c.get("user") as IUser;
  const ws = await Workspace.create({
    ...c.req.valid("json"),
    userId: user._id,
  });

  CacheManager.invalidateUser(String(user._id));
  return c.json({ success: true, data: ws }, 201);
});

workspaces.patch("/:id", zValidator("json", schema.partial()), async (c) => {
  const user = c.get("user") as IUser;
  const ws = await Workspace.findOneAndUpdate(
    { _id: c.req.param("id"), userId: user._id },
    c.req.valid("json"),
    { new: true },
  ).lean();

  if (!ws) return c.json({ success: false, error: "Workspace not found" }, 404);

  CacheManager.invalidateUser(String(user._id));
  return c.json({ success: true, data: ws });
});

workspaces.delete("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const workspaceId = c.req.param("id");
  const ws = await Workspace.findOneAndDelete({
    _id: workspaceId,
    userId: user._id,
  }).lean();

  if (!ws) return c.json({ success: false, error: "Workspace not found" }, 404);

  // Soft delete all child folders and notes in this workspace
  await Folder.updateMany(
    { workspaceId, userId: user._id },
    { isDeleted: true },
  );
  await Note.updateMany(
    { workspaceId, userId: user._id },
    { isDeleted: true },
  );

  CacheManager.invalidateUser(String(user._id));
  return c.json({ success: true, data: null });
});

// GET /workspaces/:id — get single workspace
workspaces.get("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const id = c.req.param("id");
  const cacheKey = `user:${user._id}:workspace:${id}`;

  const cached = CacheManager.get(cacheKey);
  if (cached) {
    c.header("X-Cache", "HIT");
    return c.json({ success: true, data: cached });
  }

  const ws = await Workspace.findOne({
    _id: id,
    userId: user._id,
  }).lean();

  if (!ws) return c.json({ success: false, error: "Workspace not found" }, 404);

  CacheManager.set(cacheKey, ws);
  c.header("X-Cache", "MISS");
  return c.json({ success: true, data: ws });
});

export default workspaces;
