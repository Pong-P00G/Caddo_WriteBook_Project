import { createRouter, createWebHistory } from "vue-router";
import { useAuthStore } from "@/store/auth";

const router = createRouter({
  history: createWebHistory(),
  routes: [
    // Public
    {
      path: "/",
      component: () => import("../views/HomeViews.vue"),
    },
    {
      path: "/login",
      component: () => import("../views/auth/Login.vue"),
      meta: { guest: true },
    },
    {
      path: "/register",
      component: () => import("../views/auth/Register.vue"),
      meta: { guest: true },
    },

    // App shell (auth required)
    {
      path: "/app",
      component: () => import("../components/layout/AppLayout.vue"),
      meta: { requiresAuth: true },
      children: [
        { path: "", redirect: "/app/notes" },
        {
          path: "notes",
          name: "notes",
          component: () => import("../views/Notes.vue"),
        },
        {
          path: "notes/new",
          name: "new-note",
          component: () => import("../views/NewNote.vue"),
        },
        {
          path: "notes/:noteId",
          name: "note",
          component: () => import("../views/NoteDetail.vue"),
        },
        {
          path: "notes/:noteId/edit",
          name: "editor",
          component: () => import("../views/Editor.vue"),
        },
        {
          path: "library",
          name: "library",
          component: () => import("../views/AllNotes.vue"),
        },
        {
          path: "settings",
          name: "settings",
          component: () => import("../views/Settings.vue"),
        },
        {
          path: "profile",
          name: "profile",
          component: () => import("../views/Profile.vue"),
        },
        {
          path: "trash",
          name: "trash",
          component: () => import("../views/Trash.vue"),
        },
        {
          path: "folder/:folderId",
          name: "folder",
          component: () => import("../views/Folder.vue"),
        },
        {
          path: "workspace/:workspaceId",
          name: "workspace",
          component: () => import("../views/Workspace.vue"),
        },
      ],
    },

    // Public note reading
    {
      path: "/read/:noteId",
      component: () => import("../views/ReadViews.vue"),
    },

    // 404
    {
      path: "/:pathMatch(.*)*",
      component: () => import("../views/NotFoundView.vue"),
    },
  ],
});

router.beforeEach((to) => {
  const auth = useAuthStore();

  if (to.meta.requiresAuth && !auth.isAuthenticated) {
    return { path: "/login", query: { redirect: to.fullPath } };
  }
  if (to.meta.guest && auth.isAuthenticated) {
    return { path: "/app/notes" };
  }
});

export default router;
