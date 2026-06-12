<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/store/auth'
import { BookOpen } from 'lucide-vue-next'

const router = useRouter()
const auth   = useAuthStore()

const name     = ref('')
const email    = ref('')
const password = ref('')
const error    = ref('')
const loading  = ref(false)

async function handleRegister() {
  error.value   = ''
  loading.value = true
  try {
    await auth.register(name.value, email.value, password.value)
    router.push('/app/library')
  } catch (e: unknown) {
    error.value = (e as { response?: { data?: { message?: string } } })?.response?.data?.message ?? 'Registration failed'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-parchment flex items-center justify-center p-4">
    <div class="w-full max-w-sm">
      <div class="flex items-center gap-2.5 justify-center mb-10">
        <div class="w-9 h-9 bg-amber-500 rounded-lg flex items-center justify-center">
          <BookOpen :size="18" class="text-ink-950" />
        </div>
        <span class="font-display text-2xl font-bold text-ink-900">Writebook</span>
      </div>

      <div class="bg-white rounded-2xl border border-ink-100 shadow-sm p-8 relative overflow-hidden">
        <!-- Progress bar -->
        <div v-if="loading" class="absolute top-0 left-0 w-full h-1 bg-amber-100">
          <div class="h-full bg-amber-500 animate-progress w-full origin-left"></div>
        </div>

        <h1 class="font-display text-xl font-semibold text-ink-900 mb-6">Create account</h1>

        <form @submit.prevent="handleRegister" class="space-y-4">
          <div>
            <label class="block text-sm font-ui font-medium text-ink-700 mb-1.5">Name</label>
            <input
              v-model="name"
              type="text"
              required
              autocomplete="name"
              placeholder="Your name"
              class="w-full px-3.5 py-2.5 rounded-lg border border-ink-200 bg-white text-ink-900 placeholder-ink-300 font-ui text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent transition"
            />
          </div>

          <div>
            <label class="block text-sm font-ui font-medium text-ink-700 mb-1.5">Email</label>
            <input
              v-model="email"
              type="email"
              required
              autocomplete="email"
              placeholder="you@example.com"
              class="w-full px-3.5 py-2.5 rounded-lg border border-ink-200 bg-white text-ink-900 placeholder-ink-300 font-ui text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent transition"
            />
          </div>

          <div>
            <label class="block text-sm font-ui font-medium text-ink-700 mb-1.5">Password</label>
            <input
              v-model="password"
              type="password"
              required
              minlength="8"
              autocomplete="new-password"
              placeholder="Min. 8 characters"
              class="w-full px-3.5 py-2.5 rounded-lg border border-ink-200 bg-white text-ink-900 placeholder-ink-300 font-ui text-sm focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent transition"
            />
          </div>

          <p v-if="error" class="text-sm text-red-600 font-ui">{{ error }}</p>

          <button
            type="submit"
            :disabled="loading"
            class="w-full py-2.5 bg-amber-500 hover:bg-amber-600 disabled:opacity-60 text-ink-950 rounded-lg font-ui font-semibold text-sm transition-colors"
          >
            {{ loading ? 'Creating account…' : 'Create account' }}
          </button>
        </form>

        <p class="mt-6 text-center text-sm text-ink-500 font-ui">
          Already have an account?
          <RouterLink to="/login" class="text-amber-700 hover:text-amber-800 font-medium">
            Sign in
          </RouterLink>
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
@keyframes progress {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}
.animate-progress {
  animation: progress 1.5s infinite ease-in-out;
}
</style>