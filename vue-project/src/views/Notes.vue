<script setup lang="ts">
import { onMounted, ref, computed } from "vue";
import { RouterLink, useRouter } from "vue-router";
import {
    PenLine,
    Star,
    Search,
    StickyNote,
    X,
    LayoutGrid,
    List,
    Check,
    Trash2,
} from "lucide-vue-next";
import { useNotesStore } from "@/store/notes";
import NoteCard from "@/assets/Ui/NoteCard.vue";

const store = useNotesStore();
const router = useRouter();
const search = ref("");
const tab = ref<"all" | "favorites">("all");
let searchTimer: ReturnType<typeof setTimeout>;
const selectedNotes = ref<Set<string>>(new Set());
const isSelectionMode = ref(false);

function toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
        selectedNotes.value.clear();
    }
}

type ViewMode = "list" | "grid";
const viewMode = ref<ViewMode>(
    (localStorage.getItem("wb_notes_view") as ViewMode) ?? "list",
);
function setView(m: ViewMode) {
    viewMode.value = m;
    localStorage.setItem("wb_notes_view", m);
}

onMounted(() => store.fetchNotes());

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

function relativeTime(d: string): string {
    const diff = Date.now() - new Date(d).getTime();
    const mins = Math.floor(diff / 60_000);
    if (mins < 1) return "Just now";
    if (mins < 60) return `${mins}m ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    if (days === 1) return "Yesterday";
    if (days < 7) return `${days}d ago`;
    return new Date(d).toLocaleDateString(undefined, {
        month: "short",
        day: "numeric",
    });
}

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
    for (const n of filtered.value) {
        const label = dayLabel(n.updatedAt);
        if (!map.has(label)) map.set(label, []);
        map.get(label)!.push(n);
    }
    return order
        .filter((l) => map.has(l))
        .map((l) => ({ label: l, notes: map.get(l)! }));
});

function preview(content: string): string {
    if (!content) return "";
    try {
        const doc = JSON.parse(content);
        return (
            doc.content
                ?.flatMap((n: any) => n.content ?? [])
                .filter((n: any) => n.type === "text")
                .map((n: any) => n.text)
                .join(" ") ?? ""
        ).slice(0, 120);
    } catch {
        return content.slice(0, 120);
    }
}

function selecteDeleteAll(id: string) {
    groups.value.find((g) => g.label === id)?.notes.forEach((n) => store.deleteNote(n._id));
}

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
                        @click="clearSelection"
                        class="text-sm text-ink-500 hover:text-ink-800 dark:hover:text-ink-200 font-ui underline"
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

            <!-- Right: search + view toggle + new note or delete/exit selection -->
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
                    >
                        <LayoutGrid :size="14" />
                    </button>
                </div>

                <RouterLink
                    to="/app/notes/new"
                    class="flex items-center gap-1.5 px-3 py-1.5 bg-ink-900 dark:bg-amber-500 hover:bg-ink-700 dark:hover:bg-amber-600 text-white dark:text-ink-950 rounded-lg font-ui font-semibold text-xs transition-colors"
                >
                    <PenLine :size="13" />
                    New Note
                </RouterLink>
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
                    <div v-if="viewMode === 'list'" class="space-y-px">
                        <div
                            v-for="n in 6"
                            :key="n"
                            class="h-14 bg-ink-100 dark:bg-ink-800 rounded-lg animate-pulse"
                            :style="{ opacity: 1 - n * 0.12 }"
                        />
                    </div>
                    <div
                        v-else
                        class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
                    >
                        <div
                            v-for="n in 8"
                            :key="n"
                            class="h-48 bg-ink-100 dark:bg-ink-800 rounded-xl animate-pulse"
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
                                : "Start writing your first note."
                        }}
                    </p>
                    <button
                        v-if="search"
                        @click="clearSearch"
                        class="text-sm text-amber-600 hover:underline font-ui"
                    >
                        Clear search
                    </button>
                    <RouterLink
                        v-else-if="tab === 'all'"
                        to="/app/notes/new"
                        class="px-4 py-2 bg-ink-900 text-white rounded-lg text-sm font-ui font-semibold hover:bg-ink-700 transition-colors"
                        >New Note</RouterLink
                    >
                </div>

                <!-- Grid -->
                <Transition name="view" mode="out-in">
                    <div
                        v-if="viewMode === 'grid' && filtered.length"
                        key="grid"
                        class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
                    >
                        <NoteCard
                            v-for="note in filtered"
                            :key="note._id"
                            :note="note"
                            :is-selected="selectedNotes.has(note._id)"
                            :is-selection-mode="isSelectionMode"
                            @toggle-selection="toggleNoteSelection"
                            @enter-selection-mode="(id) => { isSelectionMode = true; toggleNoteSelection(id); }"
                        />
                    </div>

                    <!-- List -->
                    <div
                        v-else-if="viewMode === 'list' && filtered.length"
                        key="list"
                        class="space-y-6"
                    >
                        <div v-for="group in groups" :key="group.label">
                            <p
                                class="text-xs font-ui font-medium text-ink-400 dark:text-ink-600 mb-2 uppercase tracking-widest"
                            >
                                {{ group.label }}
                            </p>
                            <ul class="space-y-px">
                                <li
                                    v-for="note in group.notes"
                                    :key="note._id"
                                    @click="
                                        isSelectionMode
                                            ? toggleNoteSelection(note._id)
                                            : router.push(`/app/notes/${note._id}`)
                                    "
                                    @dblclick.stop="
                                        isSelectionMode = true;
                                        toggleNoteSelection(note._id);
                                    "
                                    class="group relative flex items-center gap-4 px-3 py-3 rounded-lg cursor-pointer hover:bg-ink-50 dark:hover:bg-ink-900 transition-colors"
                                    :class="{
                                        'bg-ink-100 dark:bg-ink-800': selectedNotes.has(note._id)
                                    }"
                                >
                                    <div
                                        v-if="isSelectionMode"
                                        @click.stop="toggleNoteSelection(note._id)"
                                        class="w-5 h-5 rounded border border-ink-300 dark:border-ink-600 flex items-center justify-center shrink-0 cursor-pointer hover:border-ink-500 dark:hover:border-ink-400 transition-colors"
                                        :class="{
                                            'bg-amber-500 border-amber-500': selectedNotes.has(note._id)
                                        }"
                                    >
                                        <Check
                                            v-if="selectedNotes.has(note._id)"
                                            :size="14"
                                            class="text-white"
                                        />
                                    </div>
                                    <div class="flex-1 min-w-0">
                                        <div class="flex items-center gap-2">
                                            <h3
                                                class="text-sm font-ui font-medium text-ink-900 dark:text-ink-100 truncate"
                                            >
                                                {{ note.title }}
                                            </h3>
                                            <Star
                                                v-if="note.isFavorite"
                                                :size="10"
                                                class="text-amber-500 fill-amber-500 shrink-0"
                                            />
                                        </div>
                                        <p
                                            class="text-xs text-ink-400 dark:text-ink-600 truncate mt-0.5"
                                        >
                                            {{
                                                preview(note.content) ||
                                                "Empty note"
                                            }}
                                        </p>
                                    </div>
                                    <span
                                        class="text-xs text-ink-300 dark:text-ink-700 shrink-0 tabular-nums"
                                        >{{
                                            relativeTime(note.updatedAt)
                                        }}</span
                                    >
                                </li>
                            </ul>
                        </div>
                    </div>
                </Transition>
            </div>
        </div>
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
</style>
