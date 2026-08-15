<script setup lang="ts">
import { ref, onMounted, nextTick } from "vue";
import { RouterLink, useRoute, useRouter } from "vue-router";
import {
    BookOpen,
    Home,
    Briefcase,
    Folder,
    FolderOpen,
    Trash2,
    ChevronDown,
    ChevronRight,
    Settings,
    LogOut,
    Moon,
    Sun,
    Plus,
    X,
    Check,
    Loader2,
} from "lucide-vue-next";
import { useAuthStore } from "../store/auth";
import { useDarkMode } from "../composable/Darkmode";
import { useSidebarStore } from "../store/sidebar";

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const sidebar = useSidebarStore();
const { theme, toggle } = useDarkMode();

onMounted(() => sidebar.fetchAll());

function isActive(path: string) {
    if (path === "/app/notes") return route.path === "/app/notes";
    return route.path.startsWith(path);
}

async function handleLogout() {
    await auth.logout();
    router.push("/login");
}

// ── Section collapse state ─────────────────────────────────────────────────
const collapsed = ref({ workspaces: false, folders: false, tags: false });
function toggle_section(key: keyof typeof collapsed.value) {
    collapsed.value[key] = !collapsed.value[key];
}

// ── Folder expand state ─────────────────────────────────────────────────────
const foldersExpanded = ref<Record<string, boolean>>({});
function toggle_folder(id: string) {
    foldersExpanded.value[id] = !foldersExpanded.value[id];
}

// ════════════════════════════════════════════════════════════════════════════
// WORKSPACE CREATION
// ════════════════════════════════════════════════════════════════════════════
const WORKSPACE_EMOJIS = ["🏠", "💼", "📚", "🎨", "🔬", "🌱", "⚡", "🎯", "💡", "🗂️"];

const isCreatingWorkspace = ref(false);
const newWorkspaceName = ref("");
const newWorkspaceIcon = ref("🏠");
const workspaceCreateError = ref("");
const isSubmittingWorkspace = ref(false);
const workspaceNameInput = ref<HTMLInputElement | null>(null);

async function openWorkspaceCreate() {
    isCreatingWorkspace.value = true;
    newWorkspaceName.value = "";
    newWorkspaceIcon.value = "🏠";
    workspaceCreateError.value = "";
    collapsed.value.workspaces = false;
    await nextTick();
    workspaceNameInput.value?.focus();
}

function cancelWorkspaceCreate() {
    isCreatingWorkspace.value = false;
    newWorkspaceName.value = "";
    workspaceCreateError.value = "";
}

async function submitWorkspace() {
    const name = newWorkspaceName.value.trim();
    if (!name) return;
    isSubmittingWorkspace.value = true;
    workspaceCreateError.value = "";
    try {
        await sidebar.createWorkspace(name, newWorkspaceIcon.value);
        cancelWorkspaceCreate();
    } catch (e: any) {
        workspaceCreateError.value = e?.response?.data?.error ?? "Failed to create workspace";
    } finally {
        isSubmittingWorkspace.value = false;
    }
}

// ════════════════════════════════════════════════════════════════════════════
// FOLDER CREATION
// ════════════════════════════════════════════════════════════════════════════
const isCreatingFolder = ref(false);
const newFolderName = ref("");
const newFolderWsId = ref("");
const folderCreateError = ref("");
const isSubmittingFolder = ref(false);
const folderNameInput = ref<HTMLInputElement | null>(null);

async function openFolderCreate() {
    isCreatingFolder.value = true;
    newFolderName.value = "";
    newFolderWsId.value = sidebar.workspaces[0]?._id ?? "";
    folderCreateError.value = "";
    collapsed.value.folders = false;
    await nextTick();
    folderNameInput.value?.focus();
}

function cancelFolderCreate() {
    isCreatingFolder.value = false;
    newFolderName.value = "";
    folderCreateError.value = "";
}

async function submitFolder() {
    const name = newFolderName.value.trim();
    if (!name) return;
    if (!newFolderWsId.value) {
        folderCreateError.value = "Select a workspace first";
        return;
    }
    isSubmittingFolder.value = true;
    folderCreateError.value = "";
    try {
        await sidebar.createFolder(name, newFolderWsId.value);
        cancelFolderCreate();
    } catch (e: any) {
        folderCreateError.value = e?.response?.data?.error ?? "Failed to create folder";
    } finally {
        isSubmittingFolder.value = false;
    }
}

// ════════════════════════════════════════════════════════════════════════════
// TAG CREATION
// ════════════════════════════════════════════════════════════════════════════
const TAG_COLORS = [
    "#ef4444", "#f97316", "#eab308", "#22c55e", "#14b8a6",
    "#3b82f6", "#8b5cf6", "#ec4899", "#64748b", "#a16207",
    "#166534", "#1d4ed8", "#be185d", "#9333ea", "#0e7490", "#15803d",
];

const isCreatingTag = ref(false);
const newTagName = ref("");
const newTagColor = ref(TAG_COLORS[5]);
const showColorGrid = ref(false);
const tagCreateError = ref("");
const isSubmittingTag = ref(false);
const tagNameInput = ref<HTMLInputElement | null>(null);

async function openTagCreate() {
    isCreatingTag.value = true;
    showColorGrid.value = false;
    newTagName.value = "";
    newTagColor.value = TAG_COLORS[5];
    tagCreateError.value = "";
    collapsed.value.tags = false;
    await nextTick();
    tagNameInput.value?.focus();
}

function cancelTagCreate() {
    isCreatingTag.value = false;
    showColorGrid.value = false;
    newTagName.value = "";
    tagCreateError.value = "";
}

async function submitTag() {
    const name = newTagName.value.trim();
    if (!name) return;
    isSubmittingTag.value = true;
    tagCreateError.value = "";
    try {
        await sidebar.createTag(name, newTagColor.value);
        cancelTagCreate();
    } catch (e: any) {
        tagCreateError.value = e?.response?.data?.error ?? "Failed to create tag";
    } finally {
        isSubmittingTag.value = false;
    }
}

async function deleteTag(id: string, e: MouseEvent) {
    e.stopPropagation();
    await sidebar.deleteTag(id);
}

// ════════════════════════════════════════════════════════════════════════════
// HELPERS
// ════════════════════════════════════════════════════════════════════════════
function getWorkspaceIcon(ws: { icon?: string }) {
    const iconMap: Record<string, string> = {
        "🏠": "home", "💼": "briefcase", "📚": "book", "🎨": "palette",
        "🔬": "flask", "🌱": "sprout", "⚡": "zap", "🎯": "target",
        "💡": "bulb", "🗂️": "folder",
    };
    return iconMap[ws.icon || "🏠"] || "home";
}

async function handleDeleteWorkspace(ws: any, e: MouseEvent) {
    e.preventDefault();
    e.stopPropagation();
    if (!confirm(`Are you sure you want to delete workspace "${ws.name}"? Notes and folders inside will be moved to trash.`)) {
        return;
    }
    try {
        await sidebar.deleteWorkspace(ws._id);
        if (route.path.includes(ws._id)) {
            router.push('/app/notes');
        }
    } catch (err: any) {
        alert(err?.response?.data?.error ?? 'Failed to delete workspace');
    }
}

async function handleDeleteFolder(folder: any, e: MouseEvent) {
    e.preventDefault();
    e.stopPropagation();
    if (!confirm(`Are you sure you want to delete folder "${folder.name}"? Notes inside will be moved to trash.`)) {
        return;
    }
    try {
        await sidebar.deleteFolder(folder._id);
        if (route.path.includes(folder._id)) {
            router.push('/app/notes');
        }
    } catch (err: any) {
        alert(err?.response?.data?.error ?? 'Failed to delete folder');
    }
}
</script>

<template>
    <aside
        class="w-[280px] bg-[#f7f7f7] dark:bg-[#1a1a1a] flex flex-col shrink-0 overflow-hidden h-full border-r border-[#e0e0e0] dark:border-[#333]"
    >
        <!-- ── Logo ──────────────────────────────────────────────── -->
        <div class="px-4 py-4 border-b border-[#e0e0e0] dark:border-[#333] shrink-0">
            <RouterLink to="/app/notes" class="flex items-center gap-2.5">
                <div
                    class="w-7 h-7 bg-amber-500 rounded-lg flex items-center justify-center shrink-0"
                >
                    <BookOpen :size="14" class="text-white" />
                </div>
                <span class="font-semibold text-sm text-[#1a1a1a] dark:text-[#f5f5f5] tracking-tight">
                    Caddo Notes
                </span>
            </RouterLink>
        </div>

        <!-- ── Scrollable body ─────────────────────────────────────── -->
        <div class="flex-1 overflow-y-auto py-3">

            <!-- ════ BLOCK: WORKSPACES ════════════════════════════════════ -->
            <div class="px-4">
                <div class="flex items-center justify-between mb-2 px-2">
                    <p class="text-[11px] font-semibold text-[#999] dark:text-[#666] uppercase tracking-wider">
                        Workspaces
                    </p>
                    <button
                        v-if="!isCreatingWorkspace"
                        @click="openWorkspaceCreate"
                        class="p-1 rounded text-[#999] hover:text-[#666] hover:bg-[#ebebeb] dark:hover:bg-[#2a2a2a] dark:hover:text-[#999] transition-colors"
                        title="New workspace"
                    >
                        <Plus :size="14" />
                    </button>
                    <button
                        v-else
                        @click="cancelWorkspaceCreate"
                        class="p-1 rounded text-[#999] hover:text-red-500 hover:bg-[#ebebeb] dark:hover:bg-[#2a2a2a] transition-colors"
                    >
                        <X :size="14" />
                    </button>
                </div>

                <!-- Create workspace form -->
                <Transition
                    enter-active-class="transition-all duration-200 ease-out"
                    enter-from-class="opacity-0 -translate-y-1"
                    enter-to-class="opacity-100 translate-y-0"
                    leave-active-class="transition-all duration-150 ease-in"
                    leave-from-class="opacity-100 translate-y-0"
                    leave-to-class="opacity-0 -translate-y-1"
                >
                    <div v-if="isCreatingWorkspace" class="mb-2 bg-white dark:bg-[#252525] rounded-xl border border-[#e0e0e0] dark:border-[#3a3a3a] overflow-hidden shadow-sm">
                        <div class="flex items-center gap-2 px-3 py-2.5 border-b border-[#f0f0f0] dark:border-[#3a3a3a]">
                            <span class="text-base leading-none select-none">{{ newWorkspaceIcon }}</span>
                            <input
                                ref="workspaceNameInput"
                                v-model="newWorkspaceName"
                                @keydown.enter="submitWorkspace"
                                @keydown.escape="cancelWorkspaceCreate"
                                type="text"
                                placeholder="Workspace name…"
                                maxlength="80"
                                class="flex-1 text-xs bg-transparent outline-none text-[#1a1a1a] dark:text-[#f5f5f5] placeholder-[#999] dark:placeholder-[#666]"
                            />
                        </div>
                        <div class="px-3 py-2.5 border-b border-[#f0f0f0] dark:border-[#3a3a3a]">
                            <p class="text-[10px] font-medium text-[#999] dark:text-[#666] uppercase tracking-wider mb-1.5">Icon</p>
                            <div class="flex flex-wrap gap-1.5">
                                <button
                                    v-for="emoji in WORKSPACE_EMOJIS"
                                    :key="emoji"
                                    @click="newWorkspaceIcon = emoji"
                                    class="text-base w-7 h-7 flex items-center justify-center rounded-lg transition-all hover:scale-110"
                                    :class="newWorkspaceIcon === emoji ? 'bg-[#f0f0f0] dark:bg-[#3a3a3a] ring-2 ring-amber-400' : 'hover:bg-[#f0f0f0] dark:hover:bg-[#3a3a3a]'"
                                >
                                    {{ emoji }}
                                </button>
                            </div>
                        </div>
                        <p v-if="workspaceCreateError" class="px-3 py-1.5 text-[10px] text-red-500">{{ workspaceCreateError }}</p>
                        <div class="flex items-center gap-2 px-3 py-2">
                            <button
                                @click="submitWorkspace"
                                :disabled="!newWorkspaceName.trim() || isSubmittingWorkspace"
                                class="flex items-center gap-1.5 px-3 py-1.5 bg-[#1a1a1a] dark:bg-amber-500 text-white dark:text-[#1a1a1a] rounded-lg text-xs font-semibold disabled:opacity-40 hover:bg-[#333] dark:hover:bg-amber-600 transition-colors"
                            >
                                <Loader2 v-if="isSubmittingWorkspace" :size="10" class="animate-spin" />
                                <Check v-else :size="10" />
                                Create
                            </button>
                            <button @click="cancelWorkspaceCreate" class="px-3 py-1.5 text-xs text-[#999] hover:text-[#666] transition-colors">
                                Cancel
                            </button>
                        </div>
                    </div>
                </Transition>

                <!-- Workspace list -->
                <div v-if="!collapsed.workspaces" class="space-y-0.5">
                    <div
                        v-for="ws in sidebar.workspaces"
                        :key="ws._id"
                        class="group flex items-center justify-between rounded-lg transition-colors"
                        :class="
                            isActive(ws._id === sidebar.workspaces[0]?._id ? '/app/notes' : `/app/workspace/${ws._id}`)
                                ? 'bg-white dark:bg-[#252525] text-[#1a1a1a] dark:text-[#f5f5f5] font-medium shadow-sm'
                                : 'text-[#666] dark:text-[#999] hover:bg-white/70 dark:hover:bg-[#252525]/70 hover:text-[#1a1a1a] dark:hover:text-[#f5f5f5]'
                        "
                    >
                        <RouterLink
                            :to="ws._id === sidebar.workspaces[0]?._id ? '/app/notes' : `/app/workspace/${ws._id}`"
                            class="flex-1 min-w-0 flex items-center gap-3 px-3 py-2 text-sm"
                        >
                            <Home v-if="getWorkspaceIcon(ws) === 'home'" :size="16" class="shrink-0 text-[#999] dark:text-[#666]" />
                            <Briefcase v-else :size="16" class="shrink-0 text-[#999] dark:text-[#666]" />
                            <span class="truncate">{{ ws.name }}</span>
                        </RouterLink>
                        <button
                            @click="handleDeleteWorkspace(ws, $event)"
                            class="opacity-0 group-hover:opacity-100 p-1 mr-1.5 rounded hover:bg-red-100 dark:hover:bg-red-900/30 text-[#999] hover:text-red-500 transition-all shrink-0"
                            title="Delete workspace"
                        >
                            <Trash2 :size="13" />
                        </button>
                    </div>
                    <p
                        v-if="!sidebar.loading && sidebar.workspaces.length === 0 && !isCreatingWorkspace"
                        class="px-3 py-2 text-xs text-[#999] dark:text-[#666]"
                    >
                        No workspaces — click <span class="font-semibold">+</span> to create
                    </p>
                </div>
            </div>

            <!-- ════ BLOCK: FOLDERS ═══════════════════════════════════════ -->
            <div class="px-4 mt-5">
                <div class="flex items-center justify-between mb-2 px-2">
                    <p class="text-[11px] font-semibold text-[#999] dark:text-[#666] uppercase tracking-wider">
                        Folders
                    </p>
                    <button
                        v-if="!isCreatingFolder"
                        @click="openFolderCreate"
                        class="p-1 rounded text-[#999] hover:text-[#666] hover:bg-[#ebebeb] dark:hover:bg-[#2a2a2a] dark:hover:text-[#999] transition-colors"
                        title="New folder"
                    >
                        <Plus :size="14" />
                    </button>
                    <button
                        v-else
                        @click="cancelFolderCreate"
                        class="p-1 rounded text-[#999] hover:text-red-500 hover:bg-[#ebebeb] dark:hover:bg-[#2a2a2a] transition-colors"
                    >
                        <X :size="14" />
                    </button>
                </div>

                <!-- Create folder form -->
                <Transition
                    enter-active-class="transition-all duration-200 ease-out"
                    enter-from-class="opacity-0 -translate-y-1"
                    enter-to-class="opacity-100 translate-y-0"
                    leave-active-class="transition-all duration-150 ease-in"
                    leave-from-class="opacity-100 translate-y-0"
                    leave-to-class="opacity-0 -translate-y-1"
                >
                    <div v-if="isCreatingFolder" class="mb-2 bg-white dark:bg-[#252525] rounded-xl border border-[#e0e0e0] dark:border-[#3a3a3a] overflow-hidden shadow-sm">
                        <div v-if="sidebar.workspaces.length === 0" class="px-3 py-2.5">
                            <p class="text-xs text-amber-600 dark:text-amber-400">Create a workspace first.</p>
                        </div>
                        <template v-else>
                            <div class="flex items-center gap-2 px-3 py-2.5 border-b border-[#f0f0f0] dark:border-[#3a3a3a]">
                                <Folder :size="12" class="text-[#999] dark:text-[#666] shrink-0" />
                                <input
                                    ref="folderNameInput"
                                    v-model="newFolderName"
                                    @keydown.enter="submitFolder"
                                    @keydown.escape="cancelFolderCreate"
                                    type="text"
                                    placeholder="Folder name…"
                                    maxlength="100"
                                    class="flex-1 text-xs bg-transparent outline-none text-[#1a1a1a] dark:text-[#f5f5f5] placeholder-[#999] dark:placeholder-[#666]"
                                />
                            </div>
                            <div v-if="sidebar.workspaces.length > 1" class="px-3 py-2 border-b border-[#f0f0f0] dark:border-[#3a3a3a]">
                                <p class="text-[10px] font-medium text-[#999] dark:text-[#666] uppercase tracking-wider mb-1.5">Workspace</p>
                                <select
                                    v-model="newFolderWsId"
                                    class="w-full text-xs bg-[#fafafa] dark:bg-[#1a1a1a] border border-[#e0e0e0] dark:border-[#3a3a3a] rounded-lg px-2 py-1.5 text-[#666] dark:text-[#999] outline-none focus:ring-2 focus:ring-amber-400"
                                >
                                    <option v-for="ws in sidebar.workspaces" :key="ws._id" :value="ws._id">
                                        {{ ws.icon || "🏠" }} {{ ws.name }}
                                    </option>
                                </select>
                            </div>
                            <p v-if="folderCreateError" class="px-3 py-1.5 text-[10px] text-red-500">{{ folderCreateError }}</p>
                            <div class="flex items-center gap-2 px-3 py-2">
                                <button
                                    @click="submitFolder"
                                    :disabled="!newFolderName.trim() || isSubmittingFolder"
                                    class="flex items-center gap-1.5 px-3 py-1.5 bg-[#1a1a1a] dark:bg-amber-500 text-white dark:text-[#1a1a1a] rounded-lg text-xs font-semibold disabled:opacity-40 hover:bg-[#333] dark:hover:bg-amber-600 transition-colors"
                                >
                                    <Loader2 v-if="isSubmittingFolder" :size="10" class="animate-spin" />
                                    <Check v-else :size="10" />
                                    Create
                                </button>
                                <button @click="cancelFolderCreate" class="px-3 py-1.5 text-xs text-[#999] hover:text-[#666] transition-colors">
                                    Cancel
                                </button>
                            </div>
                        </template>
                    </div>
                </Transition>

                <!-- Folder list -->
                <div v-if="!collapsed.folders" class="space-y-0.5">
                    <div
                        v-for="folder in sidebar.folders"
                        :key="folder._id"
                        class="group flex items-center justify-between rounded-lg hover:bg-white/70 dark:hover:bg-[#252525]/70 transition-colors"
                    >
                        <RouterLink
                            :to="`/app/folder/${folder._id}`"
                            class="flex-1 min-w-0 flex items-center gap-3 px-3 py-2 text-sm text-[#666] dark:text-[#999] hover:text-[#1a1a1a] dark:hover:text-[#f5f5f5]"
                        >
                            <ChevronDown
                                v-if="foldersExpanded[folder._id]"
                                :size="12"
                                class="shrink-0 text-[#bbb] dark:text-[#555]"
                            />
                            <ChevronRight
                                v-else
                                :size="12"
                                class="shrink-0 text-[#bbb] dark:text-[#555]"
                            />
                            <FolderOpen
                                v-if="foldersExpanded[folder._id]"
                                :size="15"
                                class="shrink-0 text-[#999] dark:text-[#666]"
                            />
                            <Folder
                                v-else
                                :size="15"
                                class="shrink-0 text-[#999] dark:text-[#666]"
                            />
                            <span class="truncate">{{ folder.name }}</span>
                        </RouterLink>
                        <button
                            @click="handleDeleteFolder(folder, $event)"
                            class="opacity-0 group-hover:opacity-100 p-1 mr-1.5 rounded hover:bg-red-100 dark:hover:bg-red-900/30 text-[#999] hover:text-red-500 transition-all shrink-0"
                            title="Delete folder"
                        >
                            <Trash2 :size="13" />
                        </button>
                    </div>
                    <p
                        v-if="!sidebar.loading && sidebar.folders.length === 0 && !isCreatingFolder"
                        class="px-3 py-2 text-xs text-[#999] dark:text-[#666]"
                    >
                        No folders — click <span class="font-semibold">+</span> to create
                    </p>
                </div>
            </div>

            <!-- ════ BLOCK: TAGS ══════════════════════════════════════════ -->
            <div class="px-4 mt-5">
                <div class="flex items-center justify-between mb-2 px-2">
                    <p class="text-[11px] font-semibold text-[#999] dark:text-[#666] uppercase tracking-wider">
                        Tags
                    </p>
                    <button
                        v-if="!isCreatingTag"
                        @click="openTagCreate"
                        class="p-1 rounded text-[#999] hover:text-[#666] hover:bg-[#ebebeb] dark:hover:bg-[#2a2a2a] dark:hover:text-[#999] transition-colors"
                        title="New tag"
                    >
                        <Plus :size="14" />
                    </button>
                    <button
                        v-else
                        @click="cancelTagCreate"
                        class="p-1 rounded text-[#999] hover:text-red-500 hover:bg-[#ebebeb] dark:hover:bg-[#2a2a2a] transition-colors"
                    >
                        <X :size="14" />
                    </button>
                </div>

                <!-- Create tag form -->
                <Transition
                    enter-active-class="transition-all duration-200 ease-out"
                    enter-from-class="opacity-0 -translate-y-1"
                    enter-to-class="opacity-100 translate-y-0"
                    leave-active-class="transition-all duration-150 ease-in"
                    leave-from-class="opacity-100 translate-y-0"
                    leave-to-class="opacity-0 -translate-y-1"
                >
                    <div v-if="isCreatingTag" class="mb-2 bg-white dark:bg-[#252525] rounded-xl border border-[#e0e0e0] dark:border-[#3a3a3a] overflow-hidden shadow-sm">
                        <div class="flex items-center gap-2 px-3 py-2.5 border-b border-[#f0f0f0] dark:border-[#3a3a3a]">
                            <button
                                @click="showColorGrid = !showColorGrid"
                                class="w-4 h-4 rounded-full shrink-0 ring-1 ring-[#e0e0e0] dark:ring-[#3a3a3a] ring-offset-1 transition-transform hover:scale-110"
                                :style="{ backgroundColor: newTagColor }"
                                title="Pick a color"
                            />
                            <input
                                ref="tagNameInput"
                                v-model="newTagName"
                                @keydown.enter="submitTag"
                                @keydown.escape="cancelTagCreate"
                                type="text"
                                placeholder="Tag name…"
                                maxlength="50"
                                class="flex-1 text-xs bg-transparent outline-none text-[#1a1a1a] dark:text-[#f5f5f5] placeholder-[#999] dark:placeholder-[#666]"
                            />
                        </div>
                        <Transition
                            enter-active-class="transition-all duration-150 ease-out"
                            enter-from-class="opacity-0 scale-95"
                            enter-to-class="opacity-100 scale-100"
                            leave-active-class="transition-all duration-100 ease-in"
                            leave-from-class="opacity-100 scale-100"
                            leave-to-class="opacity-0 scale-95"
                        >
                            <div v-if="showColorGrid" class="px-3 py-2.5 border-b border-[#f0f0f0] dark:border-[#3a3a3a]">
                                <p class="text-[10px] font-medium text-[#999] dark:text-[#666] uppercase tracking-wider mb-2">Color</p>
                                <div class="grid grid-cols-8 gap-1.5">
                                    <button
                                        v-for="color in TAG_COLORS"
                                        :key="color"
                                        @click="newTagColor = color; showColorGrid = false"
                                        class="w-5 h-5 rounded-full transition-all hover:scale-125 active:scale-95 focus:outline-none"
                                        :style="{ backgroundColor: color }"
                                        :class="newTagColor === color ? 'ring-2 ring-offset-1 ring-[#666] dark:ring-[#999] scale-110' : 'ring-1 ring-[#e0e0e0] dark:ring-[#3a3a3a]'"
                                    />
                                </div>
                            </div>
                        </Transition>
                        <p v-if="tagCreateError" class="px-3 py-1.5 text-[10px] text-red-500">{{ tagCreateError }}</p>
                        <div class="flex items-center gap-2 px-3 py-2">
                            <button
                                @click="submitTag"
                                :disabled="!newTagName.trim() || isSubmittingTag"
                                class="flex items-center gap-1.5 px-3 py-1.5 bg-[#1a1a1a] dark:bg-amber-500 text-white dark:text-[#1a1a1a] rounded-lg text-xs font-semibold disabled:opacity-40 hover:bg-[#333] dark:hover:bg-amber-600 transition-colors"
                            >
                                <Loader2 v-if="isSubmittingTag" :size="10" class="animate-spin" />
                                <Check v-else :size="10" />
                                Create
                            </button>
                            <button @click="cancelTagCreate" class="px-3 py-1.5 text-xs text-[#999] hover:text-[#666] transition-colors">
                                Cancel
                            </button>
                        </div>
                    </div>
                </Transition>

                <!-- Tag list -->
                <div v-if="!collapsed.tags" class="px-2 mt-1">
                    <div v-if="sidebar.tags.length" class="flex flex-wrap gap-2">
                        <span
                            v-for="tag in sidebar.tags"
                            :key="tag._id"
                            class="group/tag inline-flex items-center gap-1 pl-2 pr-1 py-1 rounded-full text-xs cursor-pointer border transition-all"
                            :style="{
                                backgroundColor: tag.color + '18',
                                borderColor: tag.color + '40',
                                color: tag.color,
                            }"
                        >
                            <span class="w-1.5 h-1.5 rounded-full" :style="{ backgroundColor: tag.color }" />
                            <span>#{{ tag.name }}</span>
                            <button
                                @click="deleteTag(tag._id, $event)"
                                class="ml-0.5 w-3.5 h-3.5 rounded-full flex items-center justify-center opacity-0 group-hover/tag:opacity-100 hover:bg-black/10 dark:hover:bg-white/10 transition-all"
                            >
                                <X :size="8" />
                            </button>
                        </span>
                    </div>
                    <p
                        v-else-if="!sidebar.loading && !isCreatingTag"
                        class="text-xs text-[#999] dark:text-[#666] py-1"
                    >
                        No tags — click <span class="font-semibold">+</span> to create
                    </p>
                </div>
            </div>

            <!-- ── Divider & Trash ───────────────────────────────────── -->
            <div class="px-4 mt-5">
                <div class="border-t border-[#e0e0e0] dark:border-[#333] mb-4" />
                <RouterLink
                    to="/app/trash"
                    class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-[#999] dark:text-[#666] hover:bg-white/70 dark:hover:bg-[#252525]/70 hover:text-[#666] dark:hover:text-[#999] transition-colors"
                    :class="isActive('/app/trash') ? 'bg-white dark:bg-[#252525] shadow-sm' : ''"
                >
                    <Trash2 :size="15" class="shrink-0" />
                    Trash
                </RouterLink>
            </div>
        </div>

        <!-- ── Bottom ─────────────────────────────────────────────── -->
        <div class="shrink-0 border-t border-[#e0e0e0] dark:border-[#333] px-2 py-3 space-y-0.5">
            <RouterLink
                to="/app/profile"
                class="flex items-center gap-2.5 px-3 py-1.5 rounded-lg hover:bg-white/70 dark:hover:bg-[#252525]/70 transition-colors group"
                :class="isActive('/app/profile') ? 'bg-white dark:bg-[#252525] shadow-sm' : ''"
            >
                <div
                    class="w-6 h-6 rounded-full bg-amber-500 flex items-center justify-center text-white text-xs font-bold shrink-0 overflow-hidden"
                >
                    <img
                        v-if="auth.user?.avatar"
                        :src="auth.user.avatar"
                        :alt="auth.user?.name"
                        class="w-full h-full object-cover"
                    />
                    <span v-else class="dark:text-[#1a1a1a]">{{ auth.user?.name?.charAt(0).toUpperCase() }}</span>
                </div>
                <span class="text-sm text-[#666] dark:text-[#999] group-hover:text-[#1a1a1a] dark:group-hover:text-[#f5f5f5] truncate font-medium flex-1">
                    {{ auth.user?.name }}
                </span>
            </RouterLink>
            <RouterLink
                to="/app/settings"
                class="flex items-center gap-2.5 px-3 py-1.5 rounded-lg text-sm transition-colors"
                :class="
                    isActive('/app/settings')
                        ? 'bg-white dark:bg-[#252525] text-[#1a1a1a] dark:text-[#f5f5f5] shadow-sm'
                        : 'text-[#999] dark:text-[#666] hover:bg-white/70 dark:hover:bg-[#252525]/70 hover:text-[#666] dark:hover:text-[#999]'
                "
            >
                <Settings :size="14" class="shrink-0" />
                Settings
            </RouterLink>

            <button
                @click="toggle"
                class="w-full flex items-center gap-2.5 px-3 py-1.5 rounded-lg text-sm text-[#999] dark:text-[#666] hover:bg-white/70 dark:hover:bg-[#252525]/70 hover:text-[#666] dark:hover:text-[#999] transition-colors"
            >
                <Sun v-if="theme === 'dark'" :size="14" class="shrink-0" />
                <Moon v-else :size="14" class="shrink-0" />
                {{ theme === "dark" ? "Light mode" : "Dark mode" }}
            </button>
            <button
                @click="handleLogout"
                class="w-full flex items-center gap-2.5 px-3 py-1.5 rounded-lg text-sm text-[#999] dark:text-[#666] hover:bg-red-50 dark:hover:bg-red-950/20 hover:text-red-600 dark:hover:text-red-400 transition-colors"
            >
                <LogOut :size="14" class="shrink-0" />
                Sign out
            </button>
        </div>
    </aside>
</template>