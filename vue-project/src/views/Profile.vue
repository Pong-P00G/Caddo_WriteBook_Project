<script setup lang="ts">
import { ref } from "vue";
import { Camera, Sun, Moon } from "lucide-vue-next";
import { useAuthStore } from "@/store/auth";
import { useDarkMode } from "@/composable/Darkmode";
import api from "@/api/Api";

const auth = useAuthStore();
const { theme, toggle } = useDarkMode();

const name = ref(auth.user?.name ?? "");
const bio = ref(auth.user?.bio ?? "");
const saving = ref(false);
const uploading = ref(false);
const saved = ref(false);
const previewUrl = ref<string | null>(null);
const fileInput = ref<HTMLInputElement | null>(null);
const profileError = ref("");

function avatarSrc() {
    return previewUrl.value ?? auth.user?.avatar ?? null;
}

function onFileChange(e: Event) {
    const file = (e.target as HTMLInputElement).files?.[0];
    if (!file) return;
    previewUrl.value = URL.createObjectURL(file);
    uploadAvatar(file);
}

async function uploadAvatar(file: File) {
    uploading.value = true;
    profileError.value = "";
    try {
        const form = new FormData();
        form.append("avatar", file);
        const { data } = await api.post("/users/me/avatar", form, {
            headers: { "Content-Type": "multipart/form-data" },
        });
        if (auth.user) auth.user.avatar = data.data.avatar;
        previewUrl.value = null;
    } catch (e: any) {
        profileError.value = e?.response?.data?.error ?? "Upload failed";
        previewUrl.value = null;
    } finally {
        uploading.value = false;
    }
}

async function handleSave() {
    saving.value = true;
    profileError.value = "";
    try {
        const { data } = await api.patch("/users/me", {
            name: name.value.trim(),
            bio: bio.value.trim(),
        });
        if (auth.user) Object.assign(auth.user, data.data);
        saved.value = true;
        setTimeout(() => {
            saved.value = false;
        }, 2500);
    } catch {
        profileError.value = "Failed to save";
    } finally {
        saving.value = false;
    }
}
</script>

<template>
    <div class="flex flex-col h-full bg-white dark:bg-ink-950">
        <!-- Top bar -->
        <div class="flex items-center justify-between px-8 py-3 shrink-0">
            <span class="text-sm text-ink-400 dark:text-ink-600 font-ui"
                >Profile</span
            >
        </div>
        <div class="h-px bg-ink-200 dark:bg-ink-800 shrink-0" />

        <!-- Content -->
        <div class="flex-1 overflow-y-auto">
            <div class="max-w-2xl mx-auto px-8 py-10">
                <!-- ── Avatar ── -->
                <div class="flex items-start gap-6 mb-10">
                    <div class="relative group shrink-0">
                        <div
                            class="w-20 h-20 rounded-full overflow-hidden bg-amber-500 flex items-center justify-center text-white text-3xl font-bold"
                        >
                            <img
                                v-if="avatarSrc()"
                                :src="avatarSrc()!"
                                :alt="auth.user?.name"
                                class="w-full h-full object-cover"
                            />
                            <span v-else>{{
                                auth.user?.name?.charAt(0).toUpperCase()
                            }}</span>
                        </div>
                        <button
                            @click="fileInput?.click()"
                            :disabled="uploading"
                            class="absolute inset-0 rounded-full bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer"
                        >
                            <Camera :size="18" class="text-white" />
                        </button>
                        <div
                            v-if="uploading"
                            class="absolute inset-0 rounded-full bg-black/40 flex items-center justify-center"
                        >
                            <div
                                class="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"
                            />
                        </div>
                    </div>

                    <div class="pt-1">
                        <p
                            class="text-base font-ui font-semibold text-ink-900 dark:text-ink-100"
                        >
                            {{ auth.user?.name }}
                        </p>
                        <p
                            class="text-sm text-ink-400 dark:text-ink-600 font-ui mt-0.5"
                        >
                            {{ auth.user?.email }}
                        </p>
                        <p
                            class="text-xs text-ink-400 dark:text-ink-600 font-ui mt-0.5"
                        >
                            Member since
                            {{
                                new Date(
                                    auth.user?.createdAt ?? "",
                                ).getFullYear()
                            }}
                        </p>
                        <button
                            @click="fileInput?.click()"
                            :disabled="uploading"
                            class="mt-2 text-xs text-ink-400 dark:text-ink-600 hover:text-ink-700 dark:hover:text-ink-300 font-ui transition-colors underline"
                        >
                            {{ uploading ? "Uploading…" : "Change photo" }}
                        </button>
                        <p
                            class="text-xs text-ink-300 dark:text-ink-700 font-ui mt-0.5"
                        >
                            JPG, PNG, WebP or GIF · max 5 MB
                        </p>
                    </div>
                    <input
                        ref="fileInput"
                        type="file"
                        accept="image/jpeg,image/png,image/webp,image/gif"
                        class="hidden"
                        @change="onFileChange"
                    />
                </div>

                <!-- ── Info ── -->
                <p
                    class="text-xs font-ui font-medium text-ink-400 dark:text-ink-600 uppercase tracking-widest mb-5"
                >
                    Info
                </p>

                <div class="space-y-5">
                    <div>
                        <label
                            class="block text-sm font-ui font-medium text-ink-700 dark:text-ink-300 mb-1.5"
                            >Display name</label
                        >
                        <input
                            v-model="name"
                            type="text"
                            class="w-full border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-900 text-ink-900 dark:text-ink-100 rounded-lg px-3.5 py-2.5 text-sm font-ui focus:outline-none focus:ring-2 focus:ring-amber-400 transition"
                        />
                    </div>
                    <div>
                        <label
                            class="block text-sm font-ui font-medium text-ink-700 dark:text-ink-300 mb-1.5"
                            >Bio</label
                        >
                        <textarea
                            v-model="bio"
                            rows="3"
                            placeholder="Tell a little about yourself…"
                            class="w-full border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-900 text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600 rounded-lg px-3.5 py-2.5 text-sm font-ui focus:outline-none focus:ring-2 focus:ring-amber-400 transition resize-none"
                        />
                    </div>
                </div>

                <p
                    v-if="profileError"
                    class="text-xs text-red-500 font-ui mt-3"
                >
                    {{ profileError }}
                </p>

                <div class="flex items-center gap-3 mt-6">
                    <button
                        @click="handleSave"
                        :disabled="saving"
                        class="px-4 py-2 bg-ink-900 dark:bg-amber-500 text-white dark:text-ink-950 rounded-lg text-sm font-ui font-semibold hover:bg-ink-700 dark:hover:bg-amber-600 disabled:opacity-50 transition-colors"
                    >
                        {{ saving ? "Saving…" : "Save changes" }}
                    </button>
                    <span
                        v-if="saved"
                        class="text-xs text-green-600 dark:text-green-400 font-ui"
                        >Saved!</span
                    >
                </div>

                <!-- ── Appearance ── -->
                <div
                    class="border-t border-ink-200 dark:border-ink-800 pt-8 mt-10"
                >
                    <p
                        class="text-xs font-ui font-medium text-ink-400 dark:text-ink-600 uppercase tracking-widest mb-5"
                    >
                        Appearance
                    </p>
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-sm font-ui font-medium text-ink-700 dark:text-ink-300"
                            >
                                Dark mode
                            </p>
                            <p
                                class="text-xs text-ink-400 dark:text-ink-600 font-ui mt-0.5"
                            >
                                {{
                                    theme === "dark"
                                        ? "Currently on"
                                        : "Currently off"
                                }}
                            </p>
                        </div>
                        <button
                            @click="toggle"
                            class="relative inline-flex h-6 w-11 items-center rounded-full transition-colors focus:outline-none"
                            :class="
                                theme === 'dark'
                                    ? 'bg-ink-800 dark:bg-amber-500'
                                    : 'bg-ink-200'
                            "
                        >
                            <span
                                class="inline-block h-4 w-4 rounded-full bg-white shadow transition-transform"
                                :class="
                                    theme === 'dark'
                                        ? 'translate-x-6'
                                        : 'translate-x-1'
                                "
                            />
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
