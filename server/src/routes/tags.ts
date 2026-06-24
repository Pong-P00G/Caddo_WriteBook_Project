import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { authMiddleware } from "../middleware/auth.js";
import { Tag } from "../models/Tag.js";
import type { IUser } from "../models/User.js";

type Variables = { user: IUser };

const tags = new Hono<{ Variables: Variables }>();
tags.use("*", authMiddleware);

const schema = z.object({
  name: z.string().min(1).max(50),
  color: z.string().optional(),
  icon: z.string().optional(),
});

tags.get("/", async (c) => {
  const user = c.get("user") as IUser;
  const list = await Tag.find({ userId: user._id }).sort({ name: 1 });
  return c.json({ success: true, data: list });
});

tags.post("/", zValidator("json", schema), async (c) => {
  const user = c.get("user") as IUser;
  const payload = c.req.valid("json");
  try {
    const tag = await Tag.create({ ...payload, userId: user._id });
    return c.json({ success: true, data: tag }, 201);
  } catch (err: any) {
    if (err.code === 11000)
      return c.json({ success: false, error: "Tag already exists" }, 409);
    throw err;
  }
});

tags.patch("/:id", zValidator("json", schema.partial()), async (c) => {
  const user = c.get("user") as IUser;
  const tag = await Tag.findOneAndUpdate(
    { _id: c.req.param("id"), userId: user._id },
    c.req.valid("json"),
    { new: true },
  );
  if (!tag) return c.json({ success: false, error: "Tag not found" }, 404);
  return c.json({ success: true, data: tag });
});

tags.delete("/:id", async (c) => {
  const user = c.get("user") as IUser;
  const tag = await Tag.findOneAndDelete({
    _id: c.req.param("id"),
    userId: user._id,
  });
  if (!tag) return c.json({ success: false, error: "Tag not found" }, 404);
  return c.json({ success: true, data: null });
});

export default tags;
