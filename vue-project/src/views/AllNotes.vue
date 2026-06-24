<script setup lang="ts">
import { onMounted, computed, ref } from "vue";
import { RouterLink, useRouter } from "vue-router";
import { PenLine, Trash2, Check } from "lucide-vue-next";
import { useNotesStore } from "@/store/notes";
import NoteCard from "@/assets/Ui/NoteCard.vue";

const store = useNotesStore();
const router = useRouter();
onMounted(() => store.fetchNotes());
const shown = computed(() => store.notes.filter((n) => !n.isDeleted));
const selectedNotes = ref<Set<string>>(new Set());
const isSelectionMode = ref(false);

function toggleSelectionMode() {
    isSelectionMode.value = !isSelectionMode.value;
    if (!isSelectionMode.value) {
        selectedNotes.value.clear();
    }
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
    isSelectionMode.value = false;
}

function clearSelection() {
    selectedNotes.value.clear();
}
</script>

<template>
    <div class="flex flex-col h-full bg-white dark:bg-ink-950">
        <!-- ── Top bar ── -->
        <div class="flex items-center justify-between px-8 py-4.5 shrink-0">
            <!-- Left: count or selected count -->
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
                                : `${shown.length} note${shown.length !== 1 ? "s" : ""}`
                        }}
                    </span>
                </template>
            </div>

            <!-- Right: new note or delete/exit -->
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
                    <RouterLink
                        to="/app/notes/new"
                        class="flex items-center gap-1.5 px-3 py-1.5 bg-ink-900 dark:bg-amber-500 hover:bg-ink-700 dark:hover:bg-amber-600 text-white dark:text-ink-950 rounded-lg font-ui font-semibold text-xs transition-colors"
                    >
                        <PenLine :size="13" /> New Note
                    </RouterLink>
                </template>
            </div>
        </div>

        <!-- Divider -->
        <div class="h-px bg-ink-200 dark:bg-ink-800 shrink-0" />

        <!-- ── Content ── -->
        <div class="flex-1 overflow-y-auto">
            <div class="max-w-6xl mx-auto px-8 py-6">
                <!-- Loading -->
                <div
                    v-if="store.loading"
                    class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
                >
                    <div
                        v-for="n in 8"
                        :key="n"
                        class="h-48 bg-ink-100 dark:bg-ink-800 rounded-xl animate-pulse"
                        :style="{ opacity: 1 - n * 0.09 }"
                    />
                </div>

                <!-- Empty -->
                <div
                    v-else-if="shown.length === 0"
                    class="flex flex-col items-center justify-center py-24 text-center"
                >
                    <p
                        class="font-display text-xl font-semibold text-ink-500 dark:text-ink-500 mb-2"
                    >
                        Your library is empty
                    </p>
                    <p class="text-sm text-ink-400 dark:text-ink-600 mb-5">
                        Create a note to see it here.
                    </p>
                    <RouterLink
                        to="/app/notes/new"
                        class="px-4 py-2 bg-ink-900 text-white rounded-lg text-sm font-ui font-semibold hover:bg-ink-700 transition-colors"
                        >New Note</RouterLink
                    >
                </div>

                <!-- Grid -->
                <div
                    v-else
                    class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4"
                >
                    <NoteCard
                        v-for="note in shown"
                        :key="note._id"
                        :note="note"
                        :is-selected="selectedNotes.has(note._id)"
                        :is-selection-mode="isSelectionMode"
                        @toggle-selection="toggleNoteSelection"
                        @enter-selection-mode="(id) => { isSelectionMode = true; toggleNoteSelection(id); }"
                    />
                    <RouterLink
                        v-if="!isSelectionMode"
                        to="/app/notes/new"
                        class="group flex flex-col items-center justify-center gap-3 rounded-xl border-2 border-dashed border-ink-200 dark:border-ink-700 hover:border-ink-400 dark:hover:border-ink-500 transition-colors min-h-[190px]"
                    >
                        <PenLine
                            :size="18"
                            class="text-ink-300 dark:text-ink-700 group-hover:text-ink-500 dark:group-hover:text-ink-400 transition-colors"
                        />
                        <span
                            class="text-xs text-ink-300 dark:text-ink-700 group-hover:text-ink-500 font-ui transition-colors"
                            >New Note</span
                        >
                    </RouterLink>
                </div>
            </div>
        </div>
    </div>
</template>
