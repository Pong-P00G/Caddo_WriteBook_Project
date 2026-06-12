<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useBooksStore } from '@/store/books'

const router = useRouter()
const store  = useBooksStore()

const title       = ref('')
const description = ref('')
const visibility  = ref<'private' | 'unlisted' | 'public'>('private')
const loading     = ref(false)
const error       = ref('')

async function handleCreate() {
  if (!title.value.trim()) return
  error.value   = ''
  loading.value = true
  try {
    const book = await store.createBook({
      title: title.value.trim(),
      description: description.value.trim(),
      visibility: visibility.value,
    })
    router.push(`/app/books/${book._id}`)
  } catch {
    error.value = 'Failed to create book. Please try again.'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="p-6 max-w-xl mx-auto">
    <h1 class="font-display text-2xl font-bold text-ink-900 mb-8">Start a new book</h1>

    <form @submit.prevent="handleCreate" class="space-y-5">
      <div>
        <label class="block text-sm font-ui font-medium text-ink-700 mb-1.5">Title <span class="text-red-500">*</span></label>
        <input
          v-model="title"
          type="text"
          required
          placeholder="My Great Novel"
          class="w-full px-3.5 py-2.5 rounded-lg border border-ink-200 bg-white text-ink-900 placeholder-ink-300 font-ui text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent transition"
        />
      </div>

      <div>
        <label class="block text-sm font-ui font-medium text-ink-700 mb-1.5">Description</label>
        <textarea
          v-model="description"
          rows="3"
          placeholder="A brief description of your book…"
          class="w-full px-3.5 py-2.5 rounded-lg border border-ink-200 bg-white text-ink-900 placeholder-ink-300 font-ui text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent transition resize-none"
        />
      </div>

      <div>
        <label class="block text-sm font-ui font-medium text-ink-700 mb-2">Visibility</label>
        <div class="space-y-2">
          <label
            v-for="opt in [
              { value: 'private',  label: 'Private',  hint: 'Only you can read this' },
              { value: 'unlisted', label: 'Unlisted', hint: 'Anyone with the link can read' },
              { value: 'public',   label: 'Public',   hint: 'Listed publicly for everyone' },
            ]"
            :key="opt.value"
            class="flex items-start gap-3 p-3 rounded-lg border cursor-pointer transition-colors"
            :class="visibility === opt.value
              ? 'border-amber-400 bg-amber-50'
              : 'border-ink-200 bg-white hover:border-ink-300'"
          >
            <input
              type="radio"
              :value="opt.value"
              v-model="visibility"
              class="mt-0.5 accent-amber-500"
            />
            <div>
              <div class="text-sm font-medium text-ink-800 font-ui">{{ opt.label }}</div>
              <div class="text-xs text-ink-500 font-ui">{{ opt.hint }}</div>
            </div>
          </label>
        </div>
      </div>

      <p v-if="error" class="text-sm text-red-600 font-ui">{{ error }}</p>

      <div class="flex items-center gap-3 pt-2">
        <button
          type="submit"
          :disabled="!title.trim() || loading"
          class="px-6 py-2.5 bg-amber-500 hover:bg-amber-600 disabled:opacity-50 text-ink-950 rounded-lg font-ui font-semibold text-sm transition-colors"
        >
          {{ loading ? 'Creating…' : 'Create Book' }}
        </button>
        <button
          type="button"
          @click="router.back()"
          class="px-6 py-2.5 text-ink-500 hover:text-ink-700 font-ui text-sm transition-colors"
        >
          Cancel
        </button>
      </div>
    </form>
  </div>
</template>