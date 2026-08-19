<script setup lang="ts">
import { ref, watch } from "vue";
import { useNotesStore } from "@/store/notes";
import type { NoteRevision } from "@/store/types/interface";
import {
    X,
    History,
    RotateCcw,
    BookmarkPlus,
    Clock,
    CheckCircle2,
    Eye,
    Loader2,
    FileText,
} from "lucide-vue-next";

const props = defineProps<{
    isOpen: boolean;
    noteId: string;
}>();

const emit = defineEmits<{
    (e: "close"): void;
    (e: "restored", restoredContent: string, restoredTitle: string): void;
}>();

const store = useNotesStore();
const selectedRev = ref<NoteRevision | null>(null);
const isLoading = ref(false);
const isRestoring = ref(false);
const isCreatingCheckpoint = ref(false);
const checkpointSummary = ref("");
const showCheckpointInput = ref(false);

watch(
    () => props.isOpen,
    async (open) => {
        if (open && props.noteId) {
            isLoading.value = true;
            try {
                const list = await store.fetchRevisions(props.noteId);
                if (list.length > 0) {
                    await selectRevision(list[0]);
                } else {
                    selectedRev.value = null;
                }
            } finally {
                isLoading.value = false;
            }
        }
    },
    { immediate: true }
);

async function selectRevision(rev: NoteRevision) {
    if (!rev.content) {
        isLoading.value = true;
        try {
            const detail = await store.fetchRevisionDetail(props.noteId, rev._id);
            selectedRev.value = detail;
        } finally {
            isLoading.value = false;
        }
    } else {
        selectedRev.value = rev;
    }
}

function parseRevisionText(content?: string): string {
    if (!content) return "Empty content";
    try {
        const doc = JSON.parse(content);
        function walk(nodes: any[]): string {
            return nodes
                .reduce((acc: string[], n) => {
                    if (n.type === "text") {
                        acc.push(n.text ?? "");
                    } else if (n.content) {
                        acc.push(walk(n.content));
                    }
                    return acc;
                }, [])
                .join("\n");
        }
        return walk(doc.content ?? []).trim() || "No text in this version";
    } catch {
        return content;
    }
}

async function handleRestore() {
    if (!selectedRev.value) return;
    if (!confirm(`Restore note to snapshot from ${new Date(selectedRev.value.createdAt).toLocaleString()}? Current state will be backed up.`)) {
        return;
    }

    isRestoring.value = true;
    try {
        const updated = await store.restoreRevision(props.noteId, selectedRev.value._id);
        emit("restored", updated.content, updated.title);
        emit("close");
    } finally {
        isRestoring.value = false;
    }
}

async function handleCreateCheckpoint() {
    const summary = checkpointSummary.value.trim() || "Manual checkpoint";
    isCreatingCheckpoint.value = true;
    try {
        await store.createRevision(props.noteId, summary);
        checkpointSummary.value = "";
        showCheckpointInput.value = false;
        const list = await store.fetchRevisions(props.noteId);
        if (list.length > 0) selectRevision(list[0]);
    } finally {
        isCreatingCheckpoint.value = false;
    }
}

function formatDate(dateStr: string) {
    const d = new Date(dateStr);
    return {
        date: d.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" }),
        time: d.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" }),
    };
}
</script>

<template>
    <div
        v-if="isOpen"
        class="fixed inset-0 z-50 flex justify-end bg-ink-950/40 backdrop-blur-xs transition-opacity"
        @click.self="emit('close')"
    >
        <div
            class="bg-white dark:bg-ink-900 border-l border-ink-200 dark:border-ink-800 w-full max-w-2xl h-full shadow-2xl flex flex-col animate-slide-left"
        >
            <!-- Header -->
            <div class="px-6 py-4 border-b border-ink-200 dark:border-ink-800 flex items-center justify-between shrink-0">
                <div class="flex items-center gap-2.5">
                    <div class="p-2 rounded-xl bg-amber-500/10 text-amber-500">
                        <History :size="18" />
                    </div>
                    <div>
                        <h2 class="text-base font-display font-bold text-ink-900 dark:text-ink-50">
                            Version History
                        </h2>
                        <p class="text-xs text-ink-500 dark:text-ink-400 font-ui">
                            Browse snapshots and restore previous edits
                        </p>
                    </div>
                </div>

                <div class="flex items-center gap-2">
                    <button
                        @click="showCheckpointInput = !showCheckpointInput"
                        class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg border border-ink-200 dark:border-ink-700 text-ink-700 dark:text-ink-300 hover:bg-ink-50 dark:hover:bg-ink-800 text-xs font-ui transition-colors"
                    >
                        <BookmarkPlus :size="14" />
                        <span>Save Checkpoint</span>
                    </button>
                    <button
                        @click="emit('close')"
                        class="p-2 text-ink-400 hover:text-ink-700 dark:hover:text-ink-200 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                    >
                        <X :size="18" />
                    </button>
                </div>
            </div>

            <!-- Create Checkpoint Input -->
            <div
                v-if="showCheckpointInput"
                class="px-6 py-3 bg-amber-50/60 dark:bg-amber-950/20 border-b border-amber-200/60 dark:border-amber-800/40 flex items-center gap-2"
            >
                <input
                    v-model="checkpointSummary"
                    @keydown.enter="handleCreateCheckpoint"
                    type="text"
                    placeholder="Checkpoint name (e.g. Before big rewrite)..."
                    class="flex-1 px-3 py-1.5 rounded-lg border border-amber-300 dark:border-amber-700 bg-white dark:bg-ink-900 text-xs text-ink-900 dark:text-ink-100 placeholder-ink-400 focus:outline-none focus:ring-2 focus:ring-amber-500 font-ui"
                />
                <button
                    @click="handleCreateCheckpoint"
                    :disabled="isCreatingCheckpoint"
                    class="px-3 py-1.5 rounded-lg bg-amber-500 hover:bg-amber-600 text-white text-xs font-ui font-medium flex items-center gap-1"
                >
                    <Loader2 v-if="isCreatingCheckpoint" :size="12" class="animate-spin" />
                    Save
                </button>
            </div>

            <!-- Body: Left list & Right preview -->
            <div class="flex-1 flex overflow-hidden">
                <!-- Revision List -->
                <div class="w-64 border-r border-ink-200 dark:border-ink-800 overflow-y-auto p-3 space-y-1.5 shrink-0 bg-ink-50/40 dark:bg-ink-950/40">
                    <div v-if="isLoading && store.revisions.length === 0" class="flex items-center justify-center p-8 text-ink-400 text-xs font-ui">
                        <Loader2 :size="16" class="animate-spin mr-2" /> Loading history…
                    </div>

                    <div v-else-if="store.revisions.length === 0" class="text-center p-6 text-xs text-ink-400 font-ui">
                        No revisions recorded yet. Revisions are created automatically as you make changes.
                    </div>

                    <div
                        v-for="rev in store.revisions"
                        :key="rev._id"
                        @click="selectRevision(rev)"
                        class="p-3 rounded-xl border text-left cursor-pointer transition-all duration-150 relative"
                        :class="
                            selectedRev?._id === rev._id
                                ? 'bg-amber-50/90 dark:bg-amber-950/30 border-amber-400/80 dark:border-amber-600/80 text-ink-900 dark:text-ink-50 shadow-xs'
                                : 'bg-white dark:bg-ink-900 border-ink-200/80 dark:border-ink-800 hover:border-ink-300 dark:hover:border-ink-700 text-ink-700 dark:text-ink-300'
                        "
                    >
                        <div class="flex items-center justify-between text-[11px] text-ink-400 dark:text-ink-500 font-ui mb-1">
                            <span class="flex items-center gap-1">
                                <Clock :size="11" />
                                {{ formatDate(rev.createdAt).time }}
                            </span>
                            <span>{{ formatDate(rev.createdAt).date }}</span>
                        </div>
                        <p class="text-xs font-medium line-clamp-1">
                            {{ rev.title || "Untitled" }}
                        </p>
                        <span class="inline-block mt-1 text-[10px] px-1.5 py-0.5 rounded bg-ink-100 dark:bg-ink-800 text-ink-500 dark:text-ink-400 font-ui">
                            {{ rev.changeSummary || "Auto-saved" }}
                        </span>
                    </div>
                </div>

                <!-- Revision Preview -->
                <div class="flex-1 flex flex-col overflow-hidden bg-white dark:bg-ink-900">
                    <div v-if="selectedRev" class="flex-1 flex flex-col overflow-hidden">
                        <!-- Preview Header -->
                        <div class="px-6 py-3 border-b border-ink-100 dark:border-ink-800/80 flex items-center justify-between bg-ink-50/30 dark:bg-ink-950/20">
                            <div>
                                <h3 class="text-sm font-semibold text-ink-900 dark:text-ink-100 font-display">
                                    {{ selectedRev.title || "Untitled" }}
                                </h3>
                                <p class="text-[11px] text-ink-400 dark:text-ink-500 font-ui">
                                    Snapshot from {{ new Date(selectedRev.createdAt).toLocaleString() }}
                                </p>
                            </div>

                            <button
                                @click="handleRestore"
                                :disabled="isRestoring"
                                class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-amber-500 hover:bg-amber-600 text-white font-ui font-semibold text-xs shadow-xs transition-colors"
                            >
                                <Loader2 v-if="isRestoring" :size="13" class="animate-spin" />
                                <RotateCcw v-else :size="13" />
                                <span>Restore this version</span>
                            </button>
                        </div>

                        <!-- Content Preview text -->
                        <div class="flex-1 p-6 overflow-y-auto font-body text-sm leading-relaxed text-ink-800 dark:text-ink-200 whitespace-pre-wrap select-text">
                            {{ parseRevisionText(selectedRev.content) }}
                        </div>
                    </div>

                    <div v-else class="flex-1 flex flex-col items-center justify-center text-ink-400 p-8 text-center">
                        <FileText :size="32" class="mb-2 opacity-40" />
                        <p class="text-xs font-ui">Select a revision from the left to preview its content</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
