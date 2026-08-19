<script setup lang="ts">
import { onMounted, ref, computed } from "vue";
import { useRoute, RouterLink } from "vue-router";
import { useNotesStore } from "@/store/notes";
import type { Note } from "@/store/types/interface";
import {
    Lock,
    KeyRound,
    Clock,
    Calendar,
    Eye,
    Printer,
    Sun,
    Moon,
    FileText,
    ArrowLeft,
    Sparkles,
    BookOpen,
    Loader2,
    AlertCircle,
    Check,
} from "lucide-vue-next";

const route = useRoute();
const store = useNotesStore();

const slug = route.params.slug as string;
const note = ref<Note | null>(null);
const isLoading = ref(true);
const isProtected = ref(false);
const passwordInput = ref("");
const passwordError = ref("");
const isVerifying = ref(false);

const isDark = ref(
    localStorage.getItem("theme") === "dark" ||
    (!("theme" in localStorage) && window.matchMedia("(prefers-color-scheme: dark)").matches)
);

function toggleTheme() {
    isDark.value = !isDark.value;
    if (isDark.value) {
        document.documentElement.classList.add("dark");
        localStorage.setItem("theme", "dark");
    } else {
        document.documentElement.classList.remove("dark");
        localStorage.setItem("theme", "light");
    }
}

onMounted(async () => {
    // Apply initial theme
    if (isDark.value) {
        document.documentElement.classList.add("dark");
    } else {
        document.documentElement.classList.remove("dark");
    }

    try {
        const res = await store.fetchPublicNote(slug);
        if (res.isProtected) {
            isProtected.value = true;
            note.value = res;
        } else {
            note.value = res;
            isProtected.value = false;
        }
    } catch (err: any) {
        note.value = null;
    } finally {
        isLoading.value = false;
    }
});

async function handleUnlock() {
    if (!passwordInput.value.trim()) return;
    isVerifying.value = true;
    passwordError.value = "";
    try {
        const res = await store.verifyPublicPassword(slug, passwordInput.value.trim());
        note.value = res;
        isProtected.value = false;
    } catch (err: any) {
        passwordError.value = err.response?.data?.error || "Incorrect password. Please try again.";
    } finally {
        isVerifying.value = false;
    }
}

// ── Parse Content into HTML/Text ──────────────────────────────────────────
const renderedHtml = computed(() => {
    if (!note.value?.content) return "";
    try {
        const doc = JSON.parse(note.value.content);

        function renderNode(node: any): string {
            if (!node) return "";
            if (node.type === "text") {
                let text = (node.text || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
                if (node.marks) {
                    for (const mark of node.marks) {
                        if (mark.type === "bold") text = `<strong>${text}</strong>`;
                        if (mark.type === "italic") text = `<em>${text}</em>`;
                        if (mark.type === "strike") text = `<del>${text}</del>`;
                        if (mark.type === "underline") text = `<u>${text}</u>`;
                        if (mark.type === "code") text = `<code class="px-1.5 py-0.5 rounded bg-ink-100 dark:bg-ink-800 text-amber-600 dark:text-amber-400 font-mono text-xs">${text}</code>`;
                        if (mark.type === "link") text = `<a href="${mark.attrs?.href || '#'}" target="_blank" rel="noopener" class="text-amber-500 hover:underline">${text}</a>`;
                        if (mark.type === "textStyle" && mark.attrs?.color) text = `<span style="color: ${mark.attrs.color}">${text}</span>`;
                        if (mark.type === "highlight") text = `<mark class="bg-amber-200 dark:bg-amber-900/60 px-1 rounded">${text}</mark>`;
                    }
                }
                return text;
            }

            const inner = (node.content || []).map(renderNode).join("");

            switch (node.type) {
                case "paragraph":
                    return `<p class="mb-4 leading-relaxed text-ink-800 dark:text-ink-200">${inner || "<br/>"}</p>`;
                case "heading": {
                    const level = node.attrs?.level || 1;
                    if (level === 1) return `<h1 class="text-2xl sm:text-3xl font-display font-bold text-ink-950 dark:text-white mt-8 mb-4">${inner}</h1>`;
                    if (level === 2) return `<h2 class="text-xl sm:text-2xl font-display font-semibold text-ink-900 dark:text-ink-100 mt-6 mb-3">${inner}</h2>`;
                    return `<h3 class="text-lg font-display font-semibold text-ink-900 dark:text-ink-100 mt-5 mb-2">${inner}</h3>`;
                }
                case "bulletList":
                    return `<ul class="list-disc list-inside space-y-1.5 mb-4 text-ink-800 dark:text-ink-200">${inner}</ul>`;
                case "orderedList":
                    return `<ol class="list-decimal list-inside space-y-1.5 mb-4 text-ink-800 dark:text-ink-200">${inner}</ol>`;
                case "listItem":
                    return `<li class="leading-relaxed">${inner}</li>`;
                case "blockquote":
                    return `<blockquote class="border-l-4 border-amber-500 pl-4 py-1 my-4 italic text-ink-600 dark:text-ink-400 bg-amber-50/30 dark:bg-amber-950/10 rounded-r-lg">${inner}</blockquote>`;
                case "codeBlock": {
                    const lang = node.attrs?.language || "";
                    return `<pre class="p-4 rounded-xl bg-ink-950 text-ink-50 font-mono text-xs my-4 overflow-x-auto border border-ink-800"><code>${inner}</code></pre>`;
                }
                case "horizontalRule":
                    return `<hr class="my-8 border-ink-200 dark:border-ink-800" />`;
                case "image": {
                    const src = node.attrs?.src || "";
                    const alt = node.attrs?.alt || "Image";
                    return `<figure class="my-6"><img src="${src}" alt="${alt}" class="rounded-xl max-w-full h-auto mx-auto shadow-md" /></figure>`;
                }
                default:
                    return inner;
            }
        }

        return (doc.content || []).map(renderNode).join("");
    } catch {
        return `<p class="whitespace-pre-wrap leading-relaxed text-ink-800 dark:text-ink-200">${note.value.content}</p>`;
    }
});

const wordCount = computed(() => {
    if (!note.value?.content) return 0;
    try {
        const doc = JSON.parse(note.value.content);
        function walk(nodes: any[]): string {
            return nodes.reduce((acc: string[], n) => {
                if (n.type === "text") acc.push(n.text ?? "");
                else if (n.content) acc.push(walk(n.content));
                return acc;
            }, []).join(" ");
        }
        return walk(doc.content ?? []).trim().split(/\s+/).filter(Boolean).length;
    } catch {
        return note.value.content.trim().split(/\s+/).filter(Boolean).length;
    }
});

const readingTime = computed(() => {
    const mins = Math.ceil(wordCount.value / 200);
    return mins <= 1 ? "1 min read" : `${mins} min read`;
});

function printNote() {
    window.print();
}
</script>

<template>
    <div class="min-h-screen bg-ink-50/50 dark:bg-ink-950 text-ink-900 dark:text-ink-100 flex flex-col font-body transition-colors">
        <!-- Top Navbar -->
        <header class="border-b border-ink-200/80 dark:border-ink-800 bg-white/80 dark:bg-ink-900/80 backdrop-blur-md sticky top-0 z-40 px-4 sm:px-8 py-3.5 flex items-center justify-between">
            <div class="flex items-center gap-2.5">
                <div class="w-8 h-8 rounded-lg bg-amber-500 flex items-center justify-center text-white font-bold font-display shadow-xs">
                    C
                </div>
                <span class="font-display font-bold text-base tracking-tight text-ink-950 dark:text-white">
                    Caddo <span class="text-xs font-ui font-normal text-ink-400 dark:text-ink-500">Reader</span>
                </span>
            </div>

            <div class="flex items-center gap-2">
                <button
                    @click="toggleTheme"
                    class="p-2 rounded-xl hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-500 dark:text-ink-400 transition-colors cursor-pointer"
                    title="Toggle Theme"
                >
                    <Sun v-if="isDark" :size="16" />
                    <Moon v-else :size="16" />
                </button>

                <button
                    v-if="!isProtected && note"
                    @click="printNote"
                    class="p-2 rounded-xl hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-500 dark:text-ink-400 transition-colors cursor-pointer hidden sm:flex items-center"
                    title="Print Note"
                >
                    <Printer :size="16" />
                </button>

                <RouterLink
                    to="/auth/login"
                    class="px-3.5 py-1.5 rounded-xl bg-ink-900 dark:bg-amber-500 hover:bg-ink-800 dark:hover:bg-amber-400 text-white dark:text-ink-950 text-xs font-ui font-semibold shadow-xs transition-colors"
                >
                    Start Writing
                </RouterLink>
            </div>
        </header>

        <!-- Main Body -->
        <main class="flex-1 flex flex-col justify-center max-w-3xl w-full mx-auto px-4 sm:px-8 py-8 sm:py-16">
            <!-- Loading State -->
            <div v-if="isLoading" class="flex flex-col items-center justify-center py-24 space-y-4">
                <Loader2 :size="32" class="animate-spin text-amber-500" />
                <p class="text-xs font-ui text-ink-400">Loading published note…</p>
            </div>

            <!-- 404 / Not Found State -->
            <div v-else-if="!note" class="text-center py-20 space-y-4">
                <div class="w-14 h-14 mx-auto rounded-2xl bg-amber-500/10 flex items-center justify-center text-amber-500">
                    <FileText :size="24" />
                </div>
                <h1 class="text-2xl font-display font-bold text-ink-900 dark:text-ink-100">
                    Note Not Found or Link Expired
                </h1>
                <p class="text-sm font-ui text-ink-500 dark:text-ink-400 max-w-md mx-auto">
                    The note you are looking for might have been made private, deleted, or the link has expired.
                </p>
                <RouterLink
                    to="/"
                    class="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-amber-500 hover:bg-amber-600 text-white font-ui font-semibold text-xs transition-colors"
                >
                    <ArrowLeft :size="14" />
                    <span>Return to Caddo Home</span>
                </RouterLink>
            </div>

            <!-- Password Protected Lock Screen -->
            <div v-else-if="isProtected" class="max-w-md mx-auto w-full py-12 animate-fade-in">
                <div class="bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-800 rounded-2xl p-8 shadow-xl text-center space-y-5">
                    <div class="w-14 h-14 mx-auto rounded-2xl bg-amber-500/10 flex items-center justify-center text-amber-500 shadow-inner">
                        <Lock :size="24" />
                    </div>

                    <div>
                        <h2 class="text-xl font-display font-bold text-ink-900 dark:text-ink-100">
                            Password Protected Note
                        </h2>
                        <p class="text-xs font-ui text-ink-500 dark:text-ink-400 mt-1">
                            Please enter the access password provided by the author to view this document.
                        </p>
                    </div>

                    <div v-if="passwordError" class="p-3 rounded-xl bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-800/50 flex items-center gap-2 text-xs text-red-600 dark:text-red-400 font-ui text-left">
                        <AlertCircle :size="14" class="shrink-0" />
                        <span>{{ passwordError }}</span>
                    </div>

                    <form @submit.prevent="handleUnlock" class="space-y-3">
                        <div class="relative">
                            <KeyRound :size="15" class="absolute left-3.5 top-1/2 -translate-y-1/2 text-ink-400" />
                            <input
                                v-model="passwordInput"
                                type="password"
                                autofocus
                                placeholder="Enter document password..."
                                class="w-full pl-10 pr-4 py-2.5 rounded-xl border border-ink-200 dark:border-ink-700 bg-ink-50 dark:bg-ink-950 text-sm text-ink-900 dark:text-ink-100 outline-none focus:ring-2 focus:ring-amber-500 font-ui"
                            />
                        </div>

                        <button
                            type="submit"
                            :disabled="isVerifying || !passwordInput.trim()"
                            class="w-full py-2.5 rounded-xl bg-amber-500 hover:bg-amber-600 text-white font-ui font-semibold text-sm flex items-center justify-center gap-2 shadow-sm transition-all cursor-pointer disabled:opacity-50"
                        >
                            <Loader2 v-if="isVerifying" :size="16" class="animate-spin" />
                            <span>Unlock & Read</span>
                        </button>
                    </form>
                </div>
            </div>

            <!-- Published Note Content View -->
            <article v-else class="space-y-8 animate-fade-in">
                <!-- Note Header Meta -->
                <div class="border-b border-ink-200/80 dark:border-ink-800/80 pb-6 space-y-4">
                    <h1 class="text-3xl sm:text-4xl font-display font-extrabold text-ink-950 dark:text-white leading-tight">
                        {{ note.title || "Untitled" }}
                    </h1>

                    <!-- Author and Meta row -->
                    <div class="flex items-center justify-between flex-wrap gap-4 text-xs font-ui text-ink-500 dark:text-ink-400">
                        <div class="flex items-center gap-3">
                            <div class="w-8 h-8 rounded-full bg-amber-500 text-white font-bold flex items-center justify-center shrink-0 shadow-xs">
                                <img
                                    v-if="note.author?.avatar"
                                    :src="note.author.avatar"
                                    :alt="note.author.name"
                                    class="w-full h-full rounded-full object-cover"
                                />
                                <span v-else>{{ (note.author?.name || 'A').charAt(0).toUpperCase() }}</span>
                            </div>
                            <div>
                                <p class="font-medium text-ink-800 dark:text-ink-200">
                                    {{ note.author?.name || "Author" }}
                                </p>
                                <div class="flex items-center gap-2 text-[11px] text-ink-400">
                                    <span>{{ new Date(note.updatedAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' }) }}</span>
                                    <span>•</span>
                                    <span>{{ readingTime }}</span>
                                    <span>•</span>
                                    <span>{{ wordCount }} words</span>
                                </div>
                            </div>
                        </div>

                        <div class="flex items-center gap-3 text-ink-400 text-xs">
                            <span v-if="note.viewCount !== undefined" class="flex items-center gap-1">
                                <Eye :size="13" />
                                {{ note.viewCount }} views
                            </span>
                        </div>
                    </div>
                </div>

                <!-- Rendered Note Content -->
                <div class="prose dark:prose-invert max-w-none text-base leading-relaxed" v-html="renderedHtml" />
            </article>
        </main>

        <!-- Footer -->
        <footer class="border-t border-ink-200/80 dark:border-ink-800 py-6 text-center text-xs font-ui text-ink-400 dark:text-ink-600 bg-white/50 dark:bg-ink-900/50">
            <p>Published with <span class="font-semibold text-ink-700 dark:text-ink-300">Caddo Note Tracking</span></p>
        </footer>
    </div>
</template>
