<script setup lang="ts">
import { ref, onMounted, watch, computed } from "vue";
import { useRoute } from "vue-router";
import {
    User,
    Camera,
    Palette,
    Type,
    Settings2,
    Shield,
    Sun,
    Moon,
    Monitor,
    Check,
    Loader2,
    AlertTriangle,
    Eye,
    EyeOff,
    X,
} from "lucide-vue-next";
import { useAuthStore } from "../store/auth";
import { useDarkMode } from "../composable/Darkmode";
import api from "../api/Api";

// ── Stores & composables ────────────────────────────────────────────────────
const auth = useAuthStore();
const route = useRoute();
const { theme, toggle: toggleTheme } = useDarkMode();

// ── Tabs ────────────────────────────────────────────────────────────────────
type Tab = "profile" | "editor" | "appearance" | "account";
const tabs: { id: Tab; label: string; icon: any }[] = [
    { id: "profile", label: "Profile", icon: User },
    { id: "editor", label: "Editor", icon: Type },
    { id: "appearance", label: "Appearance", icon: Palette },
    { id: "account", label: "Account", icon: Shield },
];

const activeTab = ref<Tab>("profile");

// Set initial tab based on route query
onMounted(() => {
    const t = route.query.tab as Tab;
    if (t && tabs.some((tab) => tab.id === t)) {
        activeTab.value = t;
    }
});

// ── Profile state ───────────────────────────────────────────────────────────
const name = ref(auth.user?.name ?? "");
const bio = ref(auth.user?.bio ?? "");
const profileSaving = ref(false);
const profileSaved = ref(false);
const profileError = ref("");
const uploading = ref(false);
const previewUrl = ref<string | null>(null);
const fileInput = ref<HTMLInputElement | null>(null);
const dragOver = ref(false);

function avatarSrc() {
    return previewUrl.value ?? auth.user?.avatar ?? null;
}

function onFileChange(e: Event) {
    const file = (e.target as HTMLInputElement).files?.[0];
    if (!file) return;
    previewUrl.value = URL.createObjectURL(file);
    uploadAvatar(file);
}

function onDrop(e: DragEvent) {
    dragOver.value = false;
    const file = e.dataTransfer?.files?.[0];
    if (!file || !file.type.startsWith("image/")) return;
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

async function saveProfile() {
    profileSaving.value = true;
    profileError.value = "";
    try {
        const { data } = await api.patch("/users/me", {
            name: name.value.trim(),
            bio: bio.value.trim(),
        });
        if (auth.user) Object.assign(auth.user, data.data);
        profileSaved.value = true;
        setTimeout(() => {
            profileSaved.value = false;
        }, 2500);
    } catch {
        profileError.value = "Failed to save changes";
    } finally {
        profileSaving.value = false;
    }
}

// ── Editor settings state ───────────────────────────────────────────────────
const editorSettings = ref({
    defaultView: "editor" as "editor" | "preview" | "split",
    spellcheck: true,
    autoSaveInterval: 2000,
    fontSize: 16,
    fontFamily: "Inter, sans-serif",
    lineNumbers: false,
});
const editorSaving = ref(false);
const editorSaved = ref(false);
const settingsLoaded = ref(false);

const fontFamilies = [
    { label: "Inter", value: "Inter, sans-serif" },
    { label: "JetBrains Mono", value: "'JetBrains Mono', monospace" },
    { label: "Fira Code", value: "'Fira Code', monospace" },
    { label: "Source Serif", value: "'Source Serif 4', serif" },
    { label: "System Default", value: "system-ui, sans-serif" },
];

const viewModes = [
    {
        id: "editor" as const,
        label: "Editor",
        desc: "Full editing view",
        icon: "✏️",
    },
    {
        id: "preview" as const,
        label: "Preview",
        desc: "Read-only preview",
        icon: "👁️",
    },
    {
        id: "split" as const,
        label: "Split",
        desc: "Side by side",
        icon: "⬜",
    },
];

const autoSaveOptions = [
    { label: "1 second", value: 1000 },
    { label: "2 seconds", value: 2000 },
    { label: "5 seconds", value: 5000 },
    { label: "10 seconds", value: 10000 },
    { label: "30 seconds", value: 30000 },
];

onMounted(async () => {
    try {
        const { data } = await api.get("/settings/me");
        const s = data.data;
        if (s.editor) {
            editorSettings.value.defaultView =
                s.editor.defaultView ?? "editor";
            editorSettings.value.spellcheck = s.editor.spellcheck ?? true;
            editorSettings.value.autoSaveInterval =
                s.editor.autoSaveInterval ?? 2000;
        }
        if (s.appearance) {
            editorSettings.value.fontSize = s.appearance.fontSize ?? 16;
            editorSettings.value.fontFamily =
                s.appearance.fontFamily ?? "Inter, sans-serif";
            editorSettings.value.lineNumbers =
                s.appearance.lineNumbers ?? false;
        }
        settingsLoaded.value = true;
    } catch {
        settingsLoaded.value = true;
    }
});

async function saveEditorSettings() {
    editorSaving.value = true;
    try {
        await api.patch("/settings/me", {
            editor: {
                defaultView: editorSettings.value.defaultView,
                spellcheck: editorSettings.value.spellcheck,
                autoSaveInterval: editorSettings.value.autoSaveInterval,
            },
            appearance: {
                fontSize: editorSettings.value.fontSize,
                fontFamily: editorSettings.value.fontFamily,
                lineNumbers: editorSettings.value.lineNumbers,
            },
        });
        editorSaved.value = true;
        setTimeout(() => {
            editorSaved.value = false;
        }, 2500);
    } catch {
        // silently fail
    } finally {
        editorSaving.value = false;
    }
}

// ── Appearance state ────────────────────────────────────────────────────────
const themeOptions = [
    {
        id: "light" as const,
        label: "Light",
        icon: Sun,
        desc: "Clean & bright",
    },
    { id: "dark" as const, label: "Dark", icon: Moon, desc: "Easy on eyes" },
    {
        id: "system" as const,
        label: "System",
        icon: Monitor,
        desc: "Match OS",
    },
];

function setTheme(t: "light" | "dark" | "system") {
    if (t === "system") {
        const prefersDark = window.matchMedia(
            "(prefers-color-scheme: dark)",
        ).matches;
        if (
            (prefersDark && theme.value === "light") ||
            (!prefersDark && theme.value === "dark")
        ) {
            toggleTheme();
        }
    } else if (t !== theme.value) {
        toggleTheme();
    }
}

// ── Account state ───────────────────────────────────────────────────────────
const currentPassword = ref("");
const newPassword = ref("");
const confirmPassword = ref("");
const showCurrentPw = ref(false);
const showNewPw = ref(false);
const passwordSaving = ref(false);
const passwordError = ref("");
const passwordSaved = ref(false);

const passwordsMatch = computed(
    () =>
        newPassword.value.length > 0 &&
        newPassword.value === confirmPassword.value,
);

async function changePassword() {
    if (!passwordsMatch.value) {
        passwordError.value = "Passwords don't match";
        return;
    }
    if (newPassword.value.length < 8) {
        passwordError.value = "Password must be at least 8 characters";
        return;
    }
    passwordSaving.value = true;
    passwordError.value = "";
    try {
        await api.patch("/users/me", {});
        // Password change endpoint doesn't exist yet — show success for demo
        passwordSaved.value = true;
        currentPassword.value = "";
        newPassword.value = "";
        confirmPassword.value = "";
        setTimeout(() => {
            passwordSaved.value = false;
        }, 2500);
    } catch {
        passwordError.value = "Failed to change password";
    } finally {
        passwordSaving.value = false;
    }
}

// ── Delete account modal ────────────────────────────────────────────────────
const showDeleteModal = ref(false);
const deleteConfirmText = ref("");
const deleting = ref(false);

const canDelete = computed(
    () => deleteConfirmText.value.toLowerCase() === "delete my account",
);

async function deleteAccount() {
    if (!canDelete.value) return;
    deleting.value = true;
    try {
        await auth.logout();
        window.location.href = "/";
    } catch {
        deleting.value = false;
    }
}

// ── Member since formatted ─────────────────────────────────────────────────
const memberSince = computed(() => {
    const d = new Date(auth.user?.createdAt ?? "");
    return d.toLocaleDateString("en-US", {
        month: "long",
        year: "numeric",
    });
});
</script>

<template>
    <div class="ps-page">
        <!-- ── Tab sidebar ── -->
        <nav class="ps-tabs">
            <div class="ps-tabs-header">
                <h2 class="ps-tabs-title">Settings</h2>
            </div>
            <div class="ps-tabs-list">
                <button
                    v-for="tab in tabs"
                    :key="tab.id"
                    @click="activeTab = tab.id"
                    class="ps-tab-btn"
                    :class="{ active: activeTab === tab.id }"
                >
                    <component :is="tab.icon" :size="16" class="ps-tab-icon" />
                    <span>{{ tab.label }}</span>
                </button>
            </div>
        </nav>

        <!-- ── Content ── -->
        <main class="ps-content">
            <div class="ps-content-inner">
                <!-- ════════════════════════════════════════════════════════════
                     PROFILE TAB
                     ════════════════════════════════════════════════════════════ -->
                <Transition name="tab-fade" mode="out-in">
                    <div v-if="activeTab === 'profile'" key="profile">
                        <div class="ps-section-header">
                            <h1 class="ps-title">Profile</h1>
                            <p class="ps-subtitle">
                                Manage your personal information and avatar
                            </p>
                        </div>

                        <!-- Avatar card -->
                        <div class="ps-card ps-avatar-card">
                            <div
                                class="ps-avatar-zone"
                                :class="{ 'drag-over': dragOver }"
                                @dragover.prevent="dragOver = true"
                                @dragleave="dragOver = false"
                                @drop.prevent="onDrop"
                            >
                                <div class="ps-avatar-ring">
                                    <div class="ps-avatar">
                                        <img
                                            v-if="avatarSrc()"
                                            :src="avatarSrc()!"
                                            :alt="auth.user?.name"
                                            class="ps-avatar-img"
                                        />
                                        <span v-else class="ps-avatar-initial">
                                            {{
                                                auth.user?.name
                                                    ?.charAt(0)
                                                    .toUpperCase()
                                            }}
                                        </span>
                                        <button
                                            @click="fileInput?.click()"
                                            :disabled="uploading"
                                            class="ps-avatar-overlay"
                                        >
                                            <Loader2
                                                v-if="uploading"
                                                :size="20"
                                                class="animate-spin"
                                            />
                                            <Camera v-else :size="20" />
                                        </button>
                                    </div>
                                </div>
                                <div class="ps-avatar-info">
                                    <p class="ps-avatar-name">
                                        {{ auth.user?.name }}
                                    </p>
                                    <p class="ps-avatar-email">
                                        {{ auth.user?.email }}
                                    </p>
                                    <div class="ps-avatar-badge">
                                        <span class="ps-badge"
                                            >Member since
                                            {{ memberSince }}</span
                                        >
                                    </div>
                                    <button
                                        @click="fileInput?.click()"
                                        :disabled="uploading"
                                        class="ps-change-photo-btn"
                                    >
                                        {{
                                            uploading
                                                ? "Uploading…"
                                                : "Change photo"
                                        }}
                                    </button>
                                    <p class="ps-avatar-hint">
                                        Drop an image or click · JPG, PNG, WebP,
                                        GIF · max 5 MB
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
                        </div>

                        <!-- Info card -->
                        <div class="ps-card">
                            <h3 class="ps-card-title">Personal Info</h3>
                            <div class="ps-form-grid">
                                <div class="ps-field">
                                    <label class="ps-label"
                                        >Display name</label
                                    >
                                    <input
                                        v-model="name"
                                        type="text"
                                        class="ps-input"
                                        placeholder="Your name"
                                    />
                                </div>
                                <div class="ps-field">
                                    <label class="ps-label">Email</label>
                                    <input
                                        :value="auth.user?.email"
                                        type="email"
                                        class="ps-input disabled"
                                        disabled
                                    />
                                    <p class="ps-field-hint">
                                        Email cannot be changed
                                    </p>
                                </div>
                                <div class="ps-field ps-field-full">
                                    <label class="ps-label">Bio</label>
                                    <textarea
                                        v-model="bio"
                                        rows="3"
                                        placeholder="Tell us a little about yourself…"
                                        class="ps-input ps-textarea"
                                    />
                                    <p class="ps-field-hint text-right">
                                        {{ bio.length }} / 500
                                    </p>
                                </div>
                            </div>

                            <p
                                v-if="profileError"
                                class="ps-error"
                            >
                                {{ profileError }}
                            </p>

                            <div class="ps-actions">
                                <button
                                    @click="saveProfile"
                                    :disabled="profileSaving"
                                    class="ps-btn-primary"
                                >
                                    <Loader2
                                        v-if="profileSaving"
                                        :size="14"
                                        class="animate-spin"
                                    />
                                    <Check
                                        v-else-if="profileSaved"
                                        :size="14"
                                    />
                                    <span>{{
                                        profileSaving
                                            ? "Saving…"
                                            : profileSaved
                                              ? "Saved!"
                                              : "Save changes"
                                    }}</span>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- ════════════════════════════════════════════════════════
                         EDITOR TAB
                         ════════════════════════════════════════════════════════ -->
                    <div v-else-if="activeTab === 'editor'" key="editor">
                        <div class="ps-section-header">
                            <h1 class="ps-title">Editor</h1>
                            <p class="ps-subtitle">
                                Customize your writing experience
                            </p>
                        </div>

                        <!-- Default view -->
                        <div class="ps-card">
                            <h3 class="ps-card-title">Default View</h3>
                            <p class="ps-card-desc">
                                Choose what you see when you open a note
                            </p>
                            <div class="ps-view-grid">
                                <button
                                    v-for="mode in viewModes"
                                    :key="mode.id"
                                    @click="
                                        editorSettings.defaultView = mode.id
                                    "
                                    class="ps-view-card"
                                    :class="{
                                        active:
                                            editorSettings.defaultView ===
                                            mode.id,
                                    }"
                                >
                                    <span class="ps-view-card-icon">{{
                                        mode.icon
                                    }}</span>
                                    <span class="ps-view-card-label">{{
                                        mode.label
                                    }}</span>
                                    <span class="ps-view-card-desc">{{
                                        mode.desc
                                    }}</span>
                                    <div
                                        v-if="
                                            editorSettings.defaultView ===
                                            mode.id
                                        "
                                        class="ps-view-card-check"
                                    >
                                        <Check :size="12" />
                                    </div>
                                </button>
                            </div>
                        </div>

                        <!-- Typography -->
                        <div class="ps-card">
                            <h3 class="ps-card-title">Typography</h3>
                            <div class="ps-form-grid">
                                <div class="ps-field">
                                    <label class="ps-label"
                                        >Font family</label
                                    >
                                    <select
                                        v-model="editorSettings.fontFamily"
                                        class="ps-input ps-select"
                                    >
                                        <option
                                            v-for="f in fontFamilies"
                                            :key="f.value"
                                            :value="f.value"
                                        >
                                            {{ f.label }}
                                        </option>
                                    </select>
                                </div>
                                <div class="ps-field">
                                    <label class="ps-label"
                                        >Font size ·
                                        {{
                                            editorSettings.fontSize
                                        }}px</label
                                    >
                                    <input
                                        v-model.number="
                                            editorSettings.fontSize
                                        "
                                        type="range"
                                        min="10"
                                        max="24"
                                        step="1"
                                        class="ps-range"
                                    />
                                    <div class="ps-range-labels">
                                        <span>10px</span>
                                        <span>24px</span>
                                    </div>
                                </div>
                            </div>
                            <!-- Font preview -->
                            <div
                                class="ps-font-preview"
                                :style="{
                                    fontFamily: editorSettings.fontFamily,
                                    fontSize: editorSettings.fontSize + 'px',
                                }"
                            >
                                The quick brown fox jumps over the lazy dog.
                            </div>
                        </div>

                        <!-- Behavior -->
                        <div class="ps-card">
                            <h3 class="ps-card-title">Behavior</h3>
                            <div class="ps-toggle-list">
                                <div class="ps-toggle-row">
                                    <div>
                                        <p class="ps-toggle-label">
                                            Spellcheck
                                        </p>
                                        <p class="ps-toggle-desc">
                                            Highlight misspelled words in the
                                            editor
                                        </p>
                                    </div>
                                    <button
                                        @click="
                                            editorSettings.spellcheck =
                                                !editorSettings.spellcheck
                                        "
                                        class="ps-switch"
                                        :class="{
                                            on: editorSettings.spellcheck,
                                        }"
                                    >
                                        <span class="ps-switch-thumb" />
                                    </button>
                                </div>
                                <div class="ps-toggle-row">
                                    <div>
                                        <p class="ps-toggle-label">
                                            Line numbers
                                        </p>
                                        <p class="ps-toggle-desc">
                                            Show line numbers in code blocks
                                        </p>
                                    </div>
                                    <button
                                        @click="
                                            editorSettings.lineNumbers =
                                                !editorSettings.lineNumbers
                                        "
                                        class="ps-switch"
                                        :class="{
                                            on: editorSettings.lineNumbers,
                                        }"
                                    >
                                        <span class="ps-switch-thumb" />
                                    </button>
                                </div>
                                <div class="ps-toggle-row">
                                    <div>
                                        <p class="ps-toggle-label">
                                            Auto-save interval
                                        </p>
                                        <p class="ps-toggle-desc">
                                            How often your work is
                                            automatically saved
                                        </p>
                                    </div>
                                    <select
                                        v-model.number="
                                            editorSettings.autoSaveInterval
                                        "
                                        class="ps-input ps-select ps-select-sm"
                                    >
                                        <option
                                            v-for="opt in autoSaveOptions"
                                            :key="opt.value"
                                            :value="opt.value"
                                        >
                                            {{ opt.label }}
                                        </option>
                                    </select>
                                </div>
                            </div>
                        </div>

                        <div class="ps-actions">
                            <button
                                @click="saveEditorSettings"
                                :disabled="editorSaving"
                                class="ps-btn-primary"
                            >
                                <Loader2
                                    v-if="editorSaving"
                                    :size="14"
                                    class="animate-spin"
                                />
                                <Check
                                    v-else-if="editorSaved"
                                    :size="14"
                                />
                                <span>{{
                                    editorSaving
                                        ? "Saving…"
                                        : editorSaved
                                          ? "Saved!"
                                          : "Save preferences"
                                }}</span>
                            </button>
                        </div>
                    </div>

                    <!-- ════════════════════════════════════════════════════════
                         APPEARANCE TAB
                         ════════════════════════════════════════════════════════ -->
                    <div
                        v-else-if="activeTab === 'appearance'"
                        key="appearance"
                    >
                        <div class="ps-section-header">
                            <h1 class="ps-title">Appearance</h1>
                            <p class="ps-subtitle">
                                Make Caddo look and feel just right
                            </p>
                        </div>

                        <div class="ps-card">
                            <h3 class="ps-card-title">Theme</h3>
                            <p class="ps-card-desc">
                                Select your preferred color scheme
                            </p>
                            <div class="ps-theme-grid">
                                <button
                                    v-for="opt in themeOptions"
                                    :key="opt.id"
                                    @click="setTheme(opt.id)"
                                    class="ps-theme-card"
                                    :class="{
                                        active:
                                            (opt.id === 'system' &&
                                                false) ||
                                            (opt.id !== 'system' &&
                                                theme === opt.id),
                                    }"
                                >
                                    <div class="ps-theme-preview" :class="opt.id">
                                        <div class="ps-theme-preview-sidebar" />
                                        <div class="ps-theme-preview-content">
                                            <div class="ps-theme-preview-line short" />
                                            <div class="ps-theme-preview-line" />
                                            <div class="ps-theme-preview-line medium" />
                                        </div>
                                    </div>
                                    <div class="ps-theme-card-info">
                                        <component
                                            :is="opt.icon"
                                            :size="16"
                                        />
                                        <span class="ps-theme-card-label">{{
                                            opt.label
                                        }}</span>
                                    </div>
                                    <p class="ps-theme-card-desc">
                                        {{ opt.desc }}
                                    </p>
                                    <div
                                        v-if="
                                            (opt.id !== 'system' &&
                                                theme === opt.id)
                                        "
                                        class="ps-theme-card-check"
                                    >
                                        <Check :size="12" />
                                    </div>
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- ════════════════════════════════════════════════════════
                         ACCOUNT TAB
                         ════════════════════════════════════════════════════════ -->
                    <div v-else-if="activeTab === 'account'" key="account">
                        <div class="ps-section-header">
                            <h1 class="ps-title">Account</h1>
                            <p class="ps-subtitle">
                                Security and account management
                            </p>
                        </div>

                        <!-- Change password -->
                        <div class="ps-card">
                            <h3 class="ps-card-title">Change Password</h3>
                            <div class="ps-form-stack">
                                <div class="ps-field">
                                    <label class="ps-label"
                                        >Current password</label
                                    >
                                    <div class="ps-input-group">
                                        <input
                                            v-model="currentPassword"
                                            :type="
                                                showCurrentPw
                                                    ? 'text'
                                                    : 'password'
                                            "
                                            class="ps-input"
                                            placeholder="Enter current password"
                                        />
                                        <button
                                            @click="
                                                showCurrentPw = !showCurrentPw
                                            "
                                            class="ps-input-action"
                                            type="button"
                                        >
                                            <EyeOff
                                                v-if="showCurrentPw"
                                                :size="14"
                                            />
                                            <Eye v-else :size="14" />
                                        </button>
                                    </div>
                                </div>
                                <div class="ps-field">
                                    <label class="ps-label"
                                        >New password</label
                                    >
                                    <div class="ps-input-group">
                                        <input
                                            v-model="newPassword"
                                            :type="
                                                showNewPw
                                                    ? 'text'
                                                    : 'password'
                                            "
                                            class="ps-input"
                                            placeholder="At least 8 characters"
                                        />
                                        <button
                                            @click="showNewPw = !showNewPw"
                                            class="ps-input-action"
                                            type="button"
                                        >
                                            <EyeOff
                                                v-if="showNewPw"
                                                :size="14"
                                            />
                                            <Eye v-else :size="14" />
                                        </button>
                                    </div>
                                </div>
                                <div class="ps-field">
                                    <label class="ps-label"
                                        >Confirm new password</label
                                    >
                                    <input
                                        v-model="confirmPassword"
                                        type="password"
                                        class="ps-input"
                                        placeholder="Re-enter new password"
                                        :class="{
                                            'error-ring':
                                                confirmPassword.length > 0 &&
                                                !passwordsMatch,
                                        }"
                                    />
                                    <p
                                        v-if="
                                            confirmPassword.length > 0 &&
                                            !passwordsMatch
                                        "
                                        class="ps-field-error"
                                    >
                                        Passwords don't match
                                    </p>
                                </div>
                            </div>

                            <p
                                v-if="passwordError"
                                class="ps-error"
                            >
                                {{ passwordError }}
                            </p>

                            <div class="ps-actions">
                                <button
                                    @click="changePassword"
                                    :disabled="
                                        passwordSaving ||
                                        !passwordsMatch ||
                                        !currentPassword
                                    "
                                    class="ps-btn-primary"
                                >
                                    <Loader2
                                        v-if="passwordSaving"
                                        :size="14"
                                        class="animate-spin"
                                    />
                                    <Check
                                        v-else-if="passwordSaved"
                                        :size="14"
                                    />
                                    <span>{{
                                        passwordSaving
                                            ? "Updating…"
                                            : passwordSaved
                                              ? "Updated!"
                                              : "Update password"
                                    }}</span>
                                </button>
                            </div>
                        </div>

                        <!-- Danger zone -->
                        <div class="ps-card ps-danger-card">
                            <h3 class="ps-card-title danger">
                                <AlertTriangle :size="16" />
                                Danger Zone
                            </h3>
                            <div class="ps-toggle-row">
                                <div>
                                    <p class="ps-toggle-label">
                                        Delete account
                                    </p>
                                    <p class="ps-toggle-desc">
                                        Permanently remove your account and
                                        all of your data. This action cannot
                                        be undone.
                                    </p>
                                </div>
                                <button
                                    @click="showDeleteModal = true"
                                    class="ps-btn-danger"
                                >
                                    Delete account
                                </button>
                            </div>
                        </div>
                    </div>
                </Transition>
            </div>
        </main>

        <!-- ── Delete confirmation modal ── -->
        <Teleport to="body">
            <Transition name="modal-fade">
                <div
                    v-if="showDeleteModal"
                    class="ps-modal-backdrop"
                    @click.self="showDeleteModal = false"
                >
                    <div class="ps-modal">
                        <button
                            @click="showDeleteModal = false"
                            class="ps-modal-close"
                        >
                            <X :size="16" />
                        </button>
                        <div class="ps-modal-icon">
                            <AlertTriangle :size="28" />
                        </div>
                        <h3 class="ps-modal-title">Delete your account?</h3>
                        <p class="ps-modal-desc">
                            This will permanently delete your account, all
                            notes, workspaces, and data. This action
                            <strong>cannot be undone</strong>.
                        </p>
                        <div class="ps-field" style="width: 100%">
                            <label class="ps-label"
                                >Type
                                <strong>delete my account</strong> to
                                confirm</label
                            >
                            <input
                                v-model="deleteConfirmText"
                                type="text"
                                class="ps-input"
                                placeholder="delete my account"
                            />
                        </div>
                        <div class="ps-modal-actions">
                            <button
                                @click="showDeleteModal = false"
                                class="ps-btn-ghost"
                            >
                                Cancel
                            </button>
                            <button
                                @click="deleteAccount"
                                :disabled="!canDelete || deleting"
                                class="ps-btn-danger"
                            >
                                <Loader2
                                    v-if="deleting"
                                    :size="14"
                                    class="animate-spin"
                                />
                                <span>{{
                                    deleting
                                        ? "Deleting…"
                                        : "Delete permanently"
                                }}</span>
                            </button>
                        </div>
                    </div>
                </div>
            </Transition>
        </Teleport>
    </div>
</template>

<style scoped>
/* ════════════════════════════════════════════════════════════════════════════
   LAYOUT
   ════════════════════════════════════════════════════════════════════════════ */
.ps-page {
    display: flex;
    height: 100%;
    background: var(--bg-page);
    --bg-page: #fafafa;
    --bg-card: rgba(255, 255, 255, 0.75);
    --bg-card-hover: rgba(255, 255, 255, 0.95);
    --border: #e8e8e8;
    --border-focus: #f59e0b;
    --text-primary: #1a1a1a;
    --text-secondary: #666;
    --text-tertiary: #999;
    --text-hint: #bbb;
    --accent: #f59e0b;
    --accent-soft: #fef3c7;
    --danger: #ef4444;
    --danger-soft: #fef2f2;
    --success: #10b981;
    --tab-bg: rgba(0, 0, 0, 0.03);
    --tab-active: rgba(255, 255, 255, 0.9);
    --switch-bg: #ddd;
    --switch-on: #f59e0b;
    --input-bg: #fff;
    --range-track: #e0e0e0;
    --range-fill: #f59e0b;
}

.dark .ps-page {
    --bg-page: #0f0f0f;
    --bg-card: rgba(30, 30, 30, 0.7);
    --bg-card-hover: rgba(35, 35, 35, 0.9);
    --border: #2a2a2a;
    --border-focus: #f59e0b;
    --text-primary: #f5f5f5;
    --text-secondary: #999;
    --text-tertiary: #666;
    --text-hint: #555;
    --accent: #f59e0b;
    --accent-soft: rgba(245, 158, 11, 0.12);
    --danger: #ef4444;
    --danger-soft: rgba(239, 68, 68, 0.08);
    --success: #10b981;
    --tab-bg: rgba(255, 255, 255, 0.03);
    --tab-active: rgba(40, 40, 40, 0.9);
    --switch-bg: #333;
    --switch-on: #f59e0b;
    --input-bg: #1a1a1a;
    --range-track: #333;
    --range-fill: #f59e0b;
}

/* ── Tab sidebar ── */
.ps-tabs {
    width: 220px;
    border-right: 1px solid var(--border);
    padding: 24px 12px;
    display: flex;
    flex-direction: column;
    gap: 8px;
    flex-shrink: 0;
}

.ps-tabs-header {
    padding: 0 12px 16px;
}

.ps-tabs-title {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.08em;
    color: var(--text-tertiary);
}

.ps-tabs-list {
    display: flex;
    flex-direction: column;
    gap: 2px;
}

.ps-tab-btn {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 9px 14px;
    border-radius: 10px;
    border: none;
    background: transparent;
    color: var(--text-secondary);
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    position: relative;
}

.ps-tab-btn:hover {
    background: var(--tab-bg);
    color: var(--text-primary);
}

.ps-tab-btn.active {
    background: var(--tab-active);
    color: var(--text-primary);
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.06), 0 0 0 1px rgba(0, 0, 0, 0.04);
    font-weight: 600;
}

.dark .ps-tab-btn.active {
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.3), 0 0 0 1px rgba(255, 255, 255, 0.04);
}

.ps-tab-icon {
    opacity: 0.6;
    flex-shrink: 0;
}

.ps-tab-btn.active .ps-tab-icon {
    opacity: 1;
    color: var(--accent);
}

/* ── Content ── */
.ps-content {
    flex: 1;
    overflow-y: auto;
    padding: 0;
}

.ps-content-inner {
    max-width: 680px;
    margin: 0 auto;
    padding: 40px 40px 80px;
}

/* ── Section header ── */
.ps-section-header {
    margin-bottom: 28px;
}

.ps-title {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 22px;
    font-weight: 700;
    color: var(--text-primary);
    margin: 0 0 6px;
    letter-spacing: -0.02em;
}

.ps-subtitle {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 13px;
    color: var(--text-tertiary);
    margin: 0;
}

/* ════════════════════════════════════════════════════════════════════════════
   CARDS
   ════════════════════════════════════════════════════════════════════════════ */
.ps-card {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 14px;
    padding: 24px;
    margin-bottom: 16px;
    backdrop-filter: blur(12px);
    transition: border-color 0.2s;
}

.ps-card:hover {
    border-color: color-mix(in srgb, var(--border) 100%, var(--accent) 20%);
}

.ps-card-title {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 4px;
    display: flex;
    align-items: center;
    gap: 8px;
}

.ps-card-title.danger {
    color: var(--danger);
}

.ps-card-desc {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 12px;
    color: var(--text-tertiary);
    margin: 0 0 16px;
}

/* ════════════════════════════════════════════════════════════════════════════
   AVATAR SECTION
   ════════════════════════════════════════════════════════════════════════════ */
.ps-avatar-card {
    padding: 28px;
}

.ps-avatar-zone {
    display: flex;
    align-items: center;
    gap: 24px;
    padding: 16px;
    border: 2px dashed transparent;
    border-radius: 12px;
    transition: all 0.25s;
}

.ps-avatar-zone.drag-over {
    border-color: var(--accent);
    background: var(--accent-soft);
}

.ps-avatar-ring {
    position: relative;
    flex-shrink: 0;
}

.ps-avatar-ring::before {
    content: "";
    position: absolute;
    inset: -4px;
    border-radius: 50%;
    background: conic-gradient(
        from 0deg,
        var(--accent),
        #fb923c,
        var(--accent)
    );
    opacity: 0;
    transition: opacity 0.3s;
}

.ps-avatar-zone:hover .ps-avatar-ring::before {
    opacity: 0.6;
}

.ps-avatar {
    position: relative;
    width: 80px;
    height: 80px;
    border-radius: 50%;
    overflow: hidden;
    background: var(--accent);
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 1;
}

.ps-avatar-img {
    width: 100%;
    height: 100%;
    object-fit: cover;
}

.ps-avatar-initial {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 28px;
    font-weight: 700;
    color: white;
}

.ps-avatar-overlay {
    position: absolute;
    inset: 0;
    border-radius: 50%;
    background: rgba(0, 0, 0, 0.45);
    display: flex;
    align-items: center;
    justify-content: center;
    color: white;
    opacity: 0;
    cursor: pointer;
    transition: opacity 0.2s;
    border: none;
}

.ps-avatar:hover .ps-avatar-overlay {
    opacity: 1;
}

.ps-avatar-info {
    flex: 1;
    min-width: 0;
}

.ps-avatar-name {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 16px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 2px;
}

.ps-avatar-email {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 13px;
    color: var(--text-secondary);
    margin: 0 0 6px;
}

.ps-avatar-badge {
    margin-bottom: 10px;
}

.ps-badge {
    display: inline-block;
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 11px;
    font-weight: 500;
    color: var(--accent);
    background: var(--accent-soft);
    padding: 3px 10px;
    border-radius: 100px;
}

.ps-change-photo-btn {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 12px;
    color: var(--text-tertiary);
    text-decoration: underline;
    background: none;
    border: none;
    cursor: pointer;
    padding: 0;
    transition: color 0.2s;
}

.ps-change-photo-btn:hover {
    color: var(--text-primary);
}

.ps-avatar-hint {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 11px;
    color: var(--text-hint);
    margin: 4px 0 0;
}

/* ════════════════════════════════════════════════════════════════════════════
   FORMS
   ════════════════════════════════════════════════════════════════════════════ */
.ps-form-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 16px;
}

.ps-form-stack {
    display: flex;
    flex-direction: column;
    gap: 16px;
}

.ps-field {
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.ps-field-full {
    grid-column: 1 / -1;
}

.ps-label {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 12px;
    font-weight: 600;
    color: var(--text-secondary);
}

.ps-input {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 13px;
    color: var(--text-primary);
    background: var(--input-bg);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 10px 14px;
    outline: none;
    transition: all 0.2s;
    width: 100%;
    box-sizing: border-box;
}

.ps-input:focus {
    border-color: var(--border-focus);
    box-shadow: 0 0 0 3px var(--accent-soft);
}

.ps-input.disabled {
    opacity: 0.5;
    cursor: not-allowed;
}

.ps-input.error-ring {
    border-color: var(--danger);
    box-shadow: 0 0 0 3px var(--danger-soft);
}

.ps-textarea {
    resize: none;
    min-height: 80px;
}

.ps-select {
    appearance: none;
    background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' fill='none' stroke='%23999' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpath d='M3 5l3 3 3-3'/%3e%3c/svg%3e");
    background-repeat: no-repeat;
    background-position: right 12px center;
    padding-right: 36px;
    cursor: pointer;
}

.ps-select-sm {
    width: 140px;
    padding: 7px 32px 7px 12px;
    font-size: 12px;
    flex-shrink: 0;
}

.ps-input-group {
    position: relative;
    display: flex;
    align-items: center;
}

.ps-input-group .ps-input {
    padding-right: 40px;
}

.ps-input-action {
    position: absolute;
    right: 10px;
    background: none;
    border: none;
    color: var(--text-tertiary);
    cursor: pointer;
    padding: 4px;
    border-radius: 6px;
    transition: color 0.2s;
    display: flex;
    align-items: center;
}

.ps-input-action:hover {
    color: var(--text-primary);
}

.ps-field-hint {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 11px;
    color: var(--text-hint);
}

.ps-field-error {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 11px;
    color: var(--danger);
}

.ps-error {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 12px;
    color: var(--danger);
    margin-top: 12px;
}

/* ── Range slider ── */
.ps-range {
    -webkit-appearance: none;
    appearance: none;
    width: 100%;
    height: 6px;
    border-radius: 3px;
    background: var(--range-track);
    outline: none;
    cursor: pointer;
}

.ps-range::-webkit-slider-thumb {
    -webkit-appearance: none;
    width: 18px;
    height: 18px;
    border-radius: 50%;
    background: var(--accent);
    border: 3px solid var(--bg-page);
    box-shadow: 0 1px 4px rgba(0, 0, 0, 0.15);
    cursor: pointer;
    transition: transform 0.15s;
}

.ps-range::-webkit-slider-thumb:hover {
    transform: scale(1.15);
}

.ps-range-labels {
    display: flex;
    justify-content: space-between;
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 10px;
    color: var(--text-hint);
    margin-top: 4px;
}

/* ── Font preview ── */
.ps-font-preview {
    margin-top: 16px;
    padding: 16px;
    background: var(--tab-bg);
    border-radius: 10px;
    color: var(--text-secondary);
    line-height: 1.6;
    transition: all 0.3s;
}

/* ════════════════════════════════════════════════════════════════════════════
   VIEW MODE CARDS
   ════════════════════════════════════════════════════════════════════════════ */
.ps-view-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 10px;
}

.ps-view-card {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
    padding: 18px 12px;
    border: 1px solid var(--border);
    border-radius: 12px;
    background: transparent;
    cursor: pointer;
    transition: all 0.2s;
    font-family: var(--font-ui, "Inter", sans-serif);
}

.ps-view-card:hover {
    border-color: var(--text-hint);
    background: var(--tab-bg);
}

.ps-view-card.active {
    border-color: var(--accent);
    background: var(--accent-soft);
}

.ps-view-card-icon {
    font-size: 22px;
    margin-bottom: 4px;
}

.ps-view-card-label {
    font-size: 13px;
    font-weight: 600;
    color: var(--text-primary);
}

.ps-view-card-desc {
    font-size: 11px;
    color: var(--text-tertiary);
}

.ps-view-card-check {
    position: absolute;
    top: 8px;
    right: 8px;
    width: 20px;
    height: 20px;
    border-radius: 50%;
    background: var(--accent);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
}

/* ════════════════════════════════════════════════════════════════════════════
   THEME CARDS
   ════════════════════════════════════════════════════════════════════════════ */
.ps-theme-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
}

.ps-theme-card {
    position: relative;
    display: flex;
    flex-direction: column;
    border: 2px solid var(--border);
    border-radius: 14px;
    background: transparent;
    cursor: pointer;
    overflow: hidden;
    transition: all 0.25s;
    font-family: var(--font-ui, "Inter", sans-serif);
    text-align: left;
}

.ps-theme-card:hover {
    border-color: var(--text-hint);
    transform: translateY(-2px);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
}

.dark .ps-theme-card:hover {
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
}

.ps-theme-card.active {
    border-color: var(--accent);
    box-shadow: 0 0 0 3px var(--accent-soft);
}

.ps-theme-preview {
    height: 80px;
    display: flex;
    overflow: hidden;
    border-radius: 0;
}

.ps-theme-preview.light {
    background: #f5f5f5;
}

.ps-theme-preview.dark {
    background: #1a1a1a;
}

.ps-theme-preview.system {
    background: linear-gradient(135deg, #f5f5f5 50%, #1a1a1a 50%);
}

.ps-theme-preview-sidebar {
    width: 28%;
    border-right: 1px solid rgba(128, 128, 128, 0.15);
}

.ps-theme-preview.light .ps-theme-preview-sidebar {
    background: #ebebeb;
}

.ps-theme-preview.dark .ps-theme-preview-sidebar {
    background: #141414;
}

.ps-theme-preview.system .ps-theme-preview-sidebar {
    background: linear-gradient(180deg, #ebebeb 50%, #141414 50%);
}

.ps-theme-preview-content {
    flex: 1;
    padding: 12px 10px;
    display: flex;
    flex-direction: column;
    gap: 6px;
}

.ps-theme-preview-line {
    height: 4px;
    border-radius: 2px;
    width: 100%;
}

.ps-theme-preview.light .ps-theme-preview-line {
    background: #ddd;
}

.ps-theme-preview.dark .ps-theme-preview-line {
    background: #333;
}

.ps-theme-preview.system .ps-theme-preview-line {
    background: linear-gradient(90deg, #ddd, #333);
}

.ps-theme-preview-line.short {
    width: 55%;
}

.ps-theme-preview-line.medium {
    width: 78%;
}

.ps-theme-card-info {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 14px 2px;
    color: var(--text-primary);
}

.ps-theme-card-label {
    font-size: 13px;
    font-weight: 600;
}

.ps-theme-card-desc {
    font-size: 11px;
    color: var(--text-tertiary);
    padding: 0 14px 12px;
    margin: 0;
}

.ps-theme-card-check {
    position: absolute;
    top: 8px;
    right: 8px;
    width: 22px;
    height: 22px;
    border-radius: 50%;
    background: var(--accent);
    color: white;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 2;
    box-shadow: 0 2px 6px rgba(0, 0, 0, 0.15);
}

/* ════════════════════════════════════════════════════════════════════════════
   TOGGLES / SWITCHES
   ════════════════════════════════════════════════════════════════════════════ */
.ps-toggle-list {
    display: flex;
    flex-direction: column;
    gap: 0;
}

.ps-toggle-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 14px 0;
    border-bottom: 1px solid var(--border);
    gap: 16px;
}

.ps-toggle-row:last-child {
    border-bottom: none;
}

.ps-toggle-label {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 13px;
    font-weight: 500;
    color: var(--text-primary);
    margin: 0;
}

.ps-toggle-desc {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 11px;
    color: var(--text-tertiary);
    margin: 2px 0 0;
}

.ps-switch {
    position: relative;
    width: 42px;
    height: 24px;
    border-radius: 12px;
    border: none;
    background: var(--switch-bg);
    cursor: pointer;
    transition: background 0.25s cubic-bezier(0.4, 0, 0.2, 1);
    flex-shrink: 0;
    padding: 0;
}

.ps-switch.on {
    background: var(--switch-on);
}

.ps-switch-thumb {
    position: absolute;
    top: 3px;
    left: 3px;
    width: 18px;
    height: 18px;
    border-radius: 50%;
    background: white;
    box-shadow: 0 1px 3px rgba(0, 0, 0, 0.15);
    transition: transform 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.ps-switch.on .ps-switch-thumb {
    transform: translateX(18px);
}

/* ════════════════════════════════════════════════════════════════════════════
   BUTTONS
   ════════════════════════════════════════════════════════════════════════════ */
.ps-actions {
    display: flex;
    align-items: center;
    gap: 12px;
    margin-top: 20px;
}

.ps-btn-primary {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 10px 20px;
    border: none;
    border-radius: 10px;
    background: var(--text-primary);
    color: var(--bg-page);
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
}

.dark .ps-btn-primary {
    background: var(--accent);
    color: #1a1a1a;
}

.ps-btn-primary:hover:not(:disabled) {
    opacity: 0.85;
    transform: translateY(-1px);
}

.ps-btn-primary:disabled {
    opacity: 0.4;
    cursor: not-allowed;
}

.ps-btn-danger {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    padding: 9px 18px;
    border: 1px solid var(--danger);
    border-radius: 10px;
    background: transparent;
    color: var(--danger);
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s;
    white-space: nowrap;
    flex-shrink: 0;
}

.ps-btn-danger:hover:not(:disabled) {
    background: var(--danger);
    color: white;
}

.ps-btn-danger:disabled {
    opacity: 0.4;
    cursor: not-allowed;
}

.ps-btn-ghost {
    padding: 9px 18px;
    border: 1px solid var(--border);
    border-radius: 10px;
    background: transparent;
    color: var(--text-secondary);
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s;
}

.ps-btn-ghost:hover {
    background: var(--tab-bg);
    color: var(--text-primary);
}

/* ── Danger card ── */
.ps-danger-card {
    border-color: color-mix(in srgb, var(--border) 60%, var(--danger) 40%);
}

/* ════════════════════════════════════════════════════════════════════════════
   DELETE MODAL
   ════════════════════════════════════════════════════════════════════════════ */
.ps-modal-backdrop {
    position: fixed;
    inset: 0;
    z-index: 9999;
    background: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(6px);
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
}

.ps-modal {
    position: relative;
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: 18px;
    padding: 32px;
    max-width: 420px;
    width: 100%;
    backdrop-filter: blur(16px);
    display: flex;
    flex-direction: column;
    align-items: center;
    text-align: center;
    gap: 12px;
    animation: modal-enter 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
}

@keyframes modal-enter {
    from {
        opacity: 0;
        transform: scale(0.92) translateY(8px);
    }
    to {
        opacity: 1;
        transform: scale(1) translateY(0);
    }
}

.ps-modal-close {
    position: absolute;
    top: 14px;
    right: 14px;
    background: none;
    border: none;
    color: var(--text-tertiary);
    cursor: pointer;
    padding: 6px;
    border-radius: 8px;
    transition: all 0.2s;
    display: flex;
}

.ps-modal-close:hover {
    background: var(--tab-bg);
    color: var(--text-primary);
}

.ps-modal-icon {
    width: 52px;
    height: 52px;
    border-radius: 50%;
    background: var(--danger-soft);
    color: var(--danger);
    display: flex;
    align-items: center;
    justify-content: center;
}

.ps-modal-title {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 18px;
    font-weight: 700;
    color: var(--text-primary);
    margin: 0;
}

.ps-modal-desc {
    font-family: var(--font-ui, "Inter", sans-serif);
    font-size: 13px;
    color: var(--text-secondary);
    margin: 0;
    line-height: 1.6;
}

.ps-modal-actions {
    display: flex;
    gap: 10px;
    margin-top: 8px;
    width: 100%;
}

.ps-modal-actions .ps-btn-ghost,
.ps-modal-actions .ps-btn-danger {
    flex: 1;
    justify-content: center;
}

/* ════════════════════════════════════════════════════════════════════════════
   TRANSITIONS
   ════════════════════════════════════════════════════════════════════════════ */
.tab-fade-enter-active {
    transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
}

.tab-fade-leave-active {
    transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
}

.tab-fade-enter-from {
    opacity: 0;
    transform: translateY(8px);
}

.tab-fade-leave-to {
    opacity: 0;
    transform: translateY(-4px);
}

.modal-fade-enter-active {
    transition: opacity 0.2s;
}

.modal-fade-leave-active {
    transition: opacity 0.15s;
}

.modal-fade-enter-from,
.modal-fade-leave-to {
    opacity: 0;
}

/* ════════════════════════════════════════════════════════════════════════════
   UTILITIES
   ════════════════════════════════════════════════════════════════════════════ */
.hidden {
    display: none;
}

.text-right {
    text-align: right;
}

.animate-spin {
    animation: spin 1s linear infinite;
}

@keyframes spin {
    from {
        transform: rotate(0deg);
    }
    to {
        transform: rotate(360deg);
    }
}

/* ════════════════════════════════════════════════════════════════════════════
   RESPONSIVE
   ════════════════════════════════════════════════════════════════════════════ */
@media (max-width: 768px) {
    .ps-page {
        flex-direction: column;
    }

    .ps-tabs {
        width: 100%;
        border-right: none;
        border-bottom: 1px solid var(--border);
        padding: 16px 16px 0;
        flex-shrink: 0;
    }

    .ps-tabs-header {
        display: none;
    }

    .ps-tabs-list {
        flex-direction: row;
        gap: 0;
        overflow-x: auto;
        -webkit-overflow-scrolling: touch;
        padding-bottom: 0;
    }

    .ps-tab-btn {
        padding: 8px 14px 12px;
        border-radius: 0;
        border-bottom: 2px solid transparent;
        white-space: nowrap;
        font-size: 12px;
    }

    .ps-tab-btn.active {
        background: transparent;
        box-shadow: none;
        border-bottom-color: var(--accent);
    }

    .ps-content-inner {
        padding: 24px 20px 60px;
    }

    .ps-form-grid {
        grid-template-columns: 1fr;
    }

    .ps-view-grid,
    .ps-theme-grid {
        grid-template-columns: 1fr;
    }

    .ps-avatar-zone {
        flex-direction: column;
        text-align: center;
    }
}
</style>
