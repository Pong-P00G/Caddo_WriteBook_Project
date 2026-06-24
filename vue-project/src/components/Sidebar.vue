<script setup lang="ts">
import { onMounted, ref, nextTick } from "vue";
import { RouterLink, useRoute, useRouter } from "vue-router";
import {
    BookOpen,
    StickyNote,
    PenLine,
    Settings,
    LogOut,
    Moon,
    Sun,
    Folder,
    Trash2,
    Plus,
    ChevronRight,
    X,
    Check,
    Loader2,
} from "lucide-vue-next";
import { useAuthStore } from "@/store/auth";
import { useDarkMode } from "@/composable/Darkmode";
import { useSidebarStore } from "@/store/sidebar";

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

// ── Tag creation ───────────────────────────────────────────────────────────
const TAG_COLORS = [
    "#ef4444",
    "#f97316",
    "#eab308",
    "#22c55e",
    "#14b8a6",
    "#3b82f6",
    "#8b5cf6",
    "#ec4899",
    "#64748b",
    "#a16207",
    "#166534",
    "#1d4ed8",
    "#be185d",
    "#9333ea",
    "#0e7490",
    "#15803d",
];

const isCreatingTag = ref(false);
const newTagName = ref("");
const newTagColor = ref(TAG_COLORS[5]); // default blue
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
    collapsed.value.tags = false; // expand section
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
        tagCreateError.value =
            e?.response?.data?.error ?? "Failed to create tag";
    } finally {
        isSubmittingTag.value = false;
    }
}

async function deleteTag(id: string, e: MouseEvent) {
    e.stopPropagation();
    await sidebar.deleteTag(id);
}

// ── Workspace creation ────────────────────────────────────────────────────
const WORKSPACE_EMOJIS = [
    "🏠",
    "💼",
    "📚",
    "🎨",
    "🔬",
    "🌱",
    "⚡",
    "🎯",
    "💡",
    "🗂️",
];

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
        workspaceCreateError.value =
            e?.response?.data?.error ?? "Failed to create workspace";
    } finally {
        isSubmittingWorkspace.value = false;
    }
}

// ── Folder creation ───────────────────────────────────────────────────────
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
        folderCreateError.value = "Create a workspace first";
        return;
    }
    isSubmittingFolder.value = true;
    folderCreateError.value = "";
    try {
        await sidebar.createFolder(name, newFolderWsId.value);
        cancelFolderCreate();
    } catch (e: any) {
        folderCreateError.value =
            e?.response?.data?.error ?? "Failed to create folder";
    } finally {
        isSubmittingFolder.value = false;
    }
}
</script>

<template>
    <aside
        class="w-64 bg-ink-100 dark:bg-ink-950 flex flex-col shrink-0 border-r border-ink-200 dark:border-ink-800 overflow-hidden"
    >
        <!-- ── Logo ──────────────────────────────────────────────── -->
        <div
            class="px-4 pt-5 pb-4 border-b border-ink-200 dark:border-ink-800 shrink-0"
        >
            <RouterLink to="/app/notes" class="flex items-center gap-2.5">
                <div
                    class="w-7 h-7 bg-amber-500 rounded-lg flex items-center justify-center shrink-0"
                >
                    <BookOpen :size="14" class="text-white" />
                </div>
                <span
                    class="font-display text-base font-bold text-ink-900 dark:text-ink-50 tracking-tight"
                >
                    Caddo Notes
                </span>
            </RouterLink>
        </div>

        <!-- ── Scrollable body ─────────────────────────────────────── -->
        <div class="flex-1 overflow-y-auto py-2">
            <!-- ── Quick nav ──────────────────────────────────────────── -->
            <div class="px-2 space-y-0.5 pb-2">
                <RouterLink
                    to="/app/notes"
                    class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors"
                    :class="
                        isActive('/app/notes')
                            ? 'bg-white dark:bg-ink-800 text-ink-900 dark:text-ink-100 font-medium shadow-sm'
                            : 'text-ink-600 dark:text-ink-400 hover:bg-white/70 dark:hover:bg-ink-800/60 hover:text-ink-900 dark:hover:text-ink-200'
                    "
                >
                    <StickyNote :size="14" class="shrink-0" />
                    My Notes
                </RouterLink>

                <RouterLink
                    to="/app/library"
                    class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors"
                    :class="
                        isActive('/app/library')
                            ? 'bg-white dark:bg-ink-800 text-ink-900 dark:text-ink-100 font-medium shadow-sm'
                            : 'text-ink-600 dark:text-ink-400 hover:bg-white/70 dark:hover:bg-ink-800/60 hover:text-ink-900 dark:hover:text-ink-200'
                    "
                >
                    <svg
                        class="shrink-0 w-[14px] h-[14px]"
                        viewBox="0 0 24 24"
                        fill="none"
                        stroke="currentColor"
                        stroke-width="2"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                    >
                        <rect x="3" y="3" width="7" height="7" />
                        <rect x="14" y="3" width="7" height="7" />
                        <rect x="14" y="14" width="7" height="7" />
                        <rect x="3" y="14" width="7" height="7" />
                    </svg>
                    All Notes
                </RouterLink>

                <RouterLink
                    to="/app/notes/new"
                    class="flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors"
                    :class="
                        isActive('/app/notes/new')
                            ? 'bg-white dark:bg-ink-800 text-ink-900 dark:text-ink-100 font-medium shadow-sm'
                            : 'text-ink-600 dark:text-ink-400 hover:bg-white/70 dark:hover:bg-ink-800/60 hover:text-ink-900 dark:hover:text-ink-200'
                    "
                >
                    <PenLine :size="14" class="shrink-0" />
                    New Note
                </RouterLink>
            </div>

            <!-- ════ BLOCK: WORKSPACES ════════════════════════════════════ -->
            <div
                class="mx-2 mt-1 mb-1 rounded-xl bg-white/60 dark:bg-ink-900/40 border border-ink-200/60 dark:border-ink-800/60 overflow-hidden"
            >
                <!-- Section header -->
                <div class="flex items-center justify-between px-3 py-2.5">
                    <button
                        @click="toggle_section('workspaces')"
                        class="flex items-center gap-1.5 flex-1 text-left hover:opacity-80 transition-opacity"
                    >
                        <span
                            class="text-xs font-bold text-ink-700 dark:text-ink-300 font-ui tracking-wide"
                            >Workspaces</span
                        >
                        <span
                            v-if="sidebar.workspaces.length"
                            class="text-[10px] font-ui text-ink-400 dark:text-ink-600 tabular-nums"
                            >{{ sidebar.workspaces.length }}</span
                        >
                        <ChevronRight
                            :size="12"
                            class="text-ink-400 dark:text-ink-600 transition-transform duration-200"
                            :class="collapsed.workspaces ? '' : 'rotate-90'"
                        />
                    </button>
                    <button
                        v-if="!isCreatingWorkspace"
                        @click="openWorkspaceCreate"
                        class="p-1 rounded-md text-ink-400 dark:text-ink-600 hover:text-ink-700 dark:hover:text-ink-300 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                        title="New workspace"
                    >
                        <Plus :size="12" />
                    </button>
                    <button
                        v-else
                        @click="cancelWorkspaceCreate"
                        class="p-1 rounded-md text-ink-400 dark:text-ink-600 hover:text-red-500 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                        title="Cancel"
                    >
                        <X :size="12" />
                    </button>
                </div>

                <!-- Workspace create form -->
                <Transition
                    enter-active-class="transition-all duration-200 ease-out"
                    enter-from-class="opacity-0 -translate-y-1"
                    enter-to-class="opacity-100 translate-y-0"
                    leave-active-class="transition-all duration-150 ease-in"
                    leave-from-class="opacity-100 translate-y-0"
                    leave-to-class="opacity-0 -translate-y-1"
                >
                    <div v-if="isCreatingWorkspace" class="px-3 pb-3">
                        <div
                            class="bg-white dark:bg-ink-900 rounded-xl border border-ink-200 dark:border-ink-700 overflow-hidden shadow-sm"
                        >
                            <!-- Emoji + name row -->
                            <div
                                class="flex items-center gap-2 px-3 py-2.5 border-b border-ink-100 dark:border-ink-800"
                            >
                                <span
                                    class="text-base leading-none select-none"
                                    >{{ newWorkspaceIcon }}</span
                                >
                                <input
                                    ref="workspaceNameInput"
                                    v-model="newWorkspaceName"
                                    @keydown.enter="submitWorkspace"
                                    @keydown.escape="cancelWorkspaceCreate"
                                    type="text"
                                    placeholder="Workspace name…"
                                    maxlength="80"
                                    class="flex-1 text-xs font-ui bg-transparent outline-none text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600"
                                />
                            </div>
                            <!-- Emoji picker -->
                            <div
                                class="px-3 py-2.5 border-b border-ink-100 dark:border-ink-800"
                            >
                                <p
                                    class="text-[10px] font-ui font-medium text-ink-400 dark:text-ink-600 uppercase tracking-wider mb-1.5"
                                >
                                    Icon
                                </p>
                                <div class="flex flex-wrap gap-1.5">
                                    <button
                                        v-for="emoji in WORKSPACE_EMOJIS"
                                        :key="emoji"
                                        @click="newWorkspaceIcon = emoji"
                                        class="text-base w-7 h-7 flex items-center justify-center rounded-lg transition-all hover:scale-110"
                                        :class="
                                            newWorkspaceIcon === emoji
                                                ? 'bg-ink-100 dark:bg-ink-800 ring-2 ring-amber-400'
                                                : 'hover:bg-ink-100 dark:hover:bg-ink-800'
                                        "
                                    >
                                        {{ emoji }}
                                    </button>
                                </div>
                            </div>
                            <!-- Error -->
                            <p
                                v-if="workspaceCreateError"
                                class="px-3 py-1.5 text-[10px] text-red-500 font-ui"
                            >
                                {{ workspaceCreateError }}
                            </p>
                            <!-- Actions -->
                            <div class="flex items-center gap-2 px-3 py-2">
                                <button
                                    @click="submitWorkspace"
                                    :disabled="
                                        !newWorkspaceName.trim() ||
                                        isSubmittingWorkspace
                                    "
                                    class="flex items-center gap-1.5 px-3 py-1.5 bg-ink-900 dark:bg-amber-500 text-white dark:text-ink-950 rounded-lg text-xs font-ui font-semibold disabled:opacity-40 hover:bg-ink-700 dark:hover:bg-amber-600 transition-colors"
                                >
                                    <Loader2
                                        v-if="isSubmittingWorkspace"
                                        :size="10"
                                        class="animate-spin"
                                    />
                                    <Check v-else :size="10" />
                                    Create
                                </button>
                                <button
                                    @click="cancelWorkspaceCreate"
                                    class="px-3 py-1.5 text-xs font-ui text-ink-400 dark:text-ink-600 hover:text-ink-700 dark:hover:text-ink-300 transition-colors"
                                >
                                    Cancel
                                </button>
                            </div>
                        </div>
                    </div>
                </Transition>

                <!-- Workspace items -->
                <div v-if="!collapsed.workspaces" class="pb-1.5">
                    <button
                        v-for="ws in sidebar.workspaces"
                        :key="ws._id"
                        class="w-full flex items-center gap-2.5 px-3 py-1.5 text-sm text-ink-700 dark:text-ink-300 hover:bg-white/70 dark:hover:bg-ink-800/60 transition-colors text-left"
                    >
                        <span
                            class="text-base leading-none shrink-0 select-none"
                            >{{ ws.icon || "🏠" }}</span
                        >
                        <span class="truncate font-ui text-sm">{{
                            ws.name
                        }}</span>
                    </button>
                    <p
                        v-if="
                            !sidebar.loading &&
                            sidebar.workspaces.length === 0 &&
                            !isCreatingWorkspace
                        "
                        class="px-3 py-2 text-xs text-ink-400 dark:text-ink-600 font-ui"
                    >
                        No workspaces yet — click
                        <span class="font-semibold">+</span> to create one
                    </p>
                </div>
            </div>

            <!-- ════ BLOCK: FOLDERS ═══════════════════════════════════════ -->
            <div
                class="mx-2 mt-1.5 mb-1 rounded-xl bg-white/60 dark:bg-ink-900/40 border border-ink-200/60 dark:border-ink-800/60 overflow-hidden"
            >
                <!-- Section header -->
                <div class="flex items-center justify-between px-3 py-2.5">
                    <button
                        @click="toggle_section('folders')"
                        class="flex items-center gap-1.5 flex-1 text-left hover:opacity-80 transition-opacity"
                    >
                        <span
                            class="text-xs font-bold text-ink-700 dark:text-ink-300 font-ui tracking-wide"
                            >Folders</span
                        >
                        <span
                            v-if="
                                sidebar.folders.filter((f) => !f.isDeleted)
                                    .length
                            "
                            class="text-[10px] font-ui text-ink-400 dark:text-ink-600 tabular-nums"
                            >{{
                                sidebar.folders.filter((f) => !f.isDeleted)
                                    .length
                            }}</span
                        >
                        <ChevronRight
                            :size="12"
                            class="text-ink-400 dark:text-ink-600 transition-transform duration-200"
                            :class="collapsed.folders ? '' : 'rotate-90'"
                        />
                    </button>
                    <button
                        v-if="!isCreatingFolder"
                        @click="openFolderCreate"
                        class="p-1 rounded-md text-ink-400 dark:text-ink-600 hover:text-ink-700 dark:hover:text-ink-300 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                        title="New folder"
                    >
                        <Plus :size="12" />
                    </button>
                    <button
                        v-else
                        @click="cancelFolderCreate"
                        class="p-1 rounded-md text-ink-400 dark:text-ink-600 hover:text-red-500 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                        title="Cancel"
                    >
                        <X :size="12" />
                    </button>
                </div>

                <!-- Folder create form -->
                <Transition
                    enter-active-class="transition-all duration-200 ease-out"
                    enter-from-class="opacity-0 -translate-y-1"
                    enter-to-class="opacity-100 translate-y-0"
                    leave-active-class="transition-all duration-150 ease-in"
                    leave-from-class="opacity-100 translate-y-0"
                    leave-to-class="opacity-0 -translate-y-1"
                >
                    <div v-if="isCreatingFolder" class="px-3 pb-3">
                        <!-- No workspace warning -->
                        <div
                            v-if="sidebar.workspaces.length === 0"
                            class="bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800 rounded-xl px-3 py-2.5"
                        >
                            <p
                                class="text-xs text-amber-700 dark:text-amber-400 font-ui"
                            >
                                Create a workspace first before adding folders.
                            </p>
                        </div>
                        <div
                            v-else
                            class="bg-white dark:bg-ink-900 rounded-xl border border-ink-200 dark:border-ink-700 overflow-hidden shadow-sm"
                        >
                            <!-- Folder name -->
                            <div
                                class="flex items-center gap-2 px-3 py-2.5 border-b border-ink-100 dark:border-ink-800"
                            >
                                <Folder
                                    :size="12"
                                    class="text-ink-400 dark:text-ink-600 shrink-0"
                                />
                                <input
                                    ref="folderNameInput"
                                    v-model="newFolderName"
                                    @keydown.enter="submitFolder"
                                    @keydown.escape="cancelFolderCreate"
                                    type="text"
                                    placeholder="Folder name…"
                                    maxlength="100"
                                    class="flex-1 text-xs font-ui bg-transparent outline-none text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600"
                                />
                            </div>
                            <!-- Workspace selector (only when multiple workspaces) -->
                            <div
                                v-if="sidebar.workspaces.length > 1"
                                class="px-3 py-2 border-b border-ink-100 dark:border-ink-800"
                            >
                                <p
                                    class="text-[10px] font-ui font-medium text-ink-400 dark:text-ink-600 uppercase tracking-wider mb-1.5"
                                >
                                    Workspace
                                </p>
                                <select
                                    v-model="newFolderWsId"
                                    class="w-full text-xs font-ui bg-ink-50 dark:bg-ink-800 border border-ink-200 dark:border-ink-700 rounded-lg px-2 py-1.5 text-ink-700 dark:text-ink-300 outline-none focus:ring-2 focus:ring-amber-400"
                                >
                                    <option
                                        v-for="ws in sidebar.workspaces"
                                        :key="ws._id"
                                        :value="ws._id"
                                    >
                                        {{ ws.icon || "🏠" }} {{ ws.name }}
                                    </option>
                                </select>
                            </div>
                            <!-- Error -->
                            <p
                                v-if="folderCreateError"
                                class="px-3 py-1.5 text-[10px] text-red-500 font-ui"
                            >
                                {{ folderCreateError }}
                            </p>
                            <!-- Actions -->
                            <div class="flex items-center gap-2 px-3 py-2">
                                <button
                                    @click="submitFolder"
                                    :disabled="
                                        !newFolderName.trim() ||
                                        isSubmittingFolder
                                    "
                                    class="flex items-center gap-1.5 px-3 py-1.5 bg-ink-900 dark:bg-amber-500 text-white dark:text-ink-950 rounded-lg text-xs font-ui font-semibold disabled:opacity-40 hover:bg-ink-700 dark:hover:bg-amber-600 transition-colors"
                                >
                                    <Loader2
                                        v-if="isSubmittingFolder"
                                        :size="10"
                                        class="animate-spin"
                                    />
                                    <Check v-else :size="10" />
                                    Create
                                </button>
                                <button
                                    @click="cancelFolderCreate"
                                    class="px-3 py-1.5 text-xs font-ui text-ink-400 dark:text-ink-600 hover:text-ink-700 dark:hover:text-ink-300 transition-colors"
                                >
                                    Cancel
                                </button>
                            </div>
                        </div>
                    </div>
                </Transition>

                <!-- Folder items -->
                <div v-if="!collapsed.folders" class="pb-1.5">
                    <button
                        v-for="folder in sidebar.folders.filter(
                            (f) => !f.isDeleted,
                        )"
                        :key="folder._id"
                        class="w-full flex items-center gap-2 px-3 py-1.5 text-sm text-ink-600 dark:text-ink-400 hover:bg-white/70 dark:hover:bg-ink-800/60 hover:text-ink-900 dark:hover:text-ink-200 transition-colors text-left"
                    >
                        <span
                            class="text-ink-300 dark:text-ink-700 text-xs font-mono shrink-0 w-2.5 text-center"
                            >–</span
                        >
                        <Folder
                            :size="13"
                            class="text-ink-400 dark:text-ink-600 shrink-0"
                        />
                        <span class="truncate font-ui text-sm">{{
                            folder.name
                        }}</span>
                    </button>
                    <p
                        v-if="
                            !sidebar.loading &&
                            sidebar.folders.filter((f) => !f.isDeleted)
                                .length === 0 &&
                            !isCreatingFolder
                        "
                        class="px-3 py-2 text-xs text-ink-400 dark:text-ink-600 font-ui"
                    >
                        No folders yet — click
                        <span class="font-semibold">+</span> to create one
                    </p>
                </div>
            </div>

            <!-- ════ BLOCK: TAGS ══════════════════════════════════════════ -->
            <div
                class="mx-2 mt-1.5 rounded-xl bg-white/60 dark:bg-ink-900/40 border border-ink-200/60 dark:border-ink-800/60 overflow-hidden"
            >
                <!-- Section header -->
                <div class="flex items-center justify-between px-3 py-2.5">
                    <button
                        @click="toggle_section('tags')"
                        class="flex items-center gap-1.5 flex-1 text-left hover:opacity-80 transition-opacity"
                    >
                        <span
                            class="text-xs font-bold text-ink-700 dark:text-ink-300 font-ui tracking-wide"
                            >Tags</span
                        >
                        <span
                            v-if="sidebar.tags.length"
                            class="text-[10px] font-ui text-ink-400 dark:text-ink-600 tabular-nums"
                            >{{ sidebar.tags.length }}</span
                        >
                        <ChevronRight
                            :size="12"
                            class="text-ink-400 dark:text-ink-600 transition-transform duration-200"
                            :class="collapsed.tags ? '' : 'rotate-90'"
                        />
                    </button>

                    <!-- + Create tag button -->
                    <button
                        v-if="!isCreatingTag"
                        @click="openTagCreate"
                        class="p-1 rounded-md text-ink-400 dark:text-ink-600 hover:text-ink-700 dark:hover:text-ink-300 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                        title="New tag"
                    >
                        <Plus :size="12" />
                    </button>
                    <button
                        v-else
                        @click="cancelTagCreate"
                        class="p-1 rounded-md text-ink-400 dark:text-ink-600 hover:text-red-500 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                        title="Cancel"
                    >
                        <X :size="12" />
                    </button>
                </div>

                <!-- ── Tag create form ────────────────────────────────────── -->
                <Transition
                    enter-active-class="transition-all duration-200 ease-out"
                    enter-from-class="opacity-0 -translate-y-1"
                    enter-to-class="opacity-100 translate-y-0"
                    leave-active-class="transition-all duration-150 ease-in"
                    leave-from-class="opacity-100 translate-y-0"
                    leave-to-class="opacity-0 -translate-y-1"
                >
                    <div v-if="isCreatingTag" class="px-3 pb-3">
                        <div
                            class="bg-white dark:bg-ink-900 rounded-xl border border-ink-200 dark:border-ink-700 overflow-hidden shadow-sm"
                        >
                            <!-- Name + color swatch row -->
                            <div
                                class="flex items-center gap-2 px-3 py-2.5 border-b border-ink-100 dark:border-ink-800"
                            >
                                <!-- Color preview dot (click to toggle picker) -->
                                <button
                                    @click="showColorGrid = !showColorGrid"
                                    class="w-4 h-4 rounded-full shrink-0 ring-1 ring-ink-200 dark:ring-ink-700 ring-offset-1 transition-transform hover:scale-110"
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
                                    class="flex-1 text-xs font-ui bg-transparent outline-none text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600"
                                />
                            </div>

                            <!-- Color picker grid -->
                            <Transition
                                enter-active-class="transition-all duration-150 ease-out"
                                enter-from-class="opacity-0 scale-95"
                                enter-to-class="opacity-100 scale-100"
                                leave-active-class="transition-all duration-100 ease-in"
                                leave-from-class="opacity-100 scale-100"
                                leave-to-class="opacity-0 scale-95"
                            >
                                <div
                                    v-if="showColorGrid"
                                    class="px-3 py-2.5 border-b border-ink-100 dark:border-ink-800"
                                >
                                    <p
                                        class="text-[10px] font-ui font-medium text-ink-400 dark:text-ink-600 uppercase tracking-wider mb-2"
                                    >
                                        Color
                                    </p>
                                    <div class="grid grid-cols-8 gap-1.5">
                                        <button
                                            v-for="color in TAG_COLORS"
                                            :key="color"
                                            @click="
                                                newTagColor = color;
                                                showColorGrid = false;
                                            "
                                            class="w-5 h-5 rounded-full transition-all hover:scale-125 active:scale-95 focus:outline-none"
                                            :style="{ backgroundColor: color }"
                                            :class="
                                                newTagColor === color
                                                    ? 'ring-2 ring-offset-1 ring-ink-400 dark:ring-ink-300 scale-110'
                                                    : 'ring-1 ring-ink-100 dark:ring-ink-800'
                                            "
                                        />
                                    </div>
                                </div>
                            </Transition>

                            <!-- Error message -->
                            <p
                                v-if="tagCreateError"
                                class="px-3 py-1.5 text-[10px] text-red-500 font-ui"
                            >
                                {{ tagCreateError }}
                            </p>

                            <!-- Actions row -->
                            <div class="flex items-center gap-2 px-3 py-2">
                                <button
                                    @click="submitTag"
                                    :disabled="
                                        !newTagName.trim() || isSubmittingTag
                                    "
                                    class="flex items-center gap-1.5 px-3 py-1.5 bg-ink-900 dark:bg-amber-500 text-white dark:text-ink-950 rounded-lg text-xs font-ui font-semibold disabled:opacity-40 hover:bg-ink-700 dark:hover:bg-amber-600 transition-colors"
                                >
                                    <Loader2
                                        v-if="isSubmittingTag"
                                        :size="10"
                                        class="animate-spin"
                                    />
                                    <Check v-else :size="10" />
                                    Create
                                </button>
                                <button
                                    @click="cancelTagCreate"
                                    class="px-3 py-1.5 text-xs font-ui text-ink-400 dark:text-ink-600 hover:text-ink-700 dark:hover:text-ink-300 transition-colors"
                                >
                                    Cancel
                                </button>
                            </div>
                        </div>
                    </div>
                </Transition>

                <!-- ── Tag list ───────────────────────────────────────────── -->
                <div v-if="!collapsed.tags" class="px-3 pb-3">
                    <!-- Tags wrap -->
                    <div
                        v-if="sidebar.tags.length"
                        class="flex flex-wrap gap-1.5 mt-1"
                    >
                        <span
                            v-for="tag in sidebar.tags"
                            :key="tag._id"
                            class="group/tag inline-flex items-center gap-1 pl-2 pr-1 py-1 rounded-full text-xs font-ui cursor-pointer border transition-all"
                            :style="{
                                backgroundColor: tag.color + '18',
                                borderColor: tag.color + '40',
                                color: tag.color,
                            }"
                        >
                            <span
                                class="w-1.5 h-1.5 rounded-full shrink-0"
                                :style="{ backgroundColor: tag.color }"
                            />
                            <span>{{ tag.name }}</span>
                            <!-- Delete on hover -->
                            <button
                                @click="deleteTag(tag._id, $event)"
                                class="ml-0.5 w-3.5 h-3.5 rounded-full flex items-center justify-center opacity-0 group-hover/tag:opacity-100 hover:bg-black/10 dark:hover:bg-white/10 transition-all shrink-0"
                                title="Remove tag"
                            >
                                <X :size="8" />
                            </button>
                        </span>
                    </div>

                    <!-- Empty state -->
                    <p
                        v-else-if="!sidebar.loading && !isCreatingTag"
                        class="text-xs text-ink-400 dark:text-ink-600 font-ui py-1"
                    >
                        No tags yet — click
                        <span class="font-semibold">+</span> to create one
                    </p>
                </div>
            </div>

            <!-- ── Trash ──────────────────────────────────────────────── -->
            <div class="px-2 mt-3 pb-2">
                <div
                    class="mx-1 border-t border-ink-200 dark:border-ink-800 mb-2"
                />
                <RouterLink
                    to="/app/trash"
                    class="flex items-center gap-2.5 px-3 py-1.5 rounded-lg text-sm transition-colors"
                    :class="
                        isActive('/app/trash')
                            ? 'bg-white dark:bg-ink-800 text-ink-700 dark:text-ink-300 shadow-sm'
                            : 'text-ink-500 dark:text-ink-600 hover:bg-white/70 dark:hover:bg-ink-800/60 hover:text-ink-700 dark:hover:text-ink-300'
                    "
                >
                    <Trash2 :size="13" class="shrink-0" />
                    Trash
                </RouterLink>
            </div>
        </div>

        <!-- ── Bottom ─────────────────────────────────────────────── -->
        <div class="shrink-0 border-t border-ink-200 dark:border-ink-800 px-2 py-2 space-y-0.5">
            <RouterLink
                to="/app/profile"
                class="flex items-center gap-2.5 px-3 py-1.5 rounded-lg hover:bg-white/70 dark:hover:bg-ink-800/60 transition-colors group"
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
                    <span v-else>{{
                        auth.user?.name?.charAt(0).toUpperCase()
                    }}</span>
                </div>
                <span
                    class="text-sm text-ink-700 dark:text-ink-300 group-hover:text-ink-900 dark:group-hover:text-ink-100 truncate font-ui flex-1"
                >
                    {{ auth.user?.name }}
                </span>
            </RouterLink>
            <RouterLink
                to="/app/settings"
                class="flex items-center gap-2.5 px-3 py-1.5 rounded-lg text-sm transition-colors"
                :class="
                    isActive('/app/settings')
                        ? 'bg-white dark:bg-ink-800 text-ink-900 dark:text-ink-100 shadow-sm'
                        : 'text-ink-500 dark:text-ink-500 hover:bg-white/70 dark:hover:bg-ink-800/60 hover:text-ink-800 dark:hover:text-ink-200'
                "
            >
                <Settings :size="14" class="shrink-0" />
                Settings
            </RouterLink>

            <button
                @click="toggle"
                class="w-full flex items-center gap-2.5 px-3 py-1.5 rounded-lg text-sm text-ink-500 dark:text-ink-500 hover:bg-white/70 dark:hover:bg-ink-800/60 hover:text-ink-800 dark:hover:text-ink-200 transition-colors"
            >
                <Sun v-if="theme === 'dark'" :size="14" class="shrink-0" />
                <Moon v-else :size="14" class="shrink-0" />
                {{ theme === "dark" ? "Light mode" : "Dark mode" }}
            </button>
            <button
                @click="handleLogout"
                class="w-full flex items-center gap-2.5 px-3 py-1.5 rounded-lg text-sm text-ink-400 dark:text-ink-600 hover:bg-red-50 dark:hover:bg-red-950/20 hover:text-red-600 dark:hover:text-red-400 transition-colors"
            >
                <LogOut :size="14" class="shrink-0" />
                Sign out
            </button>
        </div>
    </aside>
</template>
