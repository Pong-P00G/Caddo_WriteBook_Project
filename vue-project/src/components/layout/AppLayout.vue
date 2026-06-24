<script setup lang="ts">
import { RouterView, useRoute } from "vue-router";
import AppSidebar from "@/components/Sidebar.vue";

const route = useRoute();
</script>

<template>
    <div class="flex h-screen bg-ink-100 dark:bg-ink-950 overflow-hidden">
        <AppSidebar />
        <div
            class="flex-1 flex flex-col min-w-0 overflow-hidden bg-white dark:bg-ink-950"
        >
            <RouterView v-slot="{ Component }">
                <Transition name="page" mode="out-in">
                    <component :is="Component" :key="route.path" />
                </Transition>
            </RouterView>
        </div>
    </div>
</template>

<style scoped>
.page-enter-active,
.page-leave-active {
    transition:
        opacity 0.1s ease,
        transform 0.1s ease;
}
.page-enter-from {
    opacity: 0;
    transform: translateY(3px);
}
.page-leave-to {
    opacity: 0;
    transform: translateY(-3px);
}
</style>
