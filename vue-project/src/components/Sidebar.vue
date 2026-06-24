<script setup lang="ts">
import { ref } from "vue";
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
} from "lucide-vue-next";
import { useAuthStore } from "../store/auth";
import { useDarkMode } from "../composable/Darkmode";

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const { theme, toggle } = useDarkMode();

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

// ── Static data per prompt spec ────────────────────────────────────────────
const workspaces = [
    { id: "personal", name: "Personal", icon: "home", path: "/app/notes" },
    { id: "work", name: "Work", icon: "briefcase", path: "/app/work" },
];

const folders = [
    { id: "research", name: "Research", expanded: false, path: "/app/folders/research" },
    { id: "design-system", name: "Design System", expanded: false, path: "/app/folders/design-system" },
    { id: "roadmap", name: "Roadmap", expanded: false, path: "/app/folders/roadmap" },
];

const tags = ["#frontend", "#ux", "#priority"];

function toggle_folder(id: string) {
    const folder = folders.find((f) => f.id === id);
    if (folder) folder.expanded = !folder.expanded;
}
</script>

<template>
    <aside
        class="w-[280px] bg-[#f7f7f7] flex flex-col shrink-0 overflow-hidden h-full"
    >
        <!-- ── Logo ──────────────────────────────────────────────── -->
        <div class="px-4 py-4 border-b border-[#e0e0e0] shrink-0">
            <RouterLink to="/app/notes" class="flex items-center gap-2.5">
                <div
                    class="w-7 h-7 bg-amber-500 rounded-lg flex items-center justify-center shrink-0"
                >
                    <BookOpen :size="14" class="text-white" />
                </div>
                <span class="font-semibold text-sm text-[#1a1a1a] tracking-tight">
                    Caddo Notes
                </span>
            </RouterLink>
        </div>

        <!-- ── Scrollable body ─────────────────────────────────────── -->
        <div class="flex-1 overflow-y-auto py-3">
            <!-- ════ BLOCK: WORKSPACES ════════════════════════════════════ -->
            <div class="px-4">
                <p
                    class="text-[11px] font-semibold text-[#999] uppercase tracking-wider mb-2 px-2"
                >
                    Workspaces
                </p>
                <div class="space-y-0.5">
                    <RouterLink
                        v-for="ws in workspaces"
                        :key="ws.id"
                        :to="ws.path"
                        class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors"
                        :class="
                            isActive(ws.path)
                                ? 'bg-white text-[#1a1a1a] font-medium shadow-sm'
                                : 'text-[#666] hover:bg-white/70 hover:text-[#1a1a1a]'
                        "
                    >
                        <Home v-if="ws.icon === 'home'" :size="16" class="shrink-0 text-[#999]" />
                        <Briefcase v-else :size="16" class="shrink-0 text-[#999]" />
                        {{ ws.name }}
                    </RouterLink>
                </div>
            </div>

            <!-- ════ BLOCK: FOLDERS ═══════════════════════════════════════ -->
            <div class="px-4 mt-5">
                <p
                    class="text-[11px] font-semibold text-[#999] uppercase tracking-wider mb-2 px-2"
                >
                    Folders
                </p>
                <div class="space-y-0.5">
                    <div
                        v-for="folder in folders"
                        :key="folder.id"
                        class="rounded-lg hover:bg-white/70 transition-colors"
                    >
                        <RouterLink
                            :to="folder.path"
                            class="w-full flex items-center gap-3 px-3 py-2 text-sm text-[#666] hover:text-[#1a1a1a]"
                        >
                            <ChevronDown
                                v-if="folder.expanded"
                                :size="12"
                                class="shrink-0 text-[#bbb]"
                            />
                            <ChevronRight
                                v-else
                                :size="12"
                                class="shrink-0 text-[#bbb]"
                            />
                            <FolderOpen
                                v-if="folder.expanded"
                                :size="15"
                                class="shrink-0 text-[#999]"
                            />
                            <Folder
                                v-else
                                :size="15"
                                class="shrink-0 text-[#999]"
                            />
                            <span>{{ folder.name }}</span>
                        </RouterLink>
                    </div>
                </div>
            </div>

            <!-- ════ BLOCK: TAGS ══════════════════════════════════════════ -->
            <div class="px-4 mt-5">
                <p
                    class="text-[11px] font-semibold text-[#999] uppercase tracking-wider mb-2 px-2"
                >
                    Tags
                </p>
                <div class="flex flex-wrap gap-2 px-2 mt-1">
                    <span
                        v-for="tag in tags"
                        :key="tag"
                        class="inline-flex items-center px-2.5 py-1 rounded-full text-xs bg-white border border-[#e0e0e0] text-[#666] hover:border-[#ccc] hover:text-[#333] transition-colors cursor-pointer"
                    >
                        {{ tag }}
                    </span>
                </div>
            </div>

            <!-- ── Divider & Trash ───────────────────────────────────── -->
            <div class="px-4 mt-5">
                <div class="border-t border-[#e0e0e0] mb-4" />
                <RouterLink
                    to="/app/trash"
                    class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-[#999] hover:bg-white/70 hover:text-[#666] transition-colors"
                    :class="isActive('/app/trash') ? 'bg-white shadow-sm text-[#666]' : ''"
                >
                    <Trash2 :size="15" class="shrink-0" />
                    Trash
                </RouterLink>
            </div>
        </div>

        <!-- ── Bottom ─────────────────────────────────────────────── -->
        <div class="shrink-0 border-t border-[#e0e0e0] px-2 py-3 space-y-0.5">
            <RouterLink
                to="/app/profile"
                class="flex items-center gap-2.5 px-3 py-1.5 rounded-lg hover:bg-white/70 transition-colors group"
                :class="isActive('/app/profile') ? 'bg-white shadow-sm' : ''"
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
                    <span v-else>{{ auth.user?.name?.charAt(0).toUpperCase() }}</span>
                </div>
                <span class="text-sm text-[#666] group-hover:text-[#1a1a1a] truncate font-medium flex-1">
                    {{ auth.user?.name }}
                </span>
            </RouterLink>
            <RouterLink
                to="/app/settings"
                class="flex items-center gap-2.5 px-3 py-1.5 rounded-lg text-sm transition-colors"
                :class="
                    isActive('/app/settings')
                        ? 'bg-white text-[#1a1a1a] shadow-sm'
                        : 'text-[#999] hover:bg-white/70 hover:text-[#666]'
                "
            >
                <Settings :size="14" class="shrink-0" />
                Settings
            </RouterLink>

            <button
                @click="toggle"
                class="w-full flex items-center gap-2.5 px-3 py-1.5 rounded-lg text-sm text-[#999] hover:bg-white/70 hover:text-[#666] transition-colors"
            >
                <Sun v-if="theme === 'dark'" :size="14" class="shrink-0" />
                <Moon v-else :size="14" class="shrink-0" />
                {{ theme === "dark" ? "Light mode" : "Dark mode" }}
            </button>
            <button
                @click="handleLogout"
                class="w-full flex items-center gap-2.5 px-3 py-1.5 rounded-lg text-sm text-[#999] hover:bg-red-50 hover:text-red-600 transition-colors"
            >
                <LogOut :size="14" class="shrink-0" />
                Sign out
            </button>
        </div>
    </aside>
</template>