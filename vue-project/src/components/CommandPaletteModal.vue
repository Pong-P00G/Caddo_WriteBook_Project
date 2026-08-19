<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted, nextTick } from "vue";
import { useRouter } from "vue-router";
import { useNotesStore } from "@/store/notes";
import {
    Search,
    FileText,
    Plus,
    Sparkles,
    Sun,
    Moon,
    Trash2,
    Settings,
    User,
    ArrowRight,
    Folder,
    Tag,
    BookOpen,
    X,
} from "lucide-vue-next";

const props = defineProps<{
    isOpen: boolean;
}>();

const emit = defineEmits<{
    (e: "close"): void;
    (e: "openTemplates"): void;
}>();

const router = useRouter();
const store = useNotesStore();

const query = ref("");
const selectedIndex = ref(0);
const inputRef = ref<HTMLInputElement | null>(null);

const isDark = ref(document.documentElement.classList.contains("dark"));

function toggleTheme() {
    isDark.value = !isDark.value;
    if (isDark.value) {
        document.documentElement.classList.add("dark");
        localStorage.setItem("theme", "dark");
    } else {
        document.documentElement.classList.remove("dark");
        localStorage.setItem("theme", "light");
    }
}

interface CommandItem {
    id: string;
    category: "Actions" | "Notes" | "Navigation";
    title: string;
    subtitle?: string;
    icon: any;
    action: () => void;
}

const filteredCommands = computed<CommandItem[]>(() => {
    const q = query.value.trim().toLowerCase();
    const items: CommandItem[] = [];

    // System Actions
    const defaultActions: CommandItem[] = [
        {
            id: "new-note",
            category: "Actions",
            title: "Create New Note",
            subtitle: "Start writing a blank document",
            icon: Plus,
            action: () => router.push("/app/notes/new"),
        },
        {
            id: "templates",
            category: "Actions",
            title: "Starter Templates Gallery",
            subtitle: "Choose from pre-made document structures",
            icon: Sparkles,
            action: () => emit("openTemplates"),
        },
        {
            id: "toggle-theme",
            category: "Actions",
            title: `Switch to ${isDark.value ? 'Light' : 'Dark'} Mode`,
            subtitle: "Toggle application appearance",
            icon: isDark.value ? Sun : Moon,
            action: () => toggleTheme(),
        },
        {
            id: "nav-all-notes",
            category: "Navigation",
            title: "All Notes & Library",
            subtitle: "Browse all your notes",
            icon: BookOpen,
            action: () => router.push("/app/notes"),
        },
        {
            id: "nav-settings",
            category: "Navigation",
            title: "Settings & Preferences",
            subtitle: "Manage account and editor options",
            icon: Settings,
            action: () => router.push("/app/settings"),
        },
        {
            id: "nav-profile",
            category: "Navigation",
            title: "User Profile",
            subtitle: "View and edit profile details",
            icon: User,
            action: () => router.push("/app/profile"),
        },
        {
            id: "nav-trash",
            category: "Navigation",
            title: "Trash",
            subtitle: "View and restore deleted notes",
            icon: Trash2,
            action: () => router.push("/app/trash"),
        },
    ];

    // Filter notes
    const noteItems: CommandItem[] = store.notes
        .filter((n) => !n.isDeleted)
        .map((n) => ({
            id: `note-${n._id}`,
            category: "Notes" as const,
            title: n.title || "Untitled",
            subtitle: n.folderId && typeof n.folderId === 'object' ? `Folder: ${n.folderId.name}` : undefined,
            icon: FileText,
            action: () => router.push(`/app/notes/${n._id}`),
        }));

    const all = [...defaultActions, ...noteItems];

    if (!q) {
        return all.slice(0, 10);
    }

    return all
        .filter(
            (item) =>
                item.title.toLowerCase().includes(q) ||
                (item.subtitle && item.subtitle.toLowerCase().includes(q))
        )
        .slice(0, 12);
});

watch(
    () => props.isOpen,
    (open) => {
        if (open) {
            query.value = "";
            selectedIndex.value = 0;
            isDark.value = document.documentElement.classList.contains("dark");
            nextTick(() => {
                inputRef.value?.focus();
            });
        }
    }
);

watch(filteredCommands, () => {
    selectedIndex.value = 0;
});

function handleKeydown(e: KeyboardEvent) {
    if (!props.isOpen) return;

    if (e.key === "ArrowDown") {
        e.preventDefault();
        selectedIndex.value = (selectedIndex.value + 1) % filteredCommands.value.length;
    } else if (e.key === "ArrowUp") {
        e.preventDefault();
        selectedIndex.value =
            (selectedIndex.value - 1 + filteredCommands.value.length) %
            filteredCommands.value.length;
    } else if (e.key === "Enter") {
        e.preventDefault();
        const selected = filteredCommands.value[selectedIndex.value];
        if (selected) {
            selected.action();
            emit("close");
        }
    } else if (e.key === "Escape") {
        emit("close");
    }
}
</script>

<template>
    <div
        v-if="isOpen"
        class="fixed inset-0 z-50 flex items-start justify-center pt-20 sm:pt-28 px-4 bg-ink-950/60 backdrop-blur-sm animate-fade-in"
        @click.self="emit('close')"
        @keydown="handleKeydown"
    >
        <div
            class="bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-800 rounded-2xl w-full max-w-xl shadow-2xl overflow-hidden flex flex-col animate-scale-up"
        >
            <!-- Search Header -->
            <div class="px-4 py-3.5 border-b border-ink-200 dark:border-ink-800 flex items-center gap-3">
                <Search :size="18" class="text-ink-400 shrink-0" />
                <input
                    ref="inputRef"
                    v-model="query"
                    type="text"
                    placeholder="Type a command or search notes… (↑↓ to navigate, ↵ to run)"
                    class="flex-1 bg-transparent text-sm text-ink-950 dark:text-ink-50 font-ui placeholder-ink-400 dark:placeholder-ink-600 outline-none"
                />
                <kbd class="px-2 py-0.5 rounded-md bg-ink-100 dark:bg-ink-800 text-[10px] font-mono text-ink-400 dark:text-ink-500">
                    ESC
                </kbd>
            </div>

            <!-- Command List -->
            <div class="max-h-96 overflow-y-auto p-2 space-y-1 font-ui">
                <div
                    v-if="filteredCommands.length === 0"
                    class="py-12 text-center text-xs text-ink-400"
                >
                    No matching notes or commands found for "{{ query }}"
                </div>

                <div
                    v-for="(item, index) in filteredCommands"
                    :key="item.id"
                    @click="item.action(); emit('close')"
                    @mouseenter="selectedIndex = index"
                    class="px-3.5 py-2.5 rounded-xl cursor-pointer flex items-center justify-between gap-3 transition-colors text-xs"
                    :class="
                        selectedIndex === index
                            ? 'bg-amber-500/10 text-amber-600 dark:text-amber-400 font-medium'
                            : 'text-ink-700 dark:text-ink-300 hover:bg-ink-50 dark:hover:bg-ink-800/60'
                    "
                >
                    <div class="flex items-center gap-3 min-w-0">
                        <component
                            :is="item.icon"
                            :size="16"
                            class="shrink-0"
                            :class="selectedIndex === index ? 'text-amber-500' : 'text-ink-400 dark:text-ink-500'"
                        />
                        <div class="min-w-0">
                            <p class="font-medium truncate text-ink-900 dark:text-ink-100">
                                {{ item.title }}
                            </p>
                            <p v-if="item.subtitle" class="text-[11px] text-ink-400 truncate">
                                {{ item.subtitle }}
                            </p>
                        </div>
                    </div>

                    <span class="text-[10px] text-ink-400 uppercase tracking-widest font-semibold shrink-0">
                        {{ item.category }}
                    </span>
                </div>
            </div>

            <!-- Footer -->
            <div class="px-4 py-2.5 bg-ink-50 dark:bg-ink-950/50 border-t border-ink-200 dark:border-ink-800 flex items-center justify-between text-[11px] font-ui text-ink-400">
                <div class="flex items-center gap-3">
                    <span class="flex items-center gap-1">
                        <kbd class="px-1.5 py-0.5 rounded bg-ink-200/80 dark:bg-ink-800 text-[10px] font-mono">↑↓</kbd> Navigate
                    </span>
                    <span class="flex items-center gap-1">
                        <kbd class="px-1.5 py-0.5 rounded bg-ink-200/80 dark:bg-ink-800 text-[10px] font-mono">↵</kbd> Select
                    </span>
                </div>
                <span>Caddo Spotlight</span>
            </div>
        </div>
    </div>
</template>
