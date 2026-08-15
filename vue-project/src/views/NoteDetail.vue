<script setup lang="ts">
import { onMounted, onUnmounted, computed, ref, watch } from "vue";
import { useRoute, useRouter, RouterLink } from "vue-router";
import {
    Pencil,
    Trash2,
    Star,
    ChevronDown,
    AlertTriangle,
    FileSpreadsheet,
    FileText,
    Share2,
    Check,
    Link as LinkIcon,
} from "lucide-vue-next";
import { generateHTML } from "@tiptap/html";
import StarterKit from "@tiptap/starter-kit";
import Image from "@tiptap/extension-image";
import Link from "@tiptap/extension-link";
import { Table } from "@tiptap/extension-table";
import { TableRow } from "@tiptap/extension-table-row";
import { TableCell } from "@tiptap/extension-table-cell";
import { TableHeader } from "@tiptap/extension-table-header";
import { useNotesStore } from "../store/notes";

const route = useRoute();
const router = useRouter();
const store = useNotesStore();

const noteId = route.params.noteId as string;
const menuRef = ref<HTMLElement | null>(null)

// Close dropdown when clicking outside
function handleClickOutside(e: MouseEvent) {
    if (showShareMenu.value && menuRef.value && !menuRef.value.contains(e.target as Node)) {
        showShareMenu.value = false
    }
}

onMounted(() => document.addEventListener('click', handleClickOutside, true))
onUnmounted(() => document.removeEventListener('click', handleClickOutside, true))
const confirmDelete = ref(false);
let confirmTimer: ReturnType<typeof setTimeout>;

// Refresh note when route changes (e.g., returning from edit)
watch(() => route.params.noteId, (newId) => {
    if (newId) store.fetchNote(newId as string);
}, { immediate: true });

const content = computed(() => {
    if (!store.activeNote?.content) return "";
    try {
        return generateHTML(JSON.parse(store.activeNote.content), [
            StarterKit.configure({ link: false }),
            Image,
            Link,
            Table,
            TableRow,
            TableCell,
            TableHeader,
        ]);
    } catch {
        return store.activeNote.content;
    }
});

function relativeTime(d: string): string {
    const diff = Date.now() - new Date(d).getTime();
    const mins = Math.floor(diff / 60_000);
    if (mins < 1) return "Saved just now";
    if (mins < 60) return `Saved ${mins}m ago`;
    const hours = Math.floor(mins / 60);
    if (hours < 24) return `Saved ${hours}h ago`;
    const days = Math.floor(hours / 24);
    if (days === 1) return "Saved yesterday";
    return `Saved ${days}d ago`;
}

function startDelete() {
    confirmDelete.value = true;
    confirmTimer = setTimeout(() => {
        confirmDelete.value = false;
    }, 4000);
}
async function doDelete() {
    clearTimeout(confirmTimer);
    await store.deleteNote(noteId);
    router.push("/app/notes");
}

// ── Export to Excel ──────────────────────────────────────────────────────────
async function exportToExcel() {
    const XLSX = await import('xlsx')
    const content = store.activeNote?.content
    if (!content) return

    let data: any[][] = []

    try {
        const json = JSON.parse(content)
        const findTables = (nodes: any[]): boolean => {
            for (const node of nodes) {
                if (node.type === 'table') {
                    for (const rowNode of node.content || []) {
                        if (rowNode.type === 'table_row') {
                            const row: any[] = []
                            for (const cell of rowNode.content || []) {
                                if (cell.type === 'table_cell' || cell.type === 'table_header') {
                                    let cellText = ''
                                    const getText = (n: any) => {
                                        if (n.text) cellText += n.text
                                        if (n.content) n.content.forEach(getText)
                                    }
                                    if (cell.content) cell.content.forEach(getText)
                                    row.push(cellText)
                                }
                            }
                            data.push(row)
                        }
                    }
                    return true
                }
                if (node.content && findTables(node.content)) return true
            }
            return false
        }
        findTables(json.content || json)
    } catch {}

    // Fallback: plain text
    if (data.length === 0) {
        const text = store.activeNote?.content || ''
        const lines = text.split('\n').filter(l => l.trim())
        data = lines.map(line => [line])
    }

    const ws = XLSX.utils.aoa_to_sheet(data)
    const wb = XLSX.utils.book_new()
    XLSX.utils.book_append_sheet(wb, ws, 'Notes')
    XLSX.writeFile(wb, `${store.activeNote?.title || 'note'}.xlsx`)
}

// ── Export to PDF ────────────────────────────────────────────────────────────
async function exportToPDF() {
    const { default: jsPDF } = await import('jspdf')
    const { default: autoTable } = await import('jspdf-autotable')
    const doc = new jsPDF()

    // Title
    doc.setFontSize(20)
    doc.setTextColor(26, 26, 26)
    doc.text(store.activeNote?.title || 'Untitled', 20, 20)

    const content = store.activeNote?.content
    if (!content) {
        doc.save(`${store.activeNote?.title || 'note'}.pdf`)
        return
    }

    let yPos = 35

    try {
        const json = JSON.parse(content)
        const findTables = (nodes: any[]): boolean => {
            for (const node of nodes) {
                if (node.type === 'table') {
                    const headRows: any[][] = []
                    const bodyRows: any[][] = []
                    let isHeader = true

                    for (const rowNode of node.content || []) {
                        if (rowNode.type === 'table_row') {
                            const row: any[] = []
                            for (const cell of rowNode.content || []) {
                                if (cell.type === 'table_cell' || cell.type === 'table_header') {
                                    let cellText = ''
                                    const getText = (n: any) => {
                                        if (n.text) cellText += n.text
                                        if (n.content) n.content.forEach(getText)
                                    }
                                    if (cell.content) cell.content.forEach(getText)
                                    row.push(cellText)
                                }
                            }
                            if (isHeader) {
                                headRows.push(row)
                                isHeader = false
                            } else {
                                bodyRows.push(row)
                            }
                        }
                    }

                    autoTable(doc, {
                        head: headRows.length > 0 ? headRows : [bodyRows[0] || []],
                        body: headRows.length > 0 ? bodyRows : bodyRows.slice(1),
                        startY: yPos,
                        margin: { left: 20, right: 20 },
                        theme: 'grid',
                        headStyles: { fillColor: [45, 45, 45], textColor: [255, 255, 255] },
                        alternateRowStyles: { fillColor: [245, 245, 245] },
                    })
                    // @ts-ignore
                    yPos = doc.lastAutoTable?.finalY + 15 || yPos + 30
                    return true
                }
                if (node.content && findTables(node.content)) return true
            }
            return false
        }
        const hadTables = findTables(json.content || json)

        // Plain text if no tables found
        if (!hadTables) {
            const text = store.activeNote?.content || ''
            doc.setFontSize(11)
            doc.setTextColor(80, 80, 80)
            const lines = doc.splitTextToSize(text, 170)
            doc.text(lines, 20, yPos)
        }
    } catch (e) {
        // Fallback on error
        doc.setFontSize(11)
        doc.setTextColor(80, 80, 80)
        const lines = doc.splitTextToSize(content, 170)
        doc.text(lines, 20, yPos)
    }

    doc.save(`${store.activeNote?.title || 'note'}.pdf`)
}

// ── Share note ───────────────────────────────────────────────────────────────
const showShareMenu = ref(false)
const copied = ref(false)

async function shareNote() {
    const title = store.activeNote?.title || 'Note'
    const url = window.location.href

    if (navigator.share) {
        try {
            await navigator.share({ title, url })
        } catch {}
    } else {
        // Fallback: copy link
        await navigator.clipboard.writeText(url)
        copied.value = true
        setTimeout(() => { copied.value = false }, 2000)
    }
    showShareMenu.value = false
}

function copyContent() {
    const text = store.activeNote?.content || ''
    navigator.clipboard.writeText(text)
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
    showShareMenu.value = false
}
</script>

<template>
    <div class="flex flex-col h-full bg-white dark:bg-ink-950">
        <!-- ── Top bar (matches image: "Saved 2h ago" left, star + edit + delete right) ── -->
        <div class="flex items-center justify-between px-8 py-3 shrink-0">
            <span class="text-sm text-ink-400 dark:text-ink-600 font-ui">
                {{
                    store.activeNote
                        ? relativeTime(store.activeNote.updatedAt)
                        : "…"
                }}
            </span>

            <div class="flex items-center gap-1" v-if="store.activeNote">
                <!-- Star -->
                <button
                    @click="store.toggleFavorite(noteId)"
                    class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                >
                    <Star
                        :size="16"
                        :class="
                            store.activeNote.isFavorite
                                ? 'text-amber-500 fill-amber-500'
                                : 'text-ink-300 dark:text-ink-700'
                        "
                    />
                </button>

                <!-- Edit -->
                <RouterLink
                    :to="`/app/notes/${noteId}/edit`"
                    class="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-ui font-semibold bg-ink-900 dark:bg-amber-500 text-white dark:text-ink-950 hover:bg-ink-700 dark:hover:bg-amber-600 transition-colors"
                >
                    <Pencil :size="12" /> Edit
                </RouterLink>

                <!-- Delete -->
                <Transition name="confirm">
                    <div
                        v-if="confirmDelete"
                        class="flex items-center gap-1.5 border border-red-200 dark:border-red-800 rounded-lg px-2.5 py-1.5"
                    >
                        <AlertTriangle :size="11" class="text-red-500" />
                        <span
                            class="text-xs text-red-600 dark:text-red-400 font-ui"
                            >Delete?</span
                        >
                        <button
                            @click="doDelete"
                            class="text-xs font-semibold font-ui text-red-600 dark:text-red-400 hover:underline ml-1"
                        >
                            Yes
                        </button>
                        <button
                            @click="confirmDelete = false"
                            class="text-xs font-ui text-ink-400 ml-0.5"
                        >
                            No
                        </button>
                    </div>
                </Transition>
                <button
                    v-if="!confirmDelete"
                    @click="startDelete"
                    class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors text-ink-300 dark:text-ink-700 hover:text-ink-600 dark:hover:text-ink-400"
                >
                    <Trash2 :size="15" />
                </button>

                <!-- More actions dropdown -->
                <div class="relative" ref="menuRef">
                    <button
                        @click="showShareMenu = !showShareMenu"
                        class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors text-ink-300 dark:text-ink-700"
                    >
                        <ChevronDown :size="16" />
                    </button>

                    <!-- Dropdown menu -->
                    <Transition name="dropdown">
                        <div
                            v-if="showShareMenu"
                            class="absolute right-0 top-full mt-1 w-48 bg-white dark:bg-ink-900 border border-ink-200 dark:border-ink-700 rounded-xl shadow-lg py-1 z-50"
        
                        >
                            <button
                                @click="exportToExcel"
                                class="w-full flex items-center gap-2.5 px-3 py-2 text-sm text-ink-700 dark:text-ink-200 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                            >
                                <FileSpreadsheet :size="15" class="text-emerald-600 dark:text-emerald-400" />
                                Export to Excel
                            </button>
                            <button
                                @click="exportToPDF"
                                class="w-full flex items-center gap-2.5 px-3 py-2 text-sm text-ink-700 dark:text-ink-200 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                            >
                                <FileText :size="15" class="text-red-500 dark:text-red-400" />
                                Export to PDF
                            </button>
                            <div class="h-px bg-ink-200 dark:bg-ink-700 my-1" />
                            <button
                                @click="shareNote"
                                class="w-full flex items-center gap-2.5 px-3 py-2 text-sm text-ink-700 dark:text-ink-200 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                            >
                                <Share2 :size="15" class="text-amber-500" />
                                Share Link
                            </button>
                            <button
                                @click="copyContent"
                                class="w-full flex items-center gap-2.5 px-3 py-2 text-sm text-ink-700 dark:text-ink-200 hover:bg-ink-100 dark:hover:bg-ink-800 transition-colors"
                            >
                                <LinkIcon :size="15" class="text-ink-400" />
                                Copy Content
                            </button>
                        </div>
                    </Transition>
                </div>
            </div>
        </div>

        <!-- Divider -->
        <div class="h-px bg-ink-200 dark:bg-ink-800 shrink-0" />

        <!-- ── Content ── -->
        <div class="flex-1 overflow-y-auto">
            <!-- Loading -->
            <div
                v-if="store.loading && !store.activeNote"
                class="max-w-2xl mx-auto px-8 py-10 animate-pulse space-y-5"
            >
                <div class="h-12 bg-ink-100 dark:bg-ink-800 rounded w-2/3" />
                <div class="space-y-3 mt-6">
                    <div
                        v-for="i in 5"
                        :key="i"
                        class="h-4 bg-ink-100 dark:bg-ink-800 rounded"
                        :style="{ width: `${95 - i * 8}%` }"
                    />
                </div>
            </div>

            <div
                v-else-if="store.activeNote"
                class="max-w-2xl mx-auto px-8 pt-10 pb-20"
            >
                <!-- Title -->
                <h1
                    class="font-display text-4xl font-bold text-ink-900 dark:text-ink-50 leading-tight mb-8"
                >
                    {{ store.activeNote.title }}
                </h1>

                <!-- Prose content -->
                <div
                    class="prose prose-ink max-w-none font-body text-ink-700 dark:text-ink-300 leading-relaxed tiptap"
                    v-html="
                        content ||
                        `<p class='italic text-ink-300 dark:text-ink-700'>Empty note — <a href='/app/notes/${noteId}/edit'>start writing</a></p>`
                    "
                />
            </div>
        </div>
    </div>
</template>

<style scoped>
.confirm-enter-active,
.confirm-leave-active {
    transition:
        opacity 0.12s ease,
        transform 0.12s ease;
}
.confirm-enter-from,
.confirm-leave-to {
    opacity: 0;
    transform: scale(0.95);
}

/* Dropdown animation */
.dropdown-enter-active,
.dropdown-leave-active {
    transition:
        opacity 0.15s ease,
        transform 0.15s ease;
}
.dropdown-enter-from,
.dropdown-leave-to {
    opacity: 0;
    transform: translateY(-4px) scale(0.97);
}
</style>
