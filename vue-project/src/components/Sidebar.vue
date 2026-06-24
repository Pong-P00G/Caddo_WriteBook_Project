<script setup lang="ts">
import { ref } from "vue";
import { RouterLink, useRoute } from "vue-router";
import {
    Home,
    Briefcase,
    Folder,
    FolderOpen,
    Trash2,
    ChevronDown,
    ChevronRight,
} from "lucide-vue-next";

const route = useRoute();

function isActive(path: string) {
    return route.path === path;
}

// ── Section collapse state ─────────────────────────────────────────────────
const collapsed = ref({ workspaces: false, folders: false, tags: false });
function toggle_section(key: keyof typeof collapsed.value) {
    collapsed.value[key] = !collapsed.value[key];
}

// ── Static data per prompt spec ────────────────────────────────────────────
const workspaces = [
    { id: "personal", name: "Personal", icon: "home" },
    { id: "work", name: "Work", icon: "briefcase" },
];

const folders = [
    { id: "research", name: "Research", expanded: false },
    { id: "design-system", name: "Design System", expanded: false },
    { id: "roadmap", name: "Roadmap", expanded: false },
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
        <!-- ── Scrollable body ─────────────────────────────────────── -->
        <div class="flex-1 overflow-y-auto py-4">
            <!-- ════ BLOCK: WORKSPACES ════════════════════════════════════ -->
            <div class="px-4">
                <p
                    class="text-[11px] font-semibold text-[#999] uppercase tracking-wider mb-2 px-2"
                >
                    Workspaces
                </p>
                <div class="space-y-0.5">
                    <button
                        class="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors text-left"
                        :class="
                            isActive('/app/notes')
                                ? 'bg-white text-[#1a1a1a] font-medium shadow-sm'
                                : 'text-[#666] hover:bg-white/70 hover:text-[#1a1a1a]'
                        "
                    >
                        <Home :size="16" class="shrink-0 text-[#999]" />
                        Personal
                    </button>
                    <button
                        class="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors text-left"
                        :class="
                            isActive('/app/work')
                                ? 'bg-white text-[#1a1a1a] font-medium shadow-sm'
                                : 'text-[#666] hover:bg-white/70 hover:text-[#1a1a1a]'
                        "
                    >
                        <Briefcase :size="16" class="shrink-0 text-[#999]" />
                        Work
                    </button>
                </div>
            </div>

            <!-- ════ BLOCK: FOLDERS ═══════════════════════════════════════ -->
            <div class="px-4 mt-6">
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
                        <button
                            @click="toggle_folder(folder.id)"
                            class="w-full flex items-center gap-3 px-3 py-2 text-sm text-[#666] hover:text-[#1a1a1a] text-left"
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
                        </button>
                    </div>
                </div>
            </div>

            <!-- ════ BLOCK: TAGS ══════════════════════════════════════════ -->
            <div class="px-4 mt-6">
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
            <div class="px-4 mt-6">
                <div class="border-t border-[#e0e0e0] mb-4" />
                <button
                    class="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-[#999] hover:bg-white/70 hover:text-[#666] transition-colors text-left"
                >
                    <Trash2 :size="15" class="shrink-0" />
                    Trash
                </button>
            </div>
        </div>
    </aside>
</template>
