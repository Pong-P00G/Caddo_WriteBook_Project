<script setup lang="ts">
import { ref, onMounted, onUnmounted } from "vue";
import { RouterView, useRoute } from "vue-router";
import AppSidebar from "@/components/Sidebar.vue";
import ToastContainer from "@/components/ToastContainer.vue";
import CommandPaletteModal from "@/components/CommandPaletteModal.vue";
import TemplateGalleryModal from "@/components/TemplateGalleryModal.vue";
import KeyboardShortcutsModal from "@/components/KeyboardShortcutsModal.vue";

const route = useRoute();
const showCommandPalette = ref(false);
const showTemplateModal = ref(false);
const showShortcutsModal = ref(false);

function handleGlobalKeydown(e: KeyboardEvent) {
    // Cmd+K or Ctrl+K
    if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        showCommandPalette.value = !showCommandPalette.value;
        return;
    }

    // Cmd+/ or Ctrl+/ or ? (when not inside an input/textarea/editor)
    const target = e.target as HTMLElement;
    const isEditing = target.tagName === "INPUT" || target.tagName === "TEXTAREA" || target.isContentEditable;
    if (!isEditing && ((e.metaKey || e.ctrlKey) && e.key === "/" || e.key === "?")) {
        e.preventDefault();
        showShortcutsModal.value = !showShortcutsModal.value;
    }
}

onMounted(() => {
    window.addEventListener("keydown", handleGlobalKeydown);
});

onUnmounted(() => {
    window.removeEventListener("keydown", handleGlobalKeydown);
});
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

        <!-- Global Toast Container -->
        <ToastContainer />

        <!-- Command Palette Spotlight -->
        <CommandPaletteModal
            :is-open="showCommandPalette"
            @close="showCommandPalette = false"
            @open-templates="showCommandPalette = false; showTemplateModal = true"
        />

        <!-- Starter Templates Modal -->
        <TemplateGalleryModal
            :is-open="showTemplateModal"
            @close="showTemplateModal = false"
        />

        <!-- Keyboard Shortcuts Modal -->
        <KeyboardShortcutsModal
            :is-open="showShortcutsModal"
            @close="showShortcutsModal = false"
        />
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
