<script setup lang="ts">
import { onMounted, computed, ref, watch } from "vue";
import { useRoute, useRouter, RouterLink } from "vue-router";
import {
    Pencil,
    Trash2,
    Star,
    ChevronDown,
    AlertTriangle,
} from "lucide-vue-next";
import { generateHTML } from "@tiptap/html";
import StarterKit from "@tiptap/starter-kit";
import Image from "@tiptap/extension-image";
import Link from "@tiptap/extension-link";
import { useNotesStore } from "../store/notes";

const route = useRoute();
const router = useRouter();
const store = useNotesStore();

const noteId = route.params.noteId as string;
const confirmDelete = ref(false);
let confirmTimer: ReturnType<typeof setTimeout>;

// Refresh note when route changes (e.g., returning from edit)
watch(() => route.params.noteId, (newId) => {
    if (newId) store.fetchNote(newId as string);
}, { immediate: true });

const content = computed(() => {
    if (!store.activeNote?.content) return "";
    try {
        return generateHTML(JSON.parse(store.activeNote.content), [
            StarterKit.configure({ link: false }),
            Image,
            Link,
        ]);
    } catch {
        return store.activeNote.content;
    }
});

function relativeTime(d: string): string {
    const diff = Date.now() - new Date(d).getTime();
    const mins = Math.floor(diff / 60_000);
    if (mins < 1) return "Saved just now";
    if (mins < 60) return `Saved ${mins}m ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `Saved ${hours}h ago`;
    const days = Math.floor(hours / 24);
    if (days === 1) return "Saved yesterday";
    return `Saved ${days}d ago`;
}

function startDelete() {
    confirmDelete.value = true;
    confirmTimer = setTimeout(() => {
        confirmDelete.value = false;
    }, 4000);
}
async function doDelete() {
    clearTimeout(confirmTimer);
    await store.deleteNote(noteId);
    router.push("/app/notes");
}
</script>

<template>
    <div class="flex flex-col h-full bg-white dark:bg-ink-950">
        <!-- ── Top bar (matches image: "Saved 2h ago" left, star + edit + delete right) ── -->
        <div class="flex items-center justify-between px-8 py-3 shrink-0">
            <span class="text-sm text-ink-400 dark:text-ink-600 font-ui">
                {{
                    store.activeNote
                        ? relativeTime(store.activeNote.updatedAt)
                        : "…"
                }}
            </span>

            <div class="flex items-center gap-1" v-if="store.activeNote">
                <!-- Star -->
                <button
                    @click="store.toggleFavorite(noteId)"
                    class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                >
                    <Star
                        :size="16"
                        :class="
                            store.activeNote.isFavorite
                                ? 'text-amber-500 fill-amber-500'
                                : 'text-ink-300 dark:text-ink-700'
                        "
                    />
                </button>

                <!-- Edit -->
                <RouterLink
                    :to="`/app/notes/${noteId}/edit`"
                    class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-ui font-semibold bg-ink-900 dark:bg-amber-500 text-white dark:text-ink-950 hover:bg-ink-700 dark:hover:bg-amber-600 transition-colors"
                >
                    <Pencil :size="12" /> Edit
                </RouterLink>

                <!-- Delete -->
                <Transition name="confirm">
                    <div
                        v-if="confirmDelete"
                        class="flex items-center gap-1.5 border border-red-200 dark:border-red-800 rounded-lg px-2.5 py-1.5"
                    >
                        <AlertTriangle :size="11" class="text-red-500" />
                        <span
                            class="text-xs text-red-600 dark:text-red-400 font-ui"
                            >Delete?</span
                        >
                        <button
                            @click="doDelete"
                            class="text-xs font-semibold font-ui text-red-600 dark:text-red-400 hover:underline ml-1"
                        >
                            Yes
                        </button>
                        <button
                            @click="confirmDelete = false"
                            class="text-xs font-ui text-ink-400 ml-0.5"
                        >
                            No
                        </button>
                    </div>
                </Transition>
                <button
                    v-if="!confirmDelete"
                    @click="startDelete"
                    class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors text-ink-300 dark:text-ink-700 hover:text-ink-600 dark:hover:text-ink-400"
                >
                    <Trash2 :size="15" />
                </button>

                <button
                    class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors text-ink-300 dark:text-ink-700"
                >
                    <ChevronDown :size="16" />
                </button>
            </div>
        </div>

        <!-- Divider -->
        <div class="h-px bg-ink-200 dark:bg-ink-800 shrink-0" />

        <!-- ── Content ── -->
        <div class="flex-1 overflow-y-auto">
            <!-- Loading -->
            <div
                v-if="store.loading && !store.activeNote"
                class="max-w-2xl mx-auto px-8 py-10 animate-pulse space-y-5"
            >
                <div class="h-12 bg-ink-100 dark:bg-ink-800 rounded w-2/3" />
                <div class="space-y-3 mt-6">
                    <div
                        v-for="i in 5"
                        :key="i"
                        class="h-4 bg-ink-100 dark:bg-ink-800 rounded"
                        :style="{ width: `${95 - i * 8}%` }"
                    />
                </div>
            </div>

            <div
                v-else-if="store.activeNote"
                class="max-w-2xl mx-auto px-8 pt-10 pb-20"
            >
                <!-- Title -->
                <h1
                    class="font-display text-4xl font-bold text-ink-900 dark:text-ink-50 leading-tight mb-8"
                >
                    {{ store.activeNote.title }}
                </h1>

                <!-- Prose content -->
                <div
                    class="prose prose-ink max-w-none font-body text-ink-700 dark:text-ink-300 leading-relaxed tiptap"
                    v-html="
                        content ||
                        `<p class='italic text-ink-300 dark:text-ink-700'>Empty note — <a href='/app/notes/${noteId}/edit'>start writing</a></p>`
                    "
                />
            </div>
        </div>
    </div>
</template>

<style scoped>
.confirm-enter-active,
.confirm-leave-active {
    transition:
        opacity 0.12s ease,
        transform 0.12s ease;
}
.confirm-enter-from,
.confirm-leave-to {
    opacity: 0;
    transform: scale(0.95);
}
</style>
