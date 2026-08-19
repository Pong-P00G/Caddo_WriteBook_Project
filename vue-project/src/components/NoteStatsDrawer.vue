<script setup lang="ts">
import { computed } from "vue";
import {
    X,
    BarChart3,
    Clock,
    Mic,
    FileText,
    AlignLeft,
    Hash,
    ListTree,
    Calendar,
    Sparkles,
} from "lucide-vue-next";

const props = defineProps<{
    isOpen: boolean;
    noteTitle: string;
    noteContent: string;
    createdAt?: string;
    updatedAt?: string;
}>();

const emit = defineEmits<{
    (e: "close"): void;
}>();

// ── Document Analysis ──────────────────────────────────────────────────
interface HeadingItem {
    level: number;
    text: string;
}

const parsedStats = computed(() => {
    let plain = "";
    const headings: HeadingItem[] = [];
    let paragraphCount = 0;

    if (!props.noteContent) {
        return {
            words: 0,
            charsWithSpaces: 0,
            charsNoSpaces: 0,
            paragraphs: 0,
            sentences: 0,
            readingTime: "< 1 min",
            speakingTime: "< 1 min",
            headings: [],
        };
    }

    try {
        const doc = JSON.parse(props.noteContent);

        function walk(nodes: any[]) {
            for (const n of nodes) {
                if (n.type === "text") {
                    plain += (n.text || "") + " ";
                } else if (n.type === "paragraph") {
                    paragraphCount++;
                    if (n.content) walk(n.content);
                } else if (n.type === "heading") {
                    let hText = "";
                    if (n.content) {
                        for (const child of n.content) {
                            if (child.type === "text") hText += child.text || "";
                        }
                    }
                    if (hText.trim()) {
                        headings.push({
                            level: n.attrs?.level || 1,
                            text: hText.trim(),
                        });
                    }
                    if (n.content) walk(n.content);
                } else if (n.content) {
                    walk(n.content);
                }
            }
        }

        walk(doc.content || []);
    } catch {
        plain = props.noteContent;
        paragraphCount = props.noteContent.split(/\n\n+/).filter(Boolean).length;
    }

    const trimmed = plain.trim();
    const words = trimmed ? trimmed.split(/\s+/).filter(Boolean).length : 0;
    const charsWithSpaces = trimmed.length;
    const charsNoSpaces = trimmed.replace(/\s+/g, "").length;
    const sentences = trimmed ? trimmed.split(/[.!?]+/).filter(Boolean).length : 0;

    const readMins = Math.ceil(words / 200);
    const speakMins = Math.ceil(words / 130);

    return {
        words,
        charsWithSpaces,
        charsNoSpaces,
        paragraphs: Math.max(paragraphCount, 1),
        sentences: Math.max(sentences, 1),
        readingTime: readMins <= 1 ? "1 min read" : `${readMins} mins read`,
        speakingTime: speakMins <= 1 ? "1 min" : `${speakMins} mins`,
        headings,
    };
});
</script>

<template>
    <div v-if="isOpen" class="fixed inset-0 z-50 overflow-hidden">
        <!-- Backdrop -->
        <div
            class="absolute inset-0 bg-ink-950/40 backdrop-blur-xs transition-opacity"
            @click="emit('close')"
        />

        <div class="fixed inset-y-0 right-0 max-w-full flex pl-10">
            <div
                class="w-screen max-w-sm bg-white dark:bg-ink-900 border-l border-ink-200 dark:border-ink-800 shadow-2xl flex flex-col animate-slide-left"
            >
                <!-- Header -->
                <div class="px-6 py-4 border-b border-ink-200 dark:border-ink-800 flex items-center justify-between">
                    <div class="flex items-center gap-2.5">
                        <div class="p-2 rounded-xl bg-amber-500/10 text-amber-500">
                            <BarChart3 :size="18" />
                        </div>
                        <div>
                            <h2 class="text-base font-display font-bold text-ink-900 dark:text-ink-50">
                                Note Insights
                            </h2>
                            <p class="text-xs text-ink-500 dark:text-ink-400 font-ui">
                                Statistics & document outline
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

                <!-- Content -->
                <div class="flex-1 overflow-y-auto p-6 space-y-6 font-ui">
                    <!-- Key Counts Metric Grid -->
                    <div class="grid grid-cols-2 gap-3">
                        <div class="p-3.5 rounded-2xl bg-ink-50 dark:bg-ink-950/50 border border-ink-200/80 dark:border-ink-800 text-center">
                            <p class="text-2xl font-display font-bold text-ink-950 dark:text-white">
                                {{ parsedStats.words.toLocaleString() }}
                            </p>
                            <p class="text-[11px] font-medium text-ink-400 dark:text-ink-500 uppercase tracking-wider mt-0.5">
                                Words
                            </p>
                        </div>

                        <div class="p-3.5 rounded-2xl bg-ink-50 dark:bg-ink-950/50 border border-ink-200/80 dark:border-ink-800 text-center">
                            <p class="text-2xl font-display font-bold text-ink-950 dark:text-white">
                                {{ parsedStats.charsNoSpaces.toLocaleString() }}
                            </p>
                            <p class="text-[11px] font-medium text-ink-400 dark:text-ink-500 uppercase tracking-wider mt-0.5">
                                Characters
                            </p>
                        </div>
                    </div>

                    <!-- Reading & Speaking Time -->
                    <div class="p-4 rounded-2xl border border-ink-200/80 dark:border-ink-800 bg-amber-50/20 dark:bg-amber-950/10 space-y-2.5">
                        <div class="flex items-center justify-between text-xs">
                            <div class="flex items-center gap-2 text-ink-600 dark:text-ink-300">
                                <Clock :size="14" class="text-amber-500" />
                                <span>Estimated Reading</span>
                            </div>
                            <span class="font-semibold text-ink-900 dark:text-ink-100">
                                {{ parsedStats.readingTime }}
                            </span>
                        </div>

                        <div class="flex items-center justify-between text-xs">
                            <div class="flex items-center gap-2 text-ink-600 dark:text-ink-300">
                                <Mic :size="14" class="text-amber-500" />
                                <span>Speaking Time</span>
                            </div>
                            <span class="font-semibold text-ink-900 dark:text-ink-100">
                                {{ parsedStats.speakingTime }}
                            </span>
                        </div>
                    </div>

                    <!-- Document Metrics -->
                    <div class="space-y-2.5">
                        <h3 class="text-xs font-semibold text-ink-400 dark:text-ink-500 uppercase tracking-widest">
                            Document Metrics
                        </h3>
                        <div class="p-4 rounded-2xl border border-ink-200/80 dark:border-ink-800 bg-white dark:bg-ink-900 space-y-2 text-xs">
                            <div class="flex items-center justify-between">
                                <span class="text-ink-500 dark:text-ink-400">Characters (with spaces)</span>
                                <span class="font-mono font-medium text-ink-800 dark:text-ink-200">{{ parsedStats.charsWithSpaces }}</span>
                            </div>
                            <div class="flex items-center justify-between">
                                <span class="text-ink-500 dark:text-ink-400">Paragraphs</span>
                                <span class="font-mono font-medium text-ink-800 dark:text-ink-200">{{ parsedStats.paragraphs }}</span>
                            </div>
                            <div class="flex items-center justify-between">
                                <span class="text-ink-500 dark:text-ink-400">Sentences</span>
                                <span class="font-mono font-medium text-ink-800 dark:text-ink-200">{{ parsedStats.sentences }}</span>
                            </div>
                            <div v-if="createdAt" class="flex items-center justify-between pt-1 border-t border-ink-100 dark:border-ink-800">
                                <span class="text-ink-500 dark:text-ink-400">Created</span>
                                <span class="text-ink-800 dark:text-ink-200">{{ new Date(createdAt).toLocaleDateString() }}</span>
                            </div>
                        </div>
                    </div>

                    <!-- Heading Outline (TOC) -->
                    <div class="space-y-2.5">
                        <div class="flex items-center gap-1.5 text-xs font-semibold text-ink-400 dark:text-ink-500 uppercase tracking-widest">
                            <ListTree :size="13" />
                            <span>Document Outline</span>
                        </div>

                        <div v-if="parsedStats.headings.length === 0" class="p-4 rounded-2xl border border-ink-200/80 dark:border-ink-800 bg-ink-50/50 dark:bg-ink-950/30 text-xs text-ink-400 text-center">
                            No headings found. Add H1, H2, or H3 headers in your note to see the table of contents here.
                        </div>

                        <div v-else class="p-3 rounded-2xl border border-ink-200/80 dark:border-ink-800 bg-white dark:bg-ink-900 space-y-1.5">
                            <div
                                v-for="(h, idx) in parsedStats.headings"
                                :key="idx"
                                class="text-xs text-ink-700 dark:text-ink-300 py-1 px-2 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 truncate"
                                :class="{
                                    'font-semibold text-ink-900 dark:text-ink-100': h.level === 1,
                                    'pl-4': h.level === 2,
                                    'pl-7': h.level === 3,
                                }"
                            >
                                {{ h.text }}
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
                        Close
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>
