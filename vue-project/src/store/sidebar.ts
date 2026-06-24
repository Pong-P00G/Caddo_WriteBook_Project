import { defineStore } from "pinia";
import { ref } from "vue";
import api from "../api/Api";
import type { Workspace, Folder, Tag, ApiResponse } from "./types/interface";

export const useSidebarStore = defineStore("sidebar", () => {
  const workspaces = ref<Workspace[]>([]);
  const folders = ref<Folder[]>([]);
  const tags = ref<Tag[]>([]);
  const loading = ref(false);

  // ── Fetch all ───────────────────────────────────────────────────────────────
  async function fetchAll() {
    loading.value = true;
    try {
      const [ws, fl, tg] = await Promise.allSettled([
        api.get<ApiResponse<Workspace[]>>("/workspaces"),
        api.get<ApiResponse<Folder[]>>("/folders"),
        api.get<ApiResponse<Tag[]>>("/tags"),
      ]);
      if (ws.status === "fulfilled") workspaces.value = ws.value.data.data;
      if (fl.status === "fulfilled") folders.value = fl.value.data.data;
      if (tg.status === "fulfilled") tags.value = tg.value.data.data;
    } finally {
      loading.value = false;
    }
  }

  // ── Tags ────────────────────────────────────────────────────────────────────
  async function createTag(name: string, color: string): Promise<Tag> {
    const { data } = await api.post<ApiResponse<Tag>>("/tags", {
      name: name.trim().toLowerCase(),
      color,
    });
    tags.value.push(data.data);
    return data.data;
  }

  async function deleteTag(id: string): Promise<void> {
    await api.delete(`/tags/${id}`);
    tags.value = tags.value.filter((t) => t._id !== id);
  }

  async function updateTag(
    id: string,
    payload: Partial<Pick<Tag, "name" | "color">>,
  ): Promise<Tag> {
    const { data } = await api.patch<ApiResponse<Tag>>(`/tags/${id}`, payload);
    const idx = tags.value.findIndex((t) => t._id === id);
    if (idx !== -1) tags.value[idx] = data.data;
    return data.data;
  }

  // ── Folders ─────────────────────────────────────────────────────────────────
  async function createFolder(
    name: string,
    workspaceId: string,
  ): Promise<Folder> {
    const { data } = await api.post<ApiResponse<Folder>>("/folders", {
      name: name.trim(),
      workspaceId,
    });
    folders.value.push(data.data);
    return data.data;
  }

  // ── Workspaces ──────────────────────────────────────────────────────────────
  async function createWorkspace(
    name: string,
    icon?: string,
  ): Promise<Workspace> {
    const { data } = await api.post<ApiResponse<Workspace>>("/workspaces", {
      name: name.trim(),
      icon,
    });
    workspaces.value.push(data.data);
    return data.data;
  }

  return {
    workspaces,
    folders,
    tags,
    loading,
    fetchAll,
    createTag,
    deleteTag,
    updateTag,
    createFolder,
    createWorkspace,
  };
});
