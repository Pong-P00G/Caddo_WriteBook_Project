<script setup lang="ts">
import { computed } from "vue";
import { useRoute } from "vue-router";

const route = useRoute();

const staticTitles: Record<string, string> = {
    "/app/notes": "My Notes",
    "/app/notes/new": "New Note",
    "/app/library": "All Notes",
    "/app/settings": "Settings",
    "/app/profile": "Profile",
    "/app/trash": "Trash",
};

const title = computed(() => staticTitles[route.path] ?? "Writebox");
</script>

<template>
    <header
        class="h-13 border-b border-ink-100 dark:border-ink-800 flex items-center px-6 bg-white dark:bg-ink-950 sticky top-0 z-10"
    >
        <h1
            class="font-ui text-sm font-semibold text-ink-700 dark:text-ink-300"
        >
            {{ title }}
        </h1>
    </header>
</template>
