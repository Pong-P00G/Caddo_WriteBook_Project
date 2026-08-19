<script setup lang="ts">
import { ref } from "vue";
import { useRouter } from "vue-router";
import { useNotesStore } from "@/store/notes";
import {
    X,
    Sparkles,
    Calendar,
    Users,
    FolderKanban,
    BookOpen,
    GraduationCap,
    RotateCcw,
    ArrowRight,
} from "lucide-vue-next";

const props = defineProps<{
    isOpen: boolean;
}>();

const emit = defineEmits<{
    (e: "close"): void;
    (e: "selectTemplate", template: { title: string; content: string }): void;
}>();

const router = useRouter();
const store = useNotesStore();
const selectedCategory = ref<string>("all");
const isCreating = ref(false);

interface NoteTemplate {
    id: string;
    title: string;
    description: string;
    category: "work" | "personal" | "study" | "dev";
    icon: any;
    color: string;
    defaultTitle: string;
    content: string; // Tiptap JSON or Markdown compatible structure
}

const templates: NoteTemplate[] = [
    {
        id: "daily-journal",
        title: "Daily Journal & Reflection",
        description: "Log today's priorities, gratitude, highlights, and quick reflections.",
        category: "personal",
        icon: Calendar,
        color: "amber",
        defaultTitle: `Daily Journal — ${new Date().toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })}`,
        content: JSON.stringify({
            type: "doc",
            content: [
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "🎯 Top 3 Priorities for Today" }] },
                {
                    type: "bulletList",
                    content: [
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Priority 1" }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Priority 2" }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Priority 3" }] }] },
                    ]
                },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "✨ Gratitude & Highlights" }] },
                { type: "paragraph", content: [{ type: "text", text: "What went well today? What am I grateful for?" }] },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "📝 Notes & Thoughts" }] },
                { type: "paragraph", content: [{ type: "text", text: "Write freely here..." }] }
            ]
        })
    },
    {
        id: "meeting-notes",
        title: "Meeting Minutes & Action Items",
        description: "Capture attendees, agenda topics, key decisions, and assigned follow-ups.",
        category: "work",
        icon: Users,
        color: "indigo",
        defaultTitle: "Meeting Notes: [Topic]",
        content: JSON.stringify({
            type: "doc",
            content: [
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "👥 Meeting Overview" }] },
                {
                    type: "bulletList",
                    content: [
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Date & Time: " + new Date().toLocaleString() }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Attendees: " }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Goal: " }] }] },
                    ]
                },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "📋 Key Discussions" }] },
                { type: "paragraph", content: [{ type: "text", text: "Summary of discussion points and insights..." }] },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "✅ Action Items" }] },
                {
                    type: "bulletList",
                    content: [
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "[ ] Task 1 — Owner: @name (Due: Date)" }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "[ ] Task 2 — Owner: @name (Due: Date)" }] }] },
                    ]
                }
            ]
        })
    },
    {
        id: "project-spec",
        title: "Project Specification / ADR",
        description: "Define scope, requirements, architecture decisions, and timeline.",
        category: "dev",
        icon: FolderKanban,
        color: "emerald",
        defaultTitle: "Spec: [Project or Feature Name]",
        content: JSON.stringify({
            type: "doc",
            content: [
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "📌 Problem Statement & Context" }] },
                { type: "paragraph", content: [{ type: "text", text: "What problem are we solving and why is it important?" }] },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "💡 Proposed Solution" }] },
                { type: "paragraph", content: [{ type: "text", text: "High-level overview of the architectural approach." }] },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "⚙️ Technical Requirements" }] },
                {
                    type: "bulletList",
                    content: [
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "API Endpoints & Contracts" }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Database Schema Changes" }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Frontend Components & States" }] }] },
                    ]
                },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "🚀 Milestones & Rollout" }] },
                { type: "paragraph", content: [{ type: "text", text: "Phase 1: Implementation | Phase 2: Testing & QA | Phase 3: Launch" }] }
            ]
        })
    },
    {
        id: "book-summary",
        title: "Book & Article Summary",
        description: "Record key takeaways, memorable quotes, and actionable concepts.",
        category: "study",
        icon: BookOpen,
        color: "rose",
        defaultTitle: "Summary: [Book Title] by [Author]",
        content: JSON.stringify({
            type: "doc",
            content: [
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "📖 Book Details" }] },
                {
                    type: "bulletList",
                    content: [
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Author: " }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Genre / Topic: " }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Rating: ★★★★★" }] }] },
                    ]
                },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "🧠 Core Thesis & 3 Big Ideas" }] },
                { type: "paragraph", content: [{ type: "text", text: "1. Key Idea 1\n2. Key Idea 2\n3. Key Idea 3" }] },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "💬 Memorable Quotes" }] },
                { type: "paragraph", content: [{ type: "text", text: "“Add inspiring quote here...”" }] },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "🎯 Practical Action Items" }] },
                { type: "paragraph", content: [{ type: "text", text: "How will I apply this book's teachings in my life/work?" }] }
            ]
        })
    },
    {
        id: "cornell-notes",
        title: "Cornell Method Study Notes",
        description: "Structured learning format with cues/questions, detailed notes, and summary.",
        category: "study",
        icon: GraduationCap,
        color: "sky",
        defaultTitle: "Lecture / Topic: [Subject]",
        content: JSON.stringify({
            type: "doc",
            content: [
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "🔍 Keywords & Recall Cues" }] },
                { type: "paragraph", content: [{ type: "text", text: "Key term 1 • Question prompt • Main concept" }] },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "📝 Detailed Lecture Notes" }] },
                {
                    type: "bulletList",
                    content: [
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Main point A and supporting evidence" }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Formulas, theorems, definitions" }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Diagram / flow explanations" }] }] },
                    ]
                },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "💡 2-Minute Summary" }] },
                { type: "paragraph", content: [{ type: "text", text: "In summary, the most critical takeaway is..." }] }
            ]
        })
    },
    {
        id: "sprint-retro",
        title: "Sprint Retrospective",
        description: "What went well, what could be improved, and action items for next sprint.",
        category: "work",
        icon: RotateCcw,
        color: "violet",
        defaultTitle: "Sprint Retrospective — Sprint [X]",
        content: JSON.stringify({
            type: "doc",
            content: [
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "🎉 What Went Well" }] },
                {
                    type: "bulletList",
                    content: [
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Great teamwork on the release" }] }] },
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Fast bug turnaround" }] }] },
                    ]
                },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "🚧 What Could Be Improved" }] },
                {
                    type: "bulletList",
                    content: [
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "Requirement clarity before kickoff" }] }] },
                    ]
                },
                { type: "heading", attrs: { level: 2 }, content: [{ type: "text", text: "🚀 Action Commitments" }] },
                {
                    type: "bulletList",
                    content: [
                        { type: "listItem", content: [{ type: "paragraph", content: [{ type: "text", text: "[ ] Standardize PR review templates" }] }] },
                    ]
                }
            ]
        })
    }
];

const filteredTemplates = ref(templates);

function setCategory(cat: string) {
    selectedCategory.value = cat;
    if (cat === "all") {
        filteredTemplates.value = templates;
    } else {
        filteredTemplates.value = templates.filter((t) => t.category === cat);
    }
}

async function useTemplate(template: NoteTemplate) {
    isCreating.value = true;
    try {
        const note = await store.createNote({
            title: template.defaultTitle,
            content: template.content,
            color: template.color,
        });
        emit("close");
        router.push(`/app/notes/${note._id}`);
    } finally {
        isCreating.value = false;
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
            class="bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-800 rounded-2xl w-full max-w-3xl shadow-2xl overflow-hidden flex flex-col max-h-[85vh] animate-scale-up"
        >
            <!-- Header -->
            <div class="px-6 py-5 border-b border-ink-200 dark:border-ink-800 flex items-center justify-between">
                <div class="flex items-center gap-2.5">
                    <div class="p-2 rounded-xl bg-amber-500/10 text-amber-500">
                        <Sparkles :size="20" />
                    </div>
                    <div>
                        <h2 class="text-lg font-display font-bold text-ink-900 dark:text-ink-50">
                            Starter Templates
                        </h2>
                        <p class="text-xs text-ink-500 dark:text-ink-400 font-ui">
                            Jumpstart your thoughts with crafted formats
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

            <!-- Categories tab -->
            <div class="px-6 pt-4 pb-2 border-b border-ink-100 dark:border-ink-800/80 flex items-center gap-1.5 overflow-x-auto">
                <button
                    v-for="cat in [
                        { id: 'all', label: 'All Templates' },
                        { id: 'personal', label: 'Personal & Journal' },
                        { id: 'work', label: 'Work & Projects' },
                        { id: 'study', label: 'Study & Learning' },
                        { id: 'dev', label: 'Tech & Architecture' },
                    ]"
                    :key="cat.id"
                    @click="setCategory(cat.id)"
                    class="px-3 py-1.5 rounded-lg text-xs font-ui transition-all whitespace-nowrap"
                    :class="
                        selectedCategory === cat.id
                            ? 'bg-amber-500 text-white font-medium shadow-sm'
                            : 'text-ink-600 dark:text-ink-400 hover:bg-ink-100 dark:hover:bg-ink-800'
                    "
                >
                    {{ cat.label }}
                </button>
            </div>

            <!-- Grid of templates -->
            <div class="p-6 overflow-y-auto grid grid-cols-1 md:grid-cols-2 gap-4 flex-1">
                <div
                    v-for="tpl in filteredTemplates"
                    :key="tpl.id"
                    @click="useTemplate(tpl)"
                    class="group relative flex flex-col p-4 rounded-xl border border-ink-200/80 dark:border-ink-800/80 bg-white dark:bg-ink-900/50 hover:border-amber-400/60 dark:hover:border-amber-400/40 hover:shadow-md dark:hover:shadow-black/30 cursor-pointer transition-all duration-150 hover:-translate-y-0.5"
                >
                    <div class="flex items-start justify-between gap-3 mb-2">
                        <div class="flex items-center gap-2.5">
                            <div
                                class="p-2 rounded-lg"
                                :class="{
                                    'bg-amber-100 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400': tpl.color === 'amber',
                                    'bg-indigo-100 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400': tpl.color === 'indigo',
                                    'bg-emerald-100 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400': tpl.color === 'emerald',
                                    'bg-rose-100 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400': tpl.color === 'rose',
                                    'bg-sky-100 dark:bg-sky-950/40 text-sky-600 dark:text-sky-400': tpl.color === 'sky',
                                    'bg-violet-100 dark:bg-violet-950/40 text-violet-600 dark:text-violet-400': tpl.color === 'violet',
                                }"
                            >
                                <component :is="tpl.icon" :size="18" />
                            </div>
                            <h3 class="font-display font-semibold text-sm text-ink-900 dark:text-ink-100">
                                {{ tpl.title }}
                            </h3>
                        </div>
                        <ArrowRight :size="15" class="text-ink-400 group-hover:text-amber-500 group-hover:translate-x-0.5 transition-all shrink-0 mt-1" />
                    </div>
                    <p class="text-xs text-ink-500 dark:text-ink-400 font-ui leading-relaxed flex-1 mt-1">
                        {{ tpl.description }}
                    </p>
                </div>
            </div>

            <!-- Footer -->
            <div class="px-6 py-3.5 bg-ink-50 dark:bg-ink-950/50 border-t border-ink-200 dark:border-ink-800 flex items-center justify-between text-xs text-ink-400 dark:text-ink-600 font-ui">
                <span>Click any template to create a new note with formatted starter content</span>
                <button
                    @click="emit('close')"
                    class="px-3.5 py-1.5 text-xs text-ink-600 dark:text-ink-300 hover:text-ink-900 dark:hover:text-white"
                >
                    Cancel
                </button>
            </div>
        </div>
    </div>
</template>
