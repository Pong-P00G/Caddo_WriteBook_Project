<script setup lang="ts">
import { onMounted, ref, computed, defineAsyncComponent, onUnmounted } from "vue";
import { RouterLink, useRouter } from "vue-router";
import {
    PenLine,
    Plus,
    Star,
    Pin,
    Search,
    StickyNote,
    X,
    LayoutGrid,
    List,
    Check,
    Trash2,
    CheckSquare,
    Sparkles,
    Upload,
} from "lucide-vue-next";
import { useNotesStore } from "@/store/notes";
import NoteCard from "@/components/NoteCard.vue";
import { useExportImport } from "@/composable/useExportImport";

const TemplateGalleryModal = defineAsyncComponent(
    () => import("@/components/TemplateGalleryModal.vue")
);

const store = useNotesStore();
const router = useRouter();
const { parseImportFile } = useExportImport();

const search = ref("");
const tab = ref<"all" | "favorites">("all");
let searchTimer: ReturnType<typeof setTimeout>;
const selectedNotes = ref<Set<string>>(new Set());
const isSelectionMode = ref(false);
const showTemplateModal = ref(false);
const fileInputRef = ref<HTMLInputElement | null>(null);

function toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
        selectedNotes.value.clear();
        selectedNotes.value = new Set();
    }
}

function selectAll() {
    filtered.value.forEach((n) => selectedNotes.value.add(n._id));
    selectedNotes.value = new Set(selectedNotes.value);
}

type ViewMode = "list" | "grid";
const viewMode = ref<ViewMode>(
    (localStorage.getItem("wb_notes_view") as ViewMode) ?? "list",
);
function setView(m: ViewMode) {
    viewMode.value = m;
    localStorage.setItem("wb_notes_view", m);
}

onMounted(() => {
    store.fetchNotes();
    window.addEventListener("keydown", handleKeydown);
});

onUnmounted(() => window.removeEventListener("keydown", handleKeydown));

function handleKeydown(e: KeyboardEvent) {
    if ((e.ctrlKey || e.metaKey) && e.key === "n") {
        e.preventDefault();
        router.push("/app/notes/new");
    }
}

function onSearch() {
    clearTimeout(searchTimer);
    searchTimer = setTimeout(
        () => store.fetchNotes({ search: search.value || undefined }),
        300,
    );
}

function clearSearch() {
    search.value = "";
    store.fetchNotes();
}

const filtered = computed(() =>
    tab.value === "favorites"
        ? store.notes.filter((n) => n.isFavorite)
        : store.notes,
);

const pinnedNotes = computed(() => filtered.value.filter((n) => n.isPinned));
const unpinnedNotes = computed(() => filtered.value.filter((n) => !n.isPinned));

function dayLabel(d: string): string {
    const diff = Date.now() - new Date(d).getTime();
    const days = Math.floor(diff / 86_400_000);
    if (days < 1) return "Today";
    if (days < 2) return "Yesterday";
    if (days < 7) return "This week";
    return "Earlier";
}

interface Group {
    label: string;
    notes: typeof store.notes;
}

const groups = computed((): Group[] => {
    const order = ["Today", "Yesterday", "This week", "Earlier"];
    const map = new Map<string, typeof store.notes>();
    for (const n of unpinnedNotes.value) {
        const label = dayLabel(n.updatedAt);
        if (!map.has(label)) map.set(label, []);
        map.get(label)!.push(n);
    }
    return order
        .filter((l) => map.has(l))
        .map((l) => ({ label: l, notes: map.get(l)! }));
});

function toggleNoteSelection(id: string) {
    if (selectedNotes.value.has(id)) {
        selectedNotes.value.delete(id);
    } else {
        selectedNotes.value.add(id);
    }
    selectedNotes.value = new Set(selectedNotes.value);
}

function deleteSelectedNotes() {
    selectedNotes.value.forEach((id) => store.deleteNote(id));
    selectedNotes.value.clear();
}

function clearSelection() {
    selectedNotes.value.clear();
}

function enterSelectionMode(id: string) {
    isSelectionMode.value = true;
    toggleNoteSelection(id);
}

async function onFileImport(e: Event) {
    const input = e.target as HTMLInputElement;
    if (!input.files || input.files.length === 0) return;
    const file = input.files[0];
    try {
        const result = await parseImportFile(file);
        const newNote = await store.createNote({
            title: result.title,
            content: result.content,
        });
        router.push(`/app/notes/${newNote._id}`);
    } finally {
        input.value = "";
    }
}
</script>

<template>
    <div class="flex flex-col h-full bg-white dark:bg-ink-950">
        <!-- ── Top bar ── -->
        <div class="flex items-center justify-between px-8 py-3 shrink-0">
            <!-- Left: count + tabs or selected count -->
            <div class="flex items-center gap-4">
                <template v-if="isSelectionMode">
                    <span class="text-sm text-ink-400 dark:text-ink-600 font-ui">
                        {{ selectedNotes.size }} note{{ selectedNotes.size !== 1 ? "s" : "" }} selected
                    </span>
                    <button
                        @click="selectAll"
                        class="text-sm text-ink-500 hover:text-ink-800 dark:hover:text-ink-200 font-ui underline transition-colors"
                    >
                        Select all
                    </button>
                    <button
                        @click="clearSelection"
                        class="text-sm text-ink-500 hover:text-ink-800 dark:hover:text-ink-200 font-ui underline transition-colors"
                    >
                        Clear
                    </button>
                </template>
                <template v-else>
                    <span class="text-sm text-ink-400 dark:text-ink-600 font-ui">
                        {{
                            store.loading
                                ? "…"
                                : `${filtered.length} note${filtered.length !== 1 ? "s" : ""}`
                        }}
                    </span>
                    <div class="flex items-center gap-0.5">
                        <button
                            v-for="t in [
                                { id: 'all', label: 'All' },
                                { id: 'favorites', label: 'Favorites' },
                            ]"
                            :key="t.id"
                            @click="tab = t.id as any"
                            class="px-3 py-1 rounded-md text-xs font-ui transition-colors"
                            :class="
                                tab === t.id
                                    ? 'bg-ink-100 dark:bg-ink-800 text-ink-800 dark:text-ink-200 font-medium'
                                    : 'text-ink-500 dark:text-ink-500 hover:text-ink-800 dark:hover:text-ink-200'
                            "
                        >
                            {{ t.label }}
                        </button>
                    </div>
                </template>
            </div>

            <!-- Right: search + view toggle + templates + import + new note -->
            <div class="flex items-center gap-2">
                <template v-if="isSelectionMode">
                    <button
                        @click="toggleSelectionMode"
                        class="flex items-center gap-1.5 px-3 py-1.5 bg-ink-200 dark:bg-ink-700 hover:bg-ink-300 dark:hover:bg-ink-600 text-ink-800 dark:text-ink-200 rounded-lg font-ui font-semibold text-xs transition-colors"
                    >
                        Exit
                    </button>
                    <button
                        @click="deleteSelectedNotes"
                        class="flex items-center gap-1.5 px-3 py-1.5 bg-red-600 hover:bg-red-700 text-white rounded-lg font-ui font-semibold text-xs transition-colors"
                    >
                        <Trash2 :size="13" />
                        Delete
                    </button>
                </template>
                <template v-else>
                    <div class="relative">
                        <Search
                            :size="13"
                            class="absolute left-2.5 top-1/2 -translate-y-1/2 text-ink-400"
                        />
                        <input
                            v-model="search"
                            @input="onSearch"
                            type="text"
                            placeholder="Search…"
                            class="pl-8 pr-7 py-1.5 w-48 rounded-lg border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-900 text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600 text-xs font-ui focus:outline-none focus:ring-2 focus:ring-amber-400 focus:w-64 transition-all"
                        />
                        <button
                            v-if="search"
                            @click="clearSearch"
                            class="absolute right-2 top-1/2 -translate-y-1/2 text-ink-300 hover:text-ink-600 transition-colors"
                        >
                            <X :size="11" />
                        </button>
                    </div>

                    <!-- View Toggle -->
                    <div
                        class="flex items-center gap-0.5 border border-ink-200 dark:border-ink-700 rounded-lg p-0.5"
                    >
                        <button
                            @click="setView('list')"
                            class="p-1.5 rounded transition-colors"
                            :class="
                                viewMode === 'list'
                                    ? 'bg-ink-100 dark:bg-ink-800 text-ink-800 dark:text-ink-200'
                                    : 'text-ink-400 hover:text-ink-700'
                            "
                            title="List View"
                        >
                            <List :size="14" />
                        </button>
                        <button
                            @click="setView('grid')"
                            class="p-1.5 rounded transition-colors"
                            :class="
                                viewMode === 'grid'
                                    ? 'bg-ink-100 dark:bg-ink-800 text-ink-800 dark:text-ink-200'
                                    : 'text-ink-400 hover:text-ink-700'
                            "
                            title="Grid View"
                        >
                            <LayoutGrid :size="14" />
                        </button>
                    </div>

                    <!-- Starter Templates Button -->
                    <button
                        @click="showTemplateModal = true"
                        class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-ink-200 dark:border-ink-700 hover:bg-ink-100 dark:hover:bg-ink-800 text-xs font-ui text-ink-700 dark:text-ink-300 transition-colors"
                        title="Browse starter templates"
                    >
                        <Sparkles :size="13" class="text-amber-500" />
                        <span class="hidden sm:inline">Templates</span>
                    </button>

                    <!-- Import Markdown/Text Button -->
                    <input
                        ref="fileInputRef"
                        type="file"
                        accept=".md,.txt,.markdown"
                        class="hidden"
                        @change="onFileImport"
                    />
                    <button
                        @click="fileInputRef?.click()"
                        class="p-1.5 rounded-lg border border-ink-200 dark:border-ink-700 hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-500 hover:text-ink-800 dark:hover:text-ink-200 transition-colors"
                        title="Import Markdown (.md) or Text file"
                    >
                        <Upload :size="14" />
                    </button>

                    <!-- New Note Button -->
                    <div class="relative group/tooltip">
                        <RouterLink
                            to="/app/notes/new"
                            class="flex items-center gap-1.5 px-3.5 py-1.5 bg-amber-500 hover:bg-amber-600 text-white rounded-lg font-ui font-semibold text-xs shadow-sm hover:shadow-amber-500/20 active:scale-[0.97] transition-all duration-150"
                        >
                            <Plus :size="14" class="stroke-[2.5]" />
                            <span>New Note</span>
                        </RouterLink>
                        <!-- Keyboard shortcut tooltip -->
                        <div class="tooltip whitespace-nowrap">
                            New note <kbd class="ml-1 px-1 py-0.5 text-[9px] bg-white/20 rounded">Ctrl+N</kbd>
                        </div>
                    </div>
                </template>
            </div>
        </div>

        <!-- Divider -->
        <div class="h-px bg-ink-200 dark:bg-ink-800 shrink-0" />

        <!-- ── Content ── -->
        <div class="flex-1 overflow-y-auto">
            <div
                :class="viewMode === 'grid' ? 'max-w-5xl' : 'max-w-3xl'"
                class="mx-auto px-8 py-6"
            >
                <!-- Loading -->
                <template v-if="store.loading">
                    <div v-if="viewMode === 'list'" class="space-y-3">
                        <div
                            v-for="n in 6"
                            :key="n"
                            class="h-16 skeleton-pulse"
                            :style="{ opacity: 1 - n * 0.12 }"
                        />
                    </div>
                    <div
                        v-else
                        class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
                    >
                        <div
                            v-for="n in 8"
                            :key="n"
                            class="h-52 skeleton-pulse"
                            :style="{ opacity: 1 - n * 0.1 }"
                        />
                    </div>
                </template>

                <!-- Empty -->
                <div
                    v-else-if="filtered.length === 0"
                    class="flex flex-col items-center justify-center py-24 text-center"
                >
                    <StickyNote
                        :size="32"
                        class="text-ink-200 dark:text-ink-700 mb-4"
                    />
                    <p
                        class="font-display text-lg font-semibold text-ink-600 dark:text-ink-400 mb-1"
                    >
                        {{
                            search
                                ? "No results"
                                : tab === "favorites"
                                  ? "No favorites yet"
                                  : "No notes yet"
                        }}
                    </p>
                    <p class="text-sm text-ink-400 dark:text-ink-600 mb-5">
                        {{
                            search
                                ? `Nothing matches "${search}"`
                                : "Start writing your first note or pick a starter template."
                        }}
                    </p>
                    <div class="flex items-center gap-2">
                        <button
                            v-if="search"
                            @click="clearSearch"
                            class="text-sm text-amber-600 hover:underline font-ui"
                        >
                            Clear search
                        </button>
                        <template v-else-if="tab === 'all'">
                            <button
                                @click="showTemplateModal = true"
                                class="px-3.5 py-2 bg-ink-100 dark:bg-ink-800 text-ink-800 dark:text-ink-200 rounded-lg text-sm font-ui font-semibold hover:bg-ink-200 dark:hover:bg-ink-700 transition-colors flex items-center gap-1.5"
                            >
                                <Sparkles :size="15" class="text-amber-500" />
                                Browse Templates
                            </button>
                            <RouterLink
                                to="/app/notes/new"
                                class="px-4 py-2 bg-amber-500 text-white rounded-lg text-sm font-ui font-semibold hover:bg-amber-600 transition-colors"
                            >
                                Blank Note
                            </RouterLink>
                        </template>
                    </div>
                </div>

                <!-- Notes Content (with Pinned section) -->
                <div v-else class="space-y-8">
                    <!-- ── Pinned Section (if any) ── -->
                    <div v-if="pinnedNotes.length" class="space-y-3">
                        <div class="flex items-center gap-2 text-xs font-ui font-semibold text-amber-600 dark:text-amber-400 uppercase tracking-widest">
                            <Pin :size="13" class="fill-amber-500" />
                            <span>Pinned Notes</span>
                        </div>

                        <!-- Pinned Grid -->
                        <div
                            v-if="viewMode === 'grid'"
                            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4.5"
                        >
                            <NoteCard
                                v-for="note in pinnedNotes"
                                :key="note._id"
                                :note="note"
                                :is-selected="selectedNotes.has(note._id)"
                                :is-selection-mode="isSelectionMode"
                                @toggle-selection="toggleNoteSelection"
                                @enter-selection-mode="enterSelectionMode"
                            />
                        </div>

                        <!-- Pinned List -->
                        <div v-else class="space-y-2">
                            <NoteCard
                                v-for="note in pinnedNotes"
                                :key="note._id"
                                :note="note"
                                view-mode="list"
                                :is-selected="selectedNotes.has(note._id)"
                                :is-selection-mode="isSelectionMode"
                                @toggle-selection="toggleNoteSelection"
                                @enter-selection-mode="enterSelectionMode"
                            />
                        </div>
                    </div>

                    <!-- ── All / Unpinned Notes Section ── -->
                    <div>
                        <div v-if="pinnedNotes.length && unpinnedNotes.length" class="flex items-center gap-2 text-xs font-ui font-medium text-ink-400 dark:text-ink-600 mb-3 uppercase tracking-widest">
                            <span>Other Notes</span>
                        </div>

                        <!-- Grid View -->
                        <div
                            v-if="viewMode === 'grid' && unpinnedNotes.length"
                            class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4.5"
                        >
                            <NoteCard
                                v-for="note in unpinnedNotes"
                                :key="note._id"
                                :note="note"
                                :is-selected="selectedNotes.has(note._id)"
                                :is-selection-mode="isSelectionMode"
                                @toggle-selection="toggleNoteSelection"
                                @enter-selection-mode="enterSelectionMode"
                            />
                        </div>

                        <!-- List View (Date grouped) -->
                        <div
                            v-else-if="viewMode === 'list' && unpinnedNotes.length"
                            class="space-y-6"
                        >
                            <div v-for="group in groups" :key="group.label">
                                <p
                                    class="text-xs font-ui font-medium text-ink-400 dark:text-ink-600 mb-2 uppercase tracking-widest"
                                >
                                    {{ group.label }}
                                </p>
                                <TransitionGroup
                                    name="list-item"
                                    tag="div"
                                    class="space-y-2"
                                >
                                    <NoteCard
                                        v-for="note in group.notes"
                                        :key="note._id"
                                        :note="note"
                                        view-mode="list"
                                        :is-selected="selectedNotes.has(note._id)"
                                        :is-selection-mode="isSelectionMode"
                                        @toggle-selection="toggleNoteSelection"
                                        @enter-selection-mode="enterSelectionMode"
                                    />
                                </TransitionGroup>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Templates Modal -->
        <TemplateGalleryModal
            :is-open="showTemplateModal"
            @close="showTemplateModal = false"
        />
    </div>
</template>

<style scoped>
.view-enter-active,
.view-leave-active {
    transition: opacity 0.1s ease;
}
.view-enter-from,
.view-leave-to {
    opacity: 0;
}

/* List item stagger animation */
.list-item-enter-active {
    transition: all 0.2s ease;
}
.list-item-leave-active {
    transition: all 0.15s ease;
}
.list-item-enter-from {
    opacity: 0;
    transform: translateY(-4px);
}
.list-item-leave-to {
    opacity: 0;
    transform: translateX(8px);
}
</style>
