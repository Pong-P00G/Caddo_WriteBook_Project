<script setup lang="ts">
import { ref } from 'vue'
import { useAuthStore } from '@/store/auth'
import api from '@/api/Api'

const auth  = useAuthStore()
const name  = ref(auth.user?.name ?? '')
const bio   = ref(auth.user?.bio ?? '')
const saved = ref(false)
const loading = ref(false)

async function handleSave() {
  loading.value = true
  try {
    const { data } = await api.patch('/users/me', { name: name.value, bio: bio.value })
    if (auth.user) Object.assign(auth.user, data.data)
    saved.value = true
    setTimeout(() => { saved.value = false }, 2000)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="p-6 max-w-xl mx-auto">
    <h1 class="font-display text-2xl font-bold text-ink-900 mb-8">Account settings</h1>

    <div class="bg-white rounded-2xl border border-ink-100 p-6 space-y-5">
      <!-- Avatar placeholder -->
      <div class="flex items-center gap-4">
        <div class="w-16 h-16 rounded-full bg-amber-500 flex items-center justify-center text-ink-950 text-2xl font-bold font-display">
          {{ auth.user?.name?.charAt(0).toUpperCase() }}
        </div>
        <div>
          <p class="font-ui font-medium text-ink-800">{{ auth.user?.email }}</p>
          <p class="text-xs text-ink-400 font-ui mt-0.5">Member since {{ new Date(auth.user?.createdAt ?? '').getFullYear() }}</p>
        </div>
      </div>

      <div class="border-t border-ink-100 pt-5 space-y-4">
        <div>
          <label class="block text-sm font-ui font-medium text-ink-700 mb-1.5">Display name</label>
          <input
            v-model="name"
            type="text"
            class="w-full px-3.5 py-2.5 rounded-lg border border-ink-200 bg-white text-ink-900 font-ui text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent transition"
          />
        </div>

        <div>
          <label class="block text-sm font-ui font-medium text-ink-700 mb-1.5">Bio</label>
          <textarea
            v-model="bio"
            rows="3"
            placeholder="Tell readers a little about yourself…"
            class="w-full px-3.5 py-2.5 rounded-lg border border-ink-200 bg-white text-ink-900 placeholder-ink-300 font-ui text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent transition resize-none"
          />
        </div>
      </div>

      <div class="flex items-center gap-3">
        <button
          @click="handleSave"
          :disabled="loading"
          class="px-5 py-2.5 bg-amber-500 hover:bg-amber-600 disabled:opacity-50 text-ink-950 rounded-lg font-ui font-semibold text-sm transition-colors"
        >
          {{ loading ? 'Saving…' : 'Save changes' }}
        </button>
        <span v-if="saved" class="text-sm text-green-600 font-ui">Saved!</span>
      </div>
    </div>
  </div>
</template>