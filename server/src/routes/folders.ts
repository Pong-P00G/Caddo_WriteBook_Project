import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { authMiddleware } from "../middleware/auth.js";
import { Folder } from "../models/Folder.js";
import type { IUser } from "../models/User.js";

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
  const filter: Record<string, unknown> = {
    userId: user._id,
    isDeleted: false,
  };
  if (workspaceId) filter.workspaceId = workspaceId;
  const list = await Folder.find(filter).sort({ order: 1 });
  return c.json({ success: true, data: list });
});

folders.post("/", zValidator("json", schema), async (c) => {
  const user = c.get("user") as IUser;
  const folder = await Folder.create({
    ...c.req.valid("json"),
    userId: user._id,
  });
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
    );
    if (!folder)
      return c.json({ success: false, error: "Folder not found" }, 404);
    return c.json({ success: true, data: folder });
  },
);

folders.delete("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const folder = await Folder.findOneAndUpdate(
    { _id: c.req.param("id"), userId: user._id },
    { isDeleted: true },
    { new: true },
  );
  if (!folder)
    return c.json({ success: false, error: "Folder not found" }, 404);
  return c.json({ success: true, data: null });
});

export default folders;
