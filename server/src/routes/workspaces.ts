import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { authMiddleware } from "../middleware/auth.js";
import { Workspace } from "../models/Workspace.js";
import type { IUser } from "../models/User.js";

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
  const list = await Workspace.find({ userId: user._id }).sort({
    createdAt: 1,
  });
  return c.json({ success: true, data: list });
});

workspaces.post("/", zValidator("json", schema), async (c) => {
  const user = c.get("user") as IUser;
  const ws = await Workspace.create({
    ...c.req.valid("json"),
    userId: user._id,
  });
  return c.json({ success: true, data: ws }, 201);
});

workspaces.patch("/:id", zValidator("json", schema.partial()), async (c) => {
  const user = c.get("user") as IUser;
  const ws = await Workspace.findOneAndUpdate(
    { _id: c.req.param("id"), userId: user._id },
    c.req.valid("json"),
    { new: true },
  );
  if (!ws) return c.json({ success: false, error: "Workspace not found" }, 404);
  return c.json({ success: true, data: ws });
});

workspaces.delete("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const ws = await Workspace.findOneAndDelete({
    _id: c.req.param("id"),
    userId: user._id,
  });
  if (!ws) return c.json({ success: false, error: "Workspace not found" }, 404);
  return c.json({ success: true, data: null });
});

export default workspaces;
