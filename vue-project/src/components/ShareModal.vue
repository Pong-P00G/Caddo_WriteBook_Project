<script setup lang="ts">
import { ref, watch, computed } from "vue";
import { useNotesStore } from "@/store/notes";
import {
    X,
    Share2,
    Globe,
    Lock,
    Copy,
    Check,
    ExternalLink,
    Eye,
    Loader2,
    Sparkles,
    AlertCircle,
} from "lucide-vue-next";

const props = defineProps<{
    isOpen: boolean;
    noteId: string;
    initialSlug?: string | null;
    initialIsPublic?: boolean;
    initialHasPassword?: boolean;
    viewCount?: number;
}>();

const emit = defineEmits<{
    (e: "close"): void;
}>();

const store = useNotesStore();

const isPublic = ref(false);
const slug = ref("");
const enablePassword = ref(false);
const password = ref("");
const isCopied = ref(false);
const isSaving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");
const views = ref(0);

watch(
    () => props.isOpen,
    (open) => {
        if (open) {
            isPublic.value = props.initialIsPublic ?? false;
            slug.value = props.initialSlug ?? "";
            enablePassword.value = props.initialHasPassword ?? false;
            password.value = "";
            errorMessage.value = "";
            successMessage.value = "";
            views.value = props.viewCount ?? 0;
        }
    },
    { immediate: true }
);

const fullShareUrl = computed(() => {
    if (!slug.value) return "";
    const origin = window.location.origin;
    return `${origin}/share/${slug.value}`;
});

async function handleTogglePublic() {
    isPublic.value = !isPublic.value;
    await saveSettings();
}

async function saveSettings() {
    isSaving.value = true;
    errorMessage.value = "";
    successMessage.value = "";

    try {
        const payload: {
            isPublic: boolean;
            slug?: string;
            password?: string | null;
        } = {
            isPublic: isPublic.value,
        };

        if (slug.value.trim()) {
            payload.slug = slug.value.trim().toLowerCase();
        }

        if (enablePassword.value && password.value.trim()) {
            payload.password = password.value.trim();
        } else if (!enablePassword.value) {
            payload.password = null;
        }

        const res = await store.updateShareSettings(props.noteId, payload);
        slug.value = res.slug;
        isPublic.value = res.isPublic;
        views.value = res.viewCount;
        successMessage.value = isPublic.value ? "Sharing settings saved!" : "Public access disabled";
        setTimeout(() => {
            successMessage.value = "";
        }, 3000);
    } catch (err: any) {
        errorMessage.value = err.response?.data?.error || "Failed to update sharing settings.";
    } finally {
        isSaving.value = false;
    }
}

async function copyLink() {
    if (!fullShareUrl.value) return;
    try {
        await navigator.clipboard.writeText(fullShareUrl.value);
        isCopied.value = true;
        setTimeout(() => {
            isCopied.value = false;
        }, 2000);
    } catch {
        // Fallback for older browsers
        const input = document.createElement("input");
        input.value = fullShareUrl.value;
        document.body.appendChild(input);
        input.select();
        document.execCommand("copy");
        document.body.removeChild(input);
        isCopied.value = true;
        setTimeout(() => {
            isCopied.value = false;
        }, 2000);
    }
}
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
            <div class="px-6 py-4.5 border-b border-ink-200 dark:border-ink-800 flex items-center justify-between">
                <div class="flex items-center gap-2.5">
                    <div class="p-2 rounded-xl bg-amber-500/10 text-amber-500">
                        <Share2 :size="18" />
                    </div>
                    <div>
                        <h2 class="text-base font-display font-bold text-ink-900 dark:text-ink-50">
                            Share Note to the Web
                        </h2>
                        <p class="text-xs text-ink-500 dark:text-ink-400 font-ui">
                            Publish a clean read-only version of this note
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
            <div class="p-6 space-y-5">
                <!-- Alert Messages -->
                <div
                    v-if="errorMessage"
                    class="p-3 rounded-xl bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-800/50 flex items-center gap-2 text-xs text-red-600 dark:text-red-400 font-ui"
                >
                    <AlertCircle :size="14" class="shrink-0" />
                    <span>{{ errorMessage }}</span>
                </div>

                <div
                    v-if="successMessage"
                    class="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-200 dark:border-emerald-800/50 flex items-center gap-2 text-xs text-emerald-600 dark:text-emerald-400 font-ui"
                >
                    <Check :size="14" class="shrink-0" />
                    <span>{{ successMessage }}</span>
                </div>

                <!-- Main Public Switch -->
                <div class="flex items-center justify-between p-4 rounded-xl border border-ink-200/80 dark:border-ink-800 bg-ink-50/50 dark:bg-ink-950/40">
                    <div class="flex items-center gap-3">
                        <div
                            class="p-2 rounded-lg"
                            :class="isPublic ? 'bg-amber-500/10 text-amber-500' : 'bg-ink-200 dark:bg-ink-800 text-ink-400'"
                        >
                            <Globe :size="18" />
                        </div>
                        <div>
                            <p class="text-sm font-medium text-ink-900 dark:text-ink-100 font-ui">
                                Public Link Access
                            </p>
                            <p class="text-xs text-ink-500 dark:text-ink-400 font-ui">
                                {{ isPublic ? "Anyone with the link can view this note" : "Only you can see this note" }}
                            </p>
                        </div>
                    </div>

                    <!-- Switch -->
                    <button
                        @click="handleTogglePublic"
                        :disabled="isSaving"
                        class="relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none"
                        :class="isPublic ? 'bg-amber-500' : 'bg-ink-300 dark:bg-ink-700'"
                    >
                        <span
                            class="pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow-sm ring-0 transition duration-200 ease-in-out"
                            :class="isPublic ? 'translate-x-5' : 'translate-x-0'"
                        />
                    </button>
                </div>

                <!-- Sharing Controls (Shown when Public is Enabled) -->
                <div v-if="isPublic" class="space-y-4 pt-1 animate-fade-in">
                    <!-- Copy Link Input -->
                    <div>
                        <label class="block text-xs font-ui font-medium text-ink-700 dark:text-ink-300 mb-1.5">
                            Shareable Link
                        </label>
                        <div class="flex items-center gap-2">
                            <input
                                :value="fullShareUrl"
                                readonly
                                type="text"
                                class="flex-1 px-3.5 py-2 rounded-xl border border-ink-200 dark:border-ink-700 bg-ink-50 dark:bg-ink-950 text-xs font-mono text-ink-800 dark:text-ink-200 select-all outline-none"
                            />
                            <button
                                @click="copyLink"
                                class="px-3.5 py-2 rounded-xl bg-amber-500 hover:bg-amber-600 text-white font-ui font-semibold text-xs flex items-center gap-1.5 shadow-sm transition-colors cursor-pointer"
                            >
                                <Check v-if="isCopied" :size="13" />
                                <Copy v-else :size="13" />
                                <span>{{ isCopied ? "Copied!" : "Copy" }}</span>
                            </button>
                            <a
                                :href="fullShareUrl"
                                target="_blank"
                                rel="noopener noreferrer"
                                class="p-2 rounded-xl border border-ink-200 dark:border-ink-700 text-ink-500 hover:text-ink-800 dark:hover:text-ink-200 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                                title="Open preview in new tab"
                            >
                                <ExternalLink :size="15" />
                            </a>
                        </div>
                    </div>

                    <!-- Custom Slug Customizer -->
                    <div>
                        <label class="block text-xs font-ui font-medium text-ink-700 dark:text-ink-300 mb-1.5">
                            Custom Link Address (Slug)
                        </label>
                        <div class="flex items-center gap-2">
                            <div class="flex-1 flex items-center px-3 py-1.5 rounded-xl border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-900 text-xs font-mono">
                                <span class="text-ink-400 select-none">/share/</span>
                                <input
                                    v-model="slug"
                                    type="text"
                                    placeholder="custom-link-name"
                                    class="flex-1 bg-transparent text-ink-900 dark:text-ink-100 outline-none ml-0.5"
                                />
                            </div>
                            <button
                                @click="saveSettings"
                                :disabled="isSaving"
                                class="px-3 py-2 rounded-xl border border-ink-200 dark:border-ink-700 hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-700 dark:text-ink-300 text-xs font-ui transition-colors cursor-pointer flex items-center gap-1"
                            >
                                <Loader2 v-if="isSaving" :size="12" class="animate-spin" />
                                <span>Update</span>
                            </button>
                        </div>
                    </div>

                    <!-- Password Protection Accordion -->
                    <div class="pt-2 border-t border-ink-100 dark:border-ink-800/80 space-y-3">
                        <div class="flex items-center justify-between">
                            <div class="flex items-center gap-2">
                                <Lock :size="14" class="text-ink-400" />
                                <span class="text-xs font-ui font-medium text-ink-700 dark:text-ink-300">
                                    Password Protection
                                </span>
                            </div>
                            <button
                                @click="enablePassword = !enablePassword; if (!enablePassword) saveSettings();"
                                class="text-xs text-amber-600 dark:text-amber-400 font-ui hover:underline cursor-pointer"
                            >
                                {{ enablePassword ? "Remove password" : "Set password" }}
                            </button>
                        </div>

                        <div v-if="enablePassword" class="flex items-center gap-2 animate-fade-in">
                            <input
                                v-model="password"
                                type="password"
                                placeholder="Enter access password..."
                                class="flex-1 px-3 py-1.5 rounded-xl border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-900 text-xs text-ink-900 dark:text-ink-100 outline-none focus:ring-2 focus:ring-amber-500 font-ui"
                            />
                            <button
                                @click="saveSettings"
                                :disabled="isSaving || !password.trim()"
                                class="px-3 py-1.5 rounded-xl bg-ink-900 dark:bg-amber-500 text-white dark:text-ink-950 text-xs font-ui font-medium hover:opacity-90 disabled:opacity-50"
                            >
                                Save Password
                            </button>
                        </div>
                    </div>

                    <!-- View Statistics -->
                    <div class="flex items-center gap-1.5 text-xs text-ink-400 font-ui pt-1">
                        <Eye :size="13" />
                        <span>Viewed {{ views }} time{{ views !== 1 ? 's' : '' }} by readers</span>
                    </div>
                </div>
            </div>

            <!-- Footer -->
            <div class="px-6 py-3.5 bg-ink-50 dark:bg-ink-950/50 border-t border-ink-200 dark:border-ink-800 flex items-center justify-end">
                <button
                    @click="emit('close')"
                    class="px-4 py-1.5 rounded-lg bg-ink-100 dark:bg-ink-800 hover:bg-ink-200 dark:hover:bg-ink-700 text-xs font-ui font-medium text-ink-700 dark:text-ink-300 transition-colors"
                >
                    Done
                </button>
            </div>
        </div>
    </div>
</template>
