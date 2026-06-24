<script setup lang="ts">
import { onMounted, ref } from "vue";
import { useRoute, RouterLink, useRouter } from "vue-router";
import { Briefcase, ArrowLeft, Plus, Loader2 } from "lucide-vue-next";
import { useNotesStore } from "@/store/notes";
import api from "@/api/Api";

const route = useRoute();
const router = useRouter();
const store = useNotesStore();
const workspaceName = ref("");
const isCreating = ref(false);

onMounted(async () => {
    await loadWorkspace();
    await loadNotes();
});

async function loadWorkspace() {
    const workspaceId = route.params.workspaceId as string;
    try {
        const { data } = await api.get(`/workspaces/${workspaceId}`);
        if (data.success && data.data) {
            workspaceName.value = data.data.name;
        }
    } catch (e) {
        workspaceName.value = "Workspace";
    }
}

async function loadNotes() {
    const workspaceId = route.params.workspaceId as string;
    await store.fetchNotes({ workspaceId });
}

async function createNoteInWorkspace() {
    isCreating.value = true;
    try {
        const workspaceId = route.params.workspaceId as string;
        const note = await store.createNote({
            title: "Untitled",
            workspaceId,
        });
        router.push(`/app/notes/${note._id}/edit`);
    } catch (e) {
        console.error("Failed to create note:", e);
    } finally {
        isCreating.value = false;
    }
}
</script>

<template>
    <div class="p-6">
        <div class="flex items-center justify-between mb-6">
            <div class="flex items-center gap-3">
                <RouterLink to="/app/notes" class="p-2 rounded-lg hover:bg-[#f0f0f0] dark:hover:bg-[#2a2a2a] transition-colors">
                    <ArrowLeft :size="18" class="text-[#999] dark:text-[#666]" />
                </RouterLink>
                <Briefcase :size="20" class="text-[#999] dark:text-[#666]" />
                <h1 class="text-lg font-semibold text-[#1a1a1a] dark:text-[#f5f5f5]">
                    {{ workspaceName || "Workspace" }}
                </h1>
            </div>
            <button
                @click="createNoteInWorkspace"
                :disabled="isCreating"
                class="flex items-center gap-2 px-4 py-2 bg-amber-500 hover:bg-amber-600 text-[#1a1a1a] rounded-lg text-sm font-medium transition-colors disabled:opacity-50"
            >
                <Loader2 v-if="isCreating" :size="14" class="animate-spin" />
                <Plus v-else :size="14" />
                New Note
            </button>
        </div>

        <div v-if="store.loading" class="flex justify-center py-12">
            <div class="animate-spin w-6 h-6 border-2 border-amber-500 border-t-transparent rounded-full" />
        </div>

        <div v-else-if="store.notes.length === 0" class="text-center py-12">
            <Briefcase :size="40" class="mx-auto mb-3 text-[#999] dark:text-[#666] opacity-50" />
            <p class="text-[#999] dark:text-[#666] mb-4">No notes in this workspace</p>
            <button
                @click="createNoteInWorkspace"
                class="inline-flex items-center gap-2 px-4 py-2 bg-amber-500 hover:bg-amber-600 text-[#1a1a1a] rounded-lg text-sm font-medium transition-colors"
            >
                <Plus :size="14" />
                Create first note
            </button>
        </div>

        <div v-else class="space-y-2">
            <RouterLink
                v-for="note in store.notes"
                :key="note._id"
                :to="`/app/notes/${note._id}`"
                class="block p-4 rounded-xl bg-white dark:bg-[#252525] border border-[#e0e0e0] dark:border-[#3a3a3a] hover:border-[#ccc] dark:hover:border-[#555] transition-colors"
            >
                <h2 class="font-medium text-[#1a1a1a] dark:text-[#f5f5f5] mb-1">{{ note.title }}</h2>
                <p class="text-xs text-[#999] dark:text-[#666]">
                    {{ new Date(note.updatedAt).toLocaleDateString() }}
                </p>
            </RouterLink>
        </div>
    </div>
</template>