<script setup lang="ts">
import { X, Command, Keyboard } from "lucide-vue-next";

defineProps<{
    isOpen: boolean;
}>();

const emit = defineEmits<{
    (e: "close"): void;
}>();

const isMac = typeof navigator !== "undefined" && /Mac|iPod|iPhone|iPad/.test(navigator.platform);
const modKey = isMac ? "⌘" : "Ctrl";

const shortcuts = [
    { section: "Global & Navigation", items: [
        { label: "Open Command Spotlight", keys: [`${modKey}`, "K"] },
        { label: "New Note", keys: [`${modKey}`, "Alt", "N"] },
        { label: "Close Modal / Drawer", keys: ["Esc"] },
    ]},
    { section: "Formatting", items: [
        { label: "Bold text", keys: [`${modKey}`, "B"] },
        { label: "Italic text", keys: [`${modKey}`, "I"] },
        { label: "Underline text", keys: [`${modKey}`, "U"] },
        { label: "Inline code", keys: [`${modKey}`, "E"] },
        { label: "Strikethrough", keys: [`${modKey}`, "Shift", "X"] },
    ]},
    { section: "Elements & Blocks", items: [
        { label: "Heading 1", keys: [`${modKey}`, "Alt", "1"] },
        { label: "Heading 2", keys: [`${modKey}`, "Alt", "2"] },
        { label: "Bullet list", keys: [`${modKey}`, "Shift", "8"] },
        { label: "Numbered list", keys: [`${modKey}`, "Shift", "7"] },
        { label: "Task list", keys: [`${modKey}`, "Shift", "9"] },
        { label: "Quote block", keys: [`${modKey}`, "Shift", "B"] },
        { label: "Code block", keys: [`${modKey}`, "Alt", "C"] },
    ]},
];
</script>

<template>
    <div
        v-if="isOpen"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-ink-950/60 backdrop-blur-sm animate-fade-in"
        @click.self="emit('close')"
    >
        <div
            class="bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-800 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col animate-scale-up"
        >
            <!-- Header -->
            <div class="px-6 py-4 border-b border-ink-200 dark:border-ink-800 flex items-center justify-between">
                <div class="flex items-center gap-2.5">
                    <div class="p-2 rounded-xl bg-amber-500/10 text-amber-500">
                        <Keyboard :size="18" />
                    </div>
                    <div>
                        <h2 class="text-base font-display font-bold text-ink-900 dark:text-ink-50">
                            Keyboard Shortcuts
                        </h2>
                        <p class="text-xs text-ink-500 dark:text-ink-400 font-ui">
                            Speed up your workflow
                        </p>
                    </div>
                </div>
                <button
                    @click="emit('close')"
                    class="p-2 text-ink-400 hover:text-ink-700 dark:hover:text-ink-200 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                >
                    <X :size="18" />
                </button>
            </div>

            <!-- Body -->
            <div class="p-6 max-h-[70vh] overflow-y-auto space-y-6 font-ui">
                <div v-for="sec in shortcuts" :key="sec.section" class="space-y-2.5">
                    <h3 class="text-[11px] font-semibold uppercase tracking-widest text-ink-400 dark:text-ink-500">
                        {{ sec.section }}
                    </h3>
                    <div class="space-y-1.5">
                        <div
                            v-for="item in sec.items"
                            :key="item.label"
                            class="flex items-center justify-between py-1.5 px-2.5 rounded-xl hover:bg-ink-50 dark:hover:bg-ink-800/50 text-xs text-ink-700 dark:text-ink-300"
                        >
                            <span>{{ item.label }}</span>
                            <div class="flex items-center gap-1">
                                <kbd
                                    v-for="k in item.keys"
                                    :key="k"
                                    class="px-2 py-0.5 rounded-md bg-ink-100 dark:bg-ink-800 border border-ink-200 dark:border-ink-700 font-mono text-[10px] text-ink-600 dark:text-ink-300 shadow-xs"
                                >
                                    {{ k }}
                                </kbd>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- Footer -->
            <div class="px-6 py-3.5 bg-ink-50 dark:bg-ink-950/50 border-t border-ink-200 dark:border-ink-800 flex items-center justify-end">
                <button
                    @click="emit('close')"
                    class="px-4 py-1.5 rounded-lg bg-ink-100 dark:bg-ink-800 hover:bg-ink-200 dark:hover:bg-ink-700 text-xs font-ui font-medium text-ink-700 dark:text-ink-300 transition-colors"
                >
                    Got it
                </button>
            </div>
        </div>
    </div>
</template>
