import { Hono } from "hono";
import { zValidator } from "@hono/zod-validator";
import { z } from "zod";
import { authMiddleware } from "../middleware/auth.js";
import { UserSettings } from "../models/UserSetting.js";
import type { IUser } from "../models/User.js";

type Variables = { user: IUser };

const settings = new Hono<{ Variables: Variables }>();
settings.use("*", authMiddleware);

const updateSchema = z.object({
  appearance: z
    .object({
      theme: z.enum(["light", "dark", "system"]).optional(),
      fontSize: z.number().min(10).max(24).optional(),
      fontFamily: z.string().optional(),
      lineNumbers: z.boolean().optional(),
    })
    .optional(),
  editor: z
    .object({
      defaultView: z.enum(["editor", "preview", "split"]).optional(),
      spellcheck: z.boolean().optional(),
      autoSaveInterval: z.number().optional(),
    })
    .optional(),
  layout: z
    .object({
      sidebarCollapsed: z.boolean().optional(),
      defaultWorkspaceId: z.string().nullable().optional(),
    })
    .optional(),
  revisions: z
    .object({
      retentionPeriod: z.enum(["1m", "3m", "6m", "1y", "never"]).optional(),
    })
    .optional(),
});

settings.get("/me", async (c) => {
  const user = c.get("user") as IUser;
  let s = await UserSettings.findOne({ userId: user._id });
  if (!s) s = await UserSettings.create({ userId: user._id });
  return c.json({ success: true, data: s });
});

settings.patch("/me", zValidator("json", updateSchema), async (c) => {
  const user = c.get("user") as IUser;
  const payload = c.req.valid("json");

  // Build a flat $set for nested fields
  const set: Record<string, unknown> = {};
  if (payload.appearance) {
    for (const [k, v] of Object.entries(payload.appearance)) {
      if (v !== undefined) set[`appearance.${k}`] = v;
    }
  }
  if (payload.editor) {
    for (const [k, v] of Object.entries(payload.editor)) {
      if (v !== undefined) set[`editor.${k}`] = v;
    }
  }
  if (payload.layout) {
    for (const [k, v] of Object.entries(payload.layout)) {
      if (v !== undefined) set[`layout.${k}`] = v;
    }
  }
  if (payload.revisions) {
    for (const [k, v] of Object.entries(payload.revisions)) {
      if (v !== undefined) set[`revisions.${k}`] = v;
    }
  }

  const s = await UserSettings.findOneAndUpdate(
    { userId: user._id },
    { $set: set },
    { new: true, upsert: true },
  );
  return c.json({ success: true, data: s });
});

export default settings;
