<script setup lang="ts">
import { onMounted, ref } from "vue";
import { useRoute, RouterLink } from "vue-router";
import { Folder, ArrowLeft } from "lucide-vue-next";
import { useNotesStore } from "@/store/notes";

const route = useRoute();
const store = useNotesStore();
const folderName = ref("");

onMounted(async () => {
    const folderId = route.params.folderId as string;
    await store.fetchNotes({ folderId });
    // Try to get folder name from first note's folder
    if (store.notes[0]?.folderId) {
        folderName.value = store.notes[0].folderId.name || "Folder";
    }
});
</script>

<template>
    <div class="p-6">
        <div class="flex items-center gap-3 mb-6">
            <RouterLink to="/app/notes" class="p-2 rounded-lg hover:bg-[#f0f0f0] dark:hover:bg-[#2a2a2a] transition-colors">
                <ArrowLeft :size="18" class="text-[#999] dark:text-[#666]" />
            </RouterLink>
            <Folder :size="20" class="text-[#999] dark:text-[#666]" />
            <h1 class="text-lg font-semibold text-[#1a1a1a] dark:text-[#f5f5f5]">
                {{ folderName || "Folder" }}
            </h1>
        </div>

        <div v-if="store.loading" class="flex justify-center py-12">
            <div class="animate-spin w-6 h-6 border-2 border-amber-500 border-t-transparent rounded-full" />
        </div>

        <div v-else-if="store.notes.length === 0" class="text-center py-12 text-[#999] dark:text-[#666]">
            <Folder :size="40" class="mx-auto mb-3 opacity-50" />
            <p>No notes in this folder</p>
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