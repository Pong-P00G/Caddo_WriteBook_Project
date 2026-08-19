<script setup lang="ts">
import { computed } from "vue";
import { useRouter } from "vue-router";
import { Star, Pin, FileText, List, Code2, BookOpen, Check, Folder as FolderIcon, Tag, Globe } from "lucide-vue-next";
import type { Note } from "../store/types/interface";

const props = withDefaults(
    defineProps<{
        note: Note;
        isSelected?: boolean;
        isSelectionMode?: boolean;
        viewMode?: "grid" | "list";
    }>(),
    {
        viewMode: "grid",
    }
);

const emit = defineEmits<{
    (e: "toggleSelection", id: string): void;
    (e: "enterSelectionMode", id: string): void;
    (e: "togglePin", id: string): void;
    (e: "toggleFavorite", id: string): void;
}>();

const router = useRouter();

// Color styles map
const colorThemes: Record<string, { border: string; bg: string; darkBg: string; text: string }> = {
    amber: { border: "border-l-amber-500", bg: "bg-amber-50/40", darkBg: "dark:bg-amber-950/20", text: "text-amber-600 dark:text-amber-400" },
    emerald: { border: "border-l-emerald-500", bg: "bg-emerald-50/40", darkBg: "dark:bg-emerald-950/20", text: "text-emerald-600 dark:text-emerald-400" },
    indigo: { border: "border-l-indigo-500", bg: "bg-indigo-50/40", darkBg: "dark:bg-indigo-950/20", text: "text-indigo-600 dark:text-indigo-400" },
    rose: { border: "border-l-rose-500", bg: "bg-rose-50/40", darkBg: "dark:bg-rose-950/20", text: "text-rose-600 dark:text-rose-400" },
    sky: { border: "border-l-sky-500", bg: "bg-sky-50/40", darkBg: "dark:bg-sky-950/20", text: "text-sky-600 dark:text-sky-400" },
    violet: { border: "border-l-violet-500", bg: "bg-violet-50/40", darkBg: "dark:bg-violet-950/20", text: "text-violet-600 dark:text-violet-400" },
    orange: { border: "border-l-orange-500", bg: "bg-orange-50/40", darkBg: "dark:bg-orange-950/20", text: "text-orange-600 dark:text-orange-400" },
    slate: { border: "border-l-slate-500", bg: "bg-slate-50/40", darkBg: "dark:bg-slate-900/40", text: "text-slate-600 dark:text-slate-400" },
};

const customColorStyle = computed(() => {
    if (!props.note.color || !colorThemes[props.note.color]) return null;
    return colorThemes[props.note.color];
});

// ── Content parsing ────────────────────────────────────────────────────────
interface TiptapNode {
    type: string;
    content?: TiptapNode[];
    text?: string;
    attrs?: Record<string, any>;
}

const parsed = computed((): TiptapNode | null => {
    if (!props.note.content) return null;
    try {
        return JSON.parse(props.note.content) as TiptapNode;
    } catch {
        return null;
    }
});

// Extract plain text preview (up to 160 chars)
const preview = computed((): string => {
    if (!parsed.value) return props.note.content?.slice(0, 160) ?? "";
    function walk(nodes: TiptapNode[]): string {
        return nodes
            .reduce((acc: string[], n) => {
                if (n.type === "text") {
                    acc.push(n.text ?? "");
                } else if (n.content) {
                    acc.push(walk(n.content));
                }
                return acc;
            }, [])
            .join(" ");
    }
    return walk(parsed.value.content ?? [])
        .trim()
        .slice(0, 160);
});

// Detect the dominant content type for the badge
const contentType = computed((): { label: string; icon: typeof FileText } => {
    if (!parsed.value?.content?.length)
        return { label: "Note", icon: FileText };
    const first = parsed.value.content[0];
    if (first.type === "heading")
        return {
            label: first.attrs?.level === 1 ? "H1" : `H${first.attrs?.level ?? 2}`,
            icon: BookOpen,
        };
    if (first.type === "bulletList" || first.type === "orderedList")
        return { label: "List", icon: List };
    if (first.type === "codeBlock") return { label: "Code", icon: Code2 };
    const hasCode = parsed.value.content.some((n) => n.type === "codeBlock");
    if (hasCode) return { label: "Code", icon: Code2 };
    return { label: "Note", icon: FileText };
});

// ── Tags ──────────────────────────────────────────────────────────────────
interface TagObj { _id: string; name: string; color?: string }
const tags = computed((): TagObj[] => {
    if (!props.note.tags?.length) return [];
    return (props.note.tags as any[]).filter((t): t is TagObj => typeof t === "object" && t !== null);
});

// ── Dates ──────────────────────────────────────────────────────────────────
function relativeTime(d: string): string {
    if (!d) return "";
    const diff = Date.now() - new Date(d).getTime();
    const mins = Math.floor(diff / 60_000);
    if (mins < 1) return "Just now";
    if (mins < 60) return `${mins}m ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `${hours}h ago`;
    const days = Math.floor(hours / 24);
    if (days === 1) return "Yesterday";
    if (days < 7) return `${days}d ago`;
    return new Date(d).toLocaleDateString(undefined, {
        month: "short",
        day: "numeric",
    });
}

// ── Accent color (deterministic, subtle left border) ──────────────────────
const accentBorder = computed((): string => {
    const colors = [
        "border-l-amber-400",
        "border-l-orange-400",
        "border-l-rose-400",
        "border-l-violet-400",
        "border-l-sky-400",
        "border-l-emerald-400",
        "border-l-pink-400",
        "border-l-teal-400",
    ];
    const id = props.note._id || "default";
    const idx =
        id.split("").reduce((sum: number, c: string) => sum + c.charCodeAt(0), 0) %
        colors.length;
    return colors[idx];
});

// Reading time estimate (200 wpm)
const readingTime = computed((): string => {
    const total = preview.value.split(/\s+/).filter(Boolean).length;
    const mins = Math.ceil(total / 200);
    return mins < 1 ? "< 1 min" : `${mins} min`;
});

// Word count
const wordCount = computed((): number =>
    preview.value.split(/\s+/).filter(Boolean).length
);

// ── Context menu (right-click) ─────────────────────────────────────────────
function handleContextMenu(e: MouseEvent) {
    e.preventDefault();
    // Enter selection mode on right-click for quick multi-select
    emit("enterSelectionMode", props.note._id);
}
</script>

<template>
    <!-- ── LIST VIEW MODE ── -->
    <div
        v-if="viewMode === 'list'"
        @click="
            isSelectionMode
                ? emit('toggleSelection', note._id)
                : router.push(`/app/notes/${note._id}`)
        "
        @dblclick.stop="emit('enterSelectionMode', note._id)"
        @contextmenu.prevent="handleContextMenu"
        class="group relative flex items-center justify-between gap-4 px-4 py-3.5 rounded-xl border border-ink-200/80 dark:border-ink-800/80 bg-white/90 dark:bg-ink-900/90 cursor-pointer transition-all duration-150 hover:border-amber-400/50 hover:shadow-md hover:bg-amber-50/20 dark:hover:bg-ink-800/40"
        :class="[
            customColorStyle ? customColorStyle.border : accentBorder,
            customColorStyle ? `${customColorStyle.bg} ${customColorStyle.darkBg}` : '',
            'border-l-[3px]',
            isSelected ? 'ring-2 ring-amber-500 border-amber-500 bg-amber-50/30' : '',
        ]"
    >
        <!-- Selection Checkbox -->
        <div
            v-if="isSelectionMode"
            @click.stop="emit('toggleSelection', note._id)"
            class="w-5 h-5 rounded border border-ink-300 dark:border-ink-600 bg-white dark:bg-ink-800 flex items-center justify-center shrink-0 cursor-pointer transition-colors"
            :class="{ 'bg-amber-500 border-amber-500': isSelected }"
        >
            <Check v-if="isSelected" :size="14" class="text-white" />
        </div>

        <div class="flex items-center gap-3.5 min-w-0 flex-1">
            <div class="p-2 rounded-lg bg-ink-100 dark:bg-ink-800 text-ink-600 dark:text-ink-300 shrink-0">
                <component :is="contentType.icon" :size="16" />
            </div>

            <div class="min-w-0 flex-1">
                <div class="flex items-center gap-2">
                    <Pin v-if="note.isPinned" :size="13" class="text-amber-500 fill-amber-500 shrink-0" />
                    <h3 class="font-display font-semibold text-ink-900 dark:text-ink-100 text-sm truncate">
                        {{ note.title || "Untitled" }}
                    </h3>
                    <Star v-if="note.isFavorite" :size="13" class="text-amber-500 fill-amber-500 shrink-0" />
                </div>
                <p class="text-xs text-ink-500 dark:text-ink-400 font-ui truncate max-w-md mt-0.5">
                    {{ preview || "No content yet…" }}
                </p>
                <!-- Tags row (list mode) -->
                <div v-if="tags.length" class="flex items-center gap-1 mt-1.5 flex-wrap">
                    <span
                        v-for="tag in tags.slice(0, 3)"
                        :key="tag._id"
                        class="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded text-[10px] font-ui font-medium"
                        :style="tag.color ? { color: tag.color, backgroundColor: tag.color + '22' } : {}"
                        :class="!tag.color ? 'bg-ink-100 dark:bg-ink-800 text-ink-500 dark:text-ink-400' : ''"
                    >
                        <Tag :size="9" />
                        {{ tag.name }}
                    </span>
                    <span v-if="tags.length > 3" class="text-[10px] text-ink-400 dark:text-ink-600">+{{ tags.length - 3 }}</span>
                </div>
            </div>
        </div>

        <div class="flex items-center gap-3 shrink-0 text-xs text-ink-400 dark:text-ink-500">
            <!-- Folder badge -->
            <span v-if="note.folderId && typeof note.folderId === 'object'" class="hidden sm:flex items-center gap-1 px-2 py-0.5 rounded bg-ink-100 dark:bg-ink-800 text-ink-600 dark:text-ink-300 text-[11px]">
                <FolderIcon :size="11" />
                {{ note.folderId.name }}
            </span>
            <!-- Word count (shows on hover) -->
            <span class="hidden sm:block tabular-nums font-ui text-[11px] opacity-0 group-hover:opacity-100 transition-opacity">
                {{ wordCount }}w
            </span>
            <span class="tabular-nums font-ui text-[11px]">{{ relativeTime(note.updatedAt) }}</span>
        </div>
    </div>

    <!-- ── GRID VIEW MODE (Default Tile) ── -->
    <div
        v-else
        @click="
            isSelectionMode
                ? emit('toggleSelection', note._id)
                : router.push(`/app/notes/${note._id}`)
        "
        @dblclick.stop="emit('enterSelectionMode', note._id)"
        @contextmenu.prevent="handleContextMenu"
        class="group relative flex flex-col rounded-2xl border border-ink-200/90 dark:border-ink-800/90 bg-white dark:bg-ink-900/90 cursor-pointer overflow-hidden transition-all duration-200 hover:border-amber-400/60 dark:hover:border-amber-500/40 hover:shadow-lg dark:hover:shadow-xl dark:hover:shadow-black/50 hover:-translate-y-1"
        :class="[
            customColorStyle ? customColorStyle.border : accentBorder,
            customColorStyle ? `${customColorStyle.bg} ${customColorStyle.darkBg}` : '',
            'border-l-4',
            isSelected ? 'ring-2 ring-amber-500 border-amber-500 bg-amber-50/20' : '',
        ]"
        style="min-height: 210px; will-change: transform"
    >
        <!-- Select Checkbox -->
        <Transition
            enter-active-class="transition-all duration-150"
            enter-from-class="opacity-0 scale-75"
            enter-to-class="opacity-100 scale-100"
        >
            <div
                v-if="isSelectionMode"
                @click.stop="emit('toggleSelection', note._id)"
                class="absolute top-3.5 right-3.5 z-10 w-6 h-6 rounded-lg border border-ink-300 dark:border-ink-600 bg-white dark:bg-ink-800 flex items-center justify-center shrink-0 cursor-pointer hover:border-amber-500 transition-colors shadow-xs"
                :class="{ 'bg-amber-500 border-amber-500': isSelected }"
            >
                <Check v-if="isSelected" :size="15" class="text-white" />
            </div>
        </Transition>

        <!-- Main Card Body -->
        <div class="flex flex-col flex-1 px-5 pt-4.5 pb-3.5">
            <!-- Row 1: Header tags, Public badge, Quick action icons -->
            <div class="flex items-center justify-between gap-2 mb-2.5">
                <div class="flex items-center gap-1.5 flex-wrap">
                    <!-- Content type chip -->
                    <div class="flex items-center gap-1 px-2 py-0.5 rounded-md bg-ink-100/80 dark:bg-ink-800 text-ink-600 dark:text-ink-400 text-[10px] font-ui font-semibold uppercase tracking-wider">
                        <component :is="contentType.icon" :size="11" />
                        <span>{{ contentType.label }}</span>
                    </div>

                    <!-- Public Share Badge -->
                    <div
                        v-if="note.isPublic"
                        class="flex items-center gap-1 px-1.5 py-0.5 rounded-md bg-amber-500/10 text-amber-600 dark:text-amber-400 text-[10px] font-ui font-medium"
                        title="Shared to web"
                    >
                        <Globe :size="10" />
                        <span>Public</span>
                    </div>
                </div>

                <!-- Quick Action icons (Pin & Favorite) -->
                <div class="flex items-center gap-1 shrink-0" @click.stop>
                    <!-- Pin indicator / toggle -->
                    <button
                        @click="emit('togglePin', note._id)"
                        class="p-1 rounded-md transition-colors cursor-pointer"
                        :class="note.isPinned ? 'text-amber-500' : 'text-ink-300 dark:text-ink-700 opacity-0 group-hover:opacity-100 hover:text-amber-500 hover:bg-ink-100 dark:hover:bg-ink-800'"
                        :title="note.isPinned ? 'Unpin note' : 'Pin note'"
                    >
                        <Pin :size="13" :class="note.isPinned ? 'fill-amber-500 rotate-45' : ''" />
                    </button>

                    <!-- Star indicator / toggle -->
                    <button
                        @click="emit('toggleFavorite', note._id)"
                        class="p-1 rounded-md transition-colors cursor-pointer"
                        :class="note.isFavorite ? 'text-amber-500' : 'text-ink-300 dark:text-ink-700 opacity-0 group-hover:opacity-100 hover:text-amber-500 hover:bg-ink-100 dark:hover:bg-ink-800'"
                        :title="note.isFavorite ? 'Remove favorite' : 'Add favorite'"
                    >
                        <Star :size="13" :class="note.isFavorite ? 'fill-amber-500' : ''" />
                    </button>
                </div>
            </div>

            <!-- Row 2: Note Title -->
            <h3 class="font-display font-bold text-ink-950 dark:text-ink-50 leading-snug line-clamp-2 text-[15px] mb-2 group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors">
                {{ note.title || "Untitled" }}
            </h3>

            <!-- Row 3: Preview Snippet -->
            <p class="text-xs text-ink-500 dark:text-ink-400 font-ui leading-relaxed line-clamp-3 flex-1 mb-2.5">
                {{ preview || "No content yet…" }}
            </p>

            <!-- Tags in grid -->
            <div v-if="tags.length" class="flex items-center gap-1.5 mt-auto pt-1 flex-wrap">
                <span
                    v-for="tag in tags.slice(0, 2)"
                    :key="tag._id"
                    class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px] font-ui font-medium"
                    :style="tag.color ? { color: tag.color, backgroundColor: tag.color + '22' } : {}"
                    :class="!tag.color ? 'bg-ink-100 dark:bg-ink-800 text-ink-600 dark:text-ink-400' : ''"
                >
                    <Tag :size="9" />
                    {{ tag.name }}
                </span>
                <span v-if="tags.length > 2" class="text-[10px] text-ink-400 dark:text-ink-600 font-ui font-medium">+{{ tags.length - 2 }}</span>
            </div>
        </div>

        <!-- Footer Meta Bar -->
        <div class="px-5 py-2.5 border-t border-ink-100 dark:border-ink-800/80 flex items-center justify-between gap-2 bg-ink-50/40 dark:bg-ink-950/40 text-xs font-ui">
            <div class="flex items-center gap-2 min-w-0">
                <span class="text-[11px] text-ink-400 dark:text-ink-500 tabular-nums">
                    {{ relativeTime(note.updatedAt) }}
                </span>
                <!-- Folder badge in footer -->
                <span v-if="note.folderId && typeof note.folderId === 'object'" class="flex items-center gap-1 px-1.5 py-0.5 rounded bg-ink-100 dark:bg-ink-800 text-[10px] text-ink-500 dark:text-ink-400 truncate max-w-28">
                    <FolderIcon :size="9" class="shrink-0" />
                    <span class="truncate">{{ note.folderId.name }}</span>
                </span>
            </div>
            <div class="flex items-center gap-2 shrink-0 text-[11px] text-ink-400 dark:text-ink-500">
                <span class="tabular-nums opacity-0 group-hover:opacity-100 transition-opacity">
                    {{ wordCount }}w
                </span>
                <span>•</span>
                <span class="tabular-nums">
                    {{ readingTime }}
                </span>
            </div>
        </div>
    </div>
</template>
