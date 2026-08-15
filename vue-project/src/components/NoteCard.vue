<script setup lang="ts">
import { computed } from "vue";
import { useRouter } from "vue-router";
import { Star, FileText, List, Code2, BookOpen, Check, Folder as FolderIcon } from "lucide-vue-next";
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
}>();

const router = useRouter();

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
        class="group relative flex items-center justify-between gap-4 px-4 py-3.5 rounded-xl border border-ink-200/80 dark:border-ink-800/80 bg-white/90 dark:bg-ink-900/90 cursor-pointer transition-all duration-150 hover:border-amber-400/50 hover:shadow-md hover:bg-amber-50/20 dark:hover:bg-ink-800/40"
        :class="[
            accentBorder,
            'border-l-[3px]',
            isSelected ? 'ring-2 ring-amber-500 border-amber-500 bg-amber-50/30' : '',
        ]"
    >
        <!-- Selection Checkbox -->
        <div
            v-if="isSelectionMode"
            @click.stop="emit('toggleSelection', note._id)"
            class="w-5 h-5 rounded border border-ink-300 dark:border-ink-600 bg-white dark:bg-ink-800 flex items-center justify-center shrink-0 cursor-pointer"
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
                    <h3 class="font-display font-semibold text-ink-900 dark:text-ink-100 text-sm truncate">
                        {{ note.title || "Untitled" }}
                    </h3>
                    <Star v-if="note.isFavorite" :size="13" class="text-amber-500 fill-amber-500 shrink-0" />
                </div>
                <p class="text-xs text-ink-500 dark:text-ink-400 font-ui truncate max-w-md mt-0.5">
                    {{ preview || "No content yet…" }}
                </p>
            </div>
        </div>

        <div class="flex items-center gap-4 shrink-0 text-xs text-ink-400 dark:text-ink-500">
            <span v-if="note.folderId && typeof note.folderId === 'object'" class="hidden sm:flex items-center gap-1 px-2 py-0.5 rounded bg-ink-100 dark:bg-ink-800 text-ink-600 dark:text-ink-300 text-[11px]">
                <FolderIcon :size="11" />
                {{ note.folderId.name }}
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
        class="group relative flex flex-col rounded-xl border border-ink-200/80 dark:border-ink-800/80 bg-white dark:bg-ink-900 cursor-pointer overflow-hidden transition-all duration-200 hover:border-ink-300 dark:hover:border-ink-600 hover:shadow-xl hover:shadow-ink-900/0.06 dark:hover:shadow-black/40 hover:-translate-y-1"
        :class="[
            accentBorder,
            'border-l-[3px]',
            isSelected ? 'ring-2 ring-amber-500 border-amber-500' : '',
        ]"
        style="min-height: 200px"
    >
        <!-- Select Checkbox -->
        <div
            v-if="isSelectionMode"
            @click.stop="emit('toggleSelection', note._id)"
            class="absolute top-3 right-3 z-10 w-6 h-6 rounded border border-ink-300 dark:border-ink-600 bg-white dark:bg-ink-800 flex items-center justify-center shrink-0 cursor-pointer hover:border-ink-500 dark:hover:border-ink-400 transition-colors"
            :class="{ 'bg-amber-500 border-amber-500': isSelected }"
        >
            <Check v-if="isSelected" :size="16" class="text-white" />
        </div>

        <!-- Main content -->
        <div class="flex flex-col flex-1 px-5 pt-5 pb-4">
            <!-- Row 1: type badge + star -->
            <div class="flex items-center justify-between mb-3">
                <div class="flex items-center gap-1.5 px-2 py-0.5 rounded bg-ink-100/70 dark:bg-ink-800/70">
                    <component :is="contentType.icon" :size="11" class="text-ink-600 dark:text-ink-400" />
                    <span class="text-[10px] font-ui font-semibold uppercase tracking-wider text-ink-600 dark:text-ink-400">
                        {{ contentType.label }}
                    </span>
                </div>
                <Star v-if="note.isFavorite" :size="14" class="text-amber-500 fill-amber-500 shrink-0" />
            </div>

            <!-- Row 2: Title -->
            <h3 class="font-display font-bold text-ink-900 dark:text-ink-50 leading-snug line-clamp-2 text-[15px] mb-2.5">
                {{ note.title || "Untitled" }}
            </h3>

            <!-- Row 3: Preview -->
            <p class="text-[13px] text-ink-500 dark:text-ink-400 font-ui leading-relaxed line-clamp-3 flex-1">
                {{ preview || "No content yet…" }}
            </p>
        </div>

        <!-- Footer -->
        <div class="px-5 py-3 border-t border-ink-100 dark:border-ink-800/80 flex items-center justify-between gap-2 bg-ink-50/50 dark:bg-ink-900/60">
            <span class="text-[11px] text-ink-400 dark:text-ink-500 font-ui tabular-nums">
                {{ relativeTime(note.updatedAt) }}
            </span>
            <span class="text-[11px] text-ink-400 dark:text-ink-500 font-ui opacity-0 group-hover:opacity-100 transition-opacity tabular-nums">
                {{ readingTime }} read
            </span>
        </div>
    </div>
</template>
