<script setup lang="ts">
import { useToast } from "@/composable/useToast";
import { CheckCircle2, AlertCircle, Info, AlertTriangle, X } from "lucide-vue-next";

const { toasts, removeToast } = useToast();
</script>

<template>
    <div
        aria-live="polite"
        class="fixed bottom-5 right-5 z-50 flex flex-col gap-2.5 max-w-sm w-full pointer-events-none"
    >
        <TransitionGroup
            enter-active-class="transition-all duration-300 ease-out"
            enter-from-class="opacity-0 translate-y-4 scale-95"
            enter-to-class="opacity-100 translate-y-0 scale-100"
            leave-active-class="transition-all duration-200 ease-in"
            leave-from-class="opacity-100 scale-100"
            leave-to-class="opacity-0 translate-x-4 scale-95"
        >
            <div
                v-for="toast in toasts"
                :key="toast.id"
                class="pointer-events-auto flex items-start gap-3 p-4 rounded-2xl shadow-xl border backdrop-blur-md transition-all"
                :class="[
                    toast.type === 'success'
                        ? 'bg-white/95 dark:bg-ink-900/95 border-emerald-500/40 text-emerald-900 dark:text-emerald-100'
                        : toast.type === 'error'
                        ? 'bg-white/95 dark:bg-ink-900/95 border-rose-500/40 text-rose-900 dark:text-rose-100'
                        : toast.type === 'warning'
                        ? 'bg-white/95 dark:bg-ink-900/95 border-amber-500/40 text-amber-900 dark:text-amber-100'
                        : 'bg-white/95 dark:bg-ink-900/95 border-sky-500/40 text-sky-900 dark:text-sky-100'
                ]"
            >
                <!-- Icon -->
                <div class="shrink-0 mt-0.5">
                    <CheckCircle2 v-if="toast.type === 'success'" :size="18" class="text-emerald-500" />
                    <AlertCircle v-else-if="toast.type === 'error'" :size="18" class="text-rose-500" />
                    <AlertTriangle v-else-if="toast.type === 'warning'" :size="18" class="text-amber-500" />
                    <Info v-else :size="18" class="text-sky-500" />
                </div>

                <!-- Text -->
                <div class="flex-1 min-w-0 font-ui">
                    <p class="text-xs font-semibold leading-tight text-ink-900 dark:text-ink-50">
                        {{ toast.title }}
                    </p>
                    <p v-if="toast.description" class="text-[11px] text-ink-500 dark:text-ink-400 mt-0.5 leading-snug">
                        {{ toast.description }}
                    </p>
                </div>

                <!-- Close button -->
                <button
                    @click="removeToast(toast.id)"
                    class="shrink-0 p-1 text-ink-400 hover:text-ink-700 dark:hover:text-ink-200 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                >
                    <X :size="14" />
                </button>
            </div>
        </TransitionGroup>
    </div>
</template>
