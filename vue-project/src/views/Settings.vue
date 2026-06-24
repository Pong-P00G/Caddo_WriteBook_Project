<script setup lang="ts">
import { ref } from "vue";
import { RouterLink } from "vue-router";
import { useAuthStore } from "@/store/auth";
import api from "@/api/Api";

const auth = useAuthStore();
const name = ref(auth.user?.name ?? "");
const bio = ref(auth.user?.bio ?? "");
const saved = ref(false);
const loading = ref(false);

async function handleSave() {
    loading.value = true;
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
    } finally {
        loading.value = false;
    }
}
</script>

<template>
    <div class="flex flex-col h-full bg-white dark:bg-ink-950">
        <!-- Top bar -->
        <div class="flex items-center justify-between px-8 py-3 shrink-0">
            <span class="text-sm text-ink-400 dark:text-ink-600 font-ui"
                >Account settings</span
            >
        </div>
        <div class="h-px bg-ink-200 dark:bg-ink-800 shrink-0" />

        <!-- Content -->
        <div class="flex-1 overflow-y-auto">
            <div class="max-w-2xl mx-auto px-8 py-10">
                <!-- ── Account ── -->
                <p
                    class="text-xs font-ui font-medium text-ink-400 dark:text-ink-600 uppercase tracking-widest mb-5"
                >
                    Account
                </p>

                <!-- Avatar row -->
                <div class="flex items-center gap-4 mb-8">
                    <div
                        class="w-14 h-14 rounded-full overflow-hidden bg-amber-500 flex items-center justify-center text-white text-xl font-bold shrink-0"
                    >
                        <img
                            v-if="auth.user?.avatar"
                            :src="auth.user.avatar"
                            :alt="auth.user?.name"
                            class="w-full h-full object-cover"
                        />
                        <span v-else>{{
                            auth.user?.name?.charAt(0).toUpperCase()
                        }}</span>
                    </div>
                    <div>
                        <p
                            class="text-sm font-ui font-semibold text-ink-800 dark:text-ink-200"
                        >
                            {{ auth.user?.name }}
                        </p>
                        <p
                            class="text-xs text-ink-400 dark:text-ink-600 font-ui mt-0.5"
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
                    </div>
                    <RouterLink
                        to="/app/profile"
                        class="ml-auto text-xs font-ui text-ink-400 dark:text-ink-600 hover:text-ink-700 dark:hover:text-ink-300 border border-ink-200 dark:border-ink-700 px-3 py-1.5 rounded-lg transition-colors"
                    >
                        Edit profile →
                    </RouterLink>
                </div>

                <!-- ── Profile fields ── -->
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
                            placeholder="Write a short bio…"
                            class="w-full border border-ink-200 dark:border-ink-700 bg-white dark:bg-ink-900 text-ink-900 dark:text-ink-100 placeholder-ink-300 dark:placeholder-ink-600 rounded-lg px-3.5 py-2.5 text-sm font-ui focus:outline-none focus:ring-2 focus:ring-amber-400 transition resize-none"
                        />
                    </div>
                </div>

                <div class="flex items-center gap-3 mt-6">
                    <button
                        @click="handleSave"
                        :disabled="loading"
                        class="px-4 py-2 bg-ink-900 dark:bg-amber-500 text-white dark:text-ink-950 rounded-lg text-sm font-ui font-semibold hover:bg-ink-700 dark:hover:bg-amber-600 disabled:opacity-50 transition-colors"
                    >
                        {{ loading ? "Saving…" : "Save changes" }}
                    </button>
                    <span
                        v-if="saved"
                        class="text-xs text-green-600 dark:text-green-400 font-ui"
                        >Saved!</span
                    >
                </div>

                <!-- ── Danger zone ── -->
                <div
                    class="border-t border-ink-200 dark:border-ink-800 pt-8 mt-10"
                >
                    <p
                        class="text-xs font-ui font-medium text-ink-400 dark:text-ink-600 uppercase tracking-widest mb-5"
                    >
                        Danger zone
                    </p>
                    <div class="flex items-center justify-between">
                        <div>
                            <p
                                class="text-sm font-ui font-medium text-ink-700 dark:text-ink-300"
                            >
                                Delete account
                            </p>
                            <p
                                class="text-xs text-ink-400 dark:text-ink-600 font-ui mt-0.5"
                            >
                                Permanently remove your account and all data.
                            </p>
                        </div>
                        <button
                            class="px-4 py-2 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-400 rounded-lg text-sm font-ui hover:bg-red-50 dark:hover:bg-red-950/20 transition-colors"
                        >
                            Delete account
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </div>
</template>
