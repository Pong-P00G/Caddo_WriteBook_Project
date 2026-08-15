import { serve } from "@hono/node-server";
import { serveStatic } from "@hono/node-server/serve-static";
import { Hono } from "hono";
import { cors } from "hono/cors";
import { logger } from "hono/logger";
import { prettyJSON } from "hono/pretty-json";
import { connectDB } from "./config/db.js";
import authRoutes from "./routes/auth.js";
import userRoutes from "./routes/users.js";
import noteRoutes from "./routes/notes.js";
import tagRoutes from "./routes/tags.js";
import workspaceRoutes from "./routes/workspaces.js";
import folderRoutes from "./routes/folders.js";
import settingRoutes from "./routes/settings.js";

await connectDB();

// ── Top-level app (static files + API) ──────────────
const root = new Hono();

root.use(
  "*",
  cors({
    origin: (origin) => origin || "*",
    credentials: true,
    allowMethods: ["GET", "POST", "PATCH", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization"],
  }),
);

// Serve uploaded files (avatars, etc.) from ./uploads/
root.use("/uploads/*", serveStatic({ root: "./" }));

// ── API sub-app ──────────────────────────────────────
const app = new Hono().basePath("/api/v1");

app.use("*", logger());
app.use("*", prettyJSON());

app.route("/auth", authRoutes);
app.route("/users", userRoutes);
app.route("/notes", noteRoutes);
app.route("/tags", tagRoutes);
app.route("/workspaces", workspaceRoutes);
app.route("/folders", folderRoutes);
app.route("/settings", settingRoutes);

app.get("/health", (c) => c.json({ status: "ok", ts: Date.now() }));
app.notFound((c) =>
  c.json({ success: false, message: "Route not found" }, 404),
);
app.onError((err, c) => {
  console.error(err);
  return c.json(
    { success: false, message: err.message || "Internal server error" },
    500,
  );
});

root.route("/", app);

const port = Number(process.env.PORT ?? 3000);
console.log(`🚀 Server running on http://localhost:${port}`);

serve({ fetch: root.fetch, port });
