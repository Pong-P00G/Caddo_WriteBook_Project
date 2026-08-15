import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { authMiddleware } from "../middleware/auth.js";
import { Folder } from "../models/Folder.js";
import { Note } from "../models/Note.js";
import type { IUser } from "../models/User.js";
import { CacheManager } from "../config/cache.js";

type Variables = { user: IUser };

const folders = new Hono<{ Variables: Variables }>();
folders.use("*", authMiddleware);

const schema = z.object({
  name: z.string().min(1).max(100),
  workspaceId: z.string(),
  parentId: z.string().nullable().optional(),
  icon: z.string().optional(),
  order: z.number().optional(),
});

folders.get("/", async (c) => {
  const user = c.get("user") as IUser;
  const { workspaceId } = c.req.query();
  const userIdStr = String(user._id);
  const cacheKey = `user:${userIdStr}:folders:list:${workspaceId || ""}`;

  const cached = CacheManager.get(cacheKey);
  if (cached) {
    c.header("X-Cache", "HIT");
    return c.json({ success: true, data: cached });
  }

  const filter: Record<string, unknown> = {
    userId: user._id,
    isDeleted: false,
  };
  if (workspaceId) filter.workspaceId = workspaceId;
  
  const list = await Folder.find(filter).sort({ order: 1 }).lean();

  CacheManager.set(cacheKey, list);
  c.header("X-Cache", "MISS");
  return c.json({ success: true, data: list });
});

folders.post("/", zValidator("json", schema), async (c) => {
  const user = c.get("user") as IUser;
  const folder = await Folder.create({
    ...c.req.valid("json"),
    userId: user._id,
  });

  CacheManager.invalidateUser(String(user._id));
  return c.json({ success: true, data: folder }, 201);
});

folders.patch(
  "/:id",
  zValidator("json", schema.partial().omit({ workspaceId: true })),
  async (c) => {
    const user = c.get("user") as IUser;
    const folder = await Folder.findOneAndUpdate(
      { _id: c.req.param("id"), userId: user._id },
      c.req.valid("json"),
      { new: true },
    ).lean();

    if (!folder)
      return c.json({ success: false, error: "Folder not found" }, 404);

    CacheManager.invalidateUser(String(user._id));
    return c.json({ success: true, data: folder });
  },
);

folders.delete("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const folderId = c.req.param("id");
  const folder = await Folder.findOneAndUpdate(
    { _id: folderId, userId: user._id },
    { isDeleted: true },
    { new: true },
  ).lean();

  if (!folder)
    return c.json({ success: false, error: "Folder not found" }, 404);

  // Soft delete all notes in this folder
  await Note.updateMany(
    { folderId, userId: user._id },
    { isDeleted: true },
  );

  CacheManager.invalidateUser(String(user._id));
  return c.json({ success: true, data: null });
});

// GET /folders/:id — get single folder
folders.get("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const id = c.req.param("id");
  const cacheKey = `user:${user._id}:folder:${id}`;

  const cached = CacheManager.get(cacheKey);
  if (cached) {
    c.header("X-Cache", "HIT");
    return c.json({ success: true, data: cached });
  }

  const folder = await Folder.findOne({
    _id: id,
    userId: user._id,
    isDeleted: false,
  }).lean();

  if (!folder) return c.json({ success: false, error: "Folder not found" }, 404);

  CacheManager.set(cacheKey, folder);
  c.header("X-Cache", "MISS");
  return c.json({ success: true, data: folder });
});

export default folders;
