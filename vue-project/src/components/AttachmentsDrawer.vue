<script setup lang="ts">
import { ref, watch, onMounted } from "vue";
import api from "@/api/Api";
import { useToast } from "@/composable/useToast";
import {
    X,
    Paperclip,
    Upload,
    FileText,
    Image as ImageIcon,
    FileCode,
    FileArchive,
    Music,
    Film,
    Download,
    Trash2,
    Copy,
    Check,
    Loader2,
    ExternalLink,
} from "lucide-vue-next";

export interface NoteAttachment {
    _id: string;
    noteId?: string;
    filename: string;
    url: string;
    mimeType: string;
    size: number;
    createdAt: string;
}

const props = defineProps<{
    isOpen: boolean;
    noteId: string;
}>();

const emit = defineEmits<{
    (e: "close"): void;
    (e: "insert", attachment: NoteAttachment): void;
}>();

const toast = useToast();
const attachments = ref<NoteAttachment[]>([]);
const isLoading = ref(false);
const isUploading = ref(false);
const isDragging = ref(false);
const copiedId = ref<string | null>(null);
const fileInputRef = ref<HTMLInputElement | null>(null);

watch(
    () => [props.isOpen, props.noteId],
    ([open, nId]) => {
        if (open && nId) {
            fetchAttachments();
        }
    },
    { immediate: true }
);

async function fetchAttachments() {
    if (!props.noteId) return;
    isLoading.value = true;
    try {
        const { data } = await api.get<{ success: boolean; data: NoteAttachment[] }>(
            `/attachments/note/${props.noteId}`
        );
        attachments.value = data.data;
    } catch {
        attachments.value = [];
    } finally {
        isLoading.value = false;
    }
}

async function handleFileUpload(files: FileList | null) {
    if (!files || files.length === 0) return;
    isUploading.value = true;

    try {
        for (let i = 0; i < files.length; i++) {
            const file = files[i];
            const formData = new FormData();
            formData.append("file", file);
            if (props.noteId) {
                formData.append("noteId", props.noteId);
            }

            const { data } = await api.post<{ success: boolean; data: NoteAttachment }>(
                "/attachments/upload",
                formData,
                { headers: { "Content-Type": "multipart/form-data" } }
            );
            attachments.value.unshift(data.data);
        }
        toast.success("Uploaded successfully!", `${files.length} file(s) attached to note.`);
    } catch (err: any) {
        toast.error("Upload failed", err.response?.data?.error || "Could not upload file.");
    } finally {
        isUploading.value = false;
        if (fileInputRef.value) fileInputRef.value.value = "";
    }
}

async function handleDelete(attId: string) {
    try {
        await api.delete(`/attachments/${attId}`);
        attachments.value = attachments.value.filter((a) => a._id !== attId);
        toast.success("Attachment deleted");
    } catch {
        toast.error("Failed to delete attachment");
    }
}

function copyAttachmentUrl(att: NoteAttachment) {
    const fullUrl = window.location.origin + att.url;
    navigator.clipboard.writeText(fullUrl);
    copiedId.value = att._id;
    toast.info("Link copied to clipboard");
    setTimeout(() => {
        copiedId.value = null;
    }, 2000);
}

function formatFileSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function getFileIcon(mime: string) {
    if (mime.startsWith("image/")) return ImageIcon;
    if (mime.startsWith("audio/")) return Music;
    if (mime.startsWith("video/")) return Film;
    if (mime.includes("zip") || mime.includes("tar") || mime.includes("compressed")) return FileArchive;
    if (mime.includes("json") || mime.includes("javascript") || mime.includes("xml")) return FileCode;
    return FileText;
}
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
                class="w-screen max-w-md bg-white dark:bg-ink-900 border-l border-ink-200 dark:border-ink-800 shadow-2xl flex flex-col animate-slide-left"
            >
                <!-- Drawer Header -->
                <div class="px-6 py-4 border-b border-ink-200 dark:border-ink-800 flex items-center justify-between">
                    <div class="flex items-center gap-2.5">
                        <div class="p-2 rounded-xl bg-amber-500/10 text-amber-500">
                            <Paperclip :size="18" />
                        </div>
                        <div>
                            <h2 class="text-base font-display font-bold text-ink-900 dark:text-ink-50">
                                Attachments
                            </h2>
                            <p class="text-xs text-ink-500 dark:text-ink-400 font-ui">
                                {{ attachments.length }} file{{ attachments.length !== 1 ? 's' : '' }} attached
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

                <!-- Drawer Content -->
                <div class="flex-1 overflow-y-auto p-6 space-y-6">
                    <!-- Drop Zone -->
                    <div
                        @dragover.prevent="isDragging = true"
                        @dragleave.prevent="isDragging = false"
                        @drop.prevent="isDragging = false; handleFileUpload($event.dataTransfer?.files || null)"
                        class="border-2 border-dashed rounded-2xl p-6 text-center transition-all cursor-pointer flex flex-col items-center justify-center gap-2.5"
                        :class="isDragging ? 'border-amber-500 bg-amber-50/20 dark:bg-amber-950/20' : 'border-ink-200 dark:border-ink-700 hover:border-ink-400 dark:hover:border-ink-600 bg-ink-50/50 dark:bg-ink-950/30'"
                        @click="fileInputRef?.click()"
                    >
                        <input
                            ref="fileInputRef"
                            type="file"
                            multiple
                            class="hidden"
                            @change="handleFileUpload(($event.target as HTMLInputElement).files)"
                        />
                        <div class="p-3 rounded-2xl bg-white dark:bg-ink-800 text-ink-500 dark:text-ink-300 shadow-sm">
                            <Loader2 v-if="isUploading" :size="20" class="animate-spin text-amber-500" />
                            <Upload v-else :size="20" />
                        </div>
                        <div>
                            <p class="text-xs font-semibold text-ink-800 dark:text-ink-200 font-ui">
                                {{ isUploading ? "Uploading files…" : "Click or drag files here to attach" }}
                            </p>
                            <p class="text-[11px] text-ink-400 dark:text-ink-500 font-ui mt-0.5">
                                Images, PDFs, Documents, Audio up to 25 MB
                            </p>
                        </div>
                    </div>

                    <!-- Attachments List -->
                    <div v-if="isLoading" class="flex flex-col items-center justify-center py-12">
                        <Loader2 :size="24" class="animate-spin text-amber-500 mb-2" />
                        <span class="text-xs font-ui text-ink-400">Loading attachments…</span>
                    </div>

                    <div v-else-if="attachments.length === 0" class="text-center py-12 text-ink-400 font-ui text-xs">
                        No attachments yet. Upload images, docs, or PDFs to attach them to this note.
                    </div>

                    <div v-else class="space-y-2.5">
                        <div
                            v-for="att in attachments"
                            :key="att._id"
                            class="group p-3.5 rounded-xl border border-ink-200/80 dark:border-ink-800 bg-white dark:bg-ink-900 hover:border-ink-300 dark:hover:border-ink-700 transition-all flex items-center justify-between gap-3 shadow-xs"
                        >
                            <!-- Left icon + details -->
                            <div class="flex items-center gap-3 min-w-0 flex-1">
                                <div class="p-2.5 rounded-xl bg-ink-100 dark:bg-ink-800 text-ink-600 dark:text-ink-300 shrink-0">
                                    <component :is="getFileIcon(att.mimeType)" :size="18" />
                                </div>
                                <div class="min-w-0 flex-1">
                                    <p class="text-xs font-medium text-ink-900 dark:text-ink-100 font-ui truncate" :title="att.filename">
                                        {{ att.filename }}
                                    </p>
                                    <div class="flex items-center gap-2 text-[11px] text-ink-400 font-ui mt-0.5">
                                        <span>{{ formatFileSize(att.size) }}</span>
                                        <span>•</span>
                                        <span>{{ new Date(att.createdAt).toLocaleDateString() }}</span>
                                    </div>
                                </div>
                            </div>

                            <!-- Right actions -->
                            <div class="flex items-center gap-1 shrink-0">
                                <button
                                    @click="copyAttachmentUrl(att)"
                                    class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400 hover:text-ink-700 dark:hover:text-ink-200 transition-colors"
                                    title="Copy URL"
                                >
                                    <Check v-if="copiedId === att._id" :size="14" class="text-emerald-500" />
                                    <Copy v-else :size="14" />
                                </button>
                                <a
                                    :href="att.url"
                                    target="_blank"
                                    download
                                    class="p-1.5 rounded-lg hover:bg-ink-100 dark:hover:bg-ink-800 text-ink-400 hover:text-ink-700 dark:hover:text-ink-200 transition-colors"
                                    title="Download"
                                >
                                    <Download :size="14" />
                                </a>
                                <button
                                    @click="handleDelete(att._id)"
                                    class="p-1.5 rounded-lg hover:bg-red-50 dark:hover:bg-red-950/40 text-ink-400 hover:text-red-600 dark:hover:text-red-400 transition-colors"
                                    title="Delete"
                                >
                                    <Trash2 :size="14" />
                                </button>
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
                        Done
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>
