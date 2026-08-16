<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '@/store/auth'
import { BookOpen, Eye, EyeOff, AlertCircle, Loader2, Check } from 'lucide-vue-next'

const router = useRouter()
const auth   = useAuthStore()

const name     = ref('')
const email    = ref('')
const password = ref('')
const error    = ref('')
const loading  = ref(false)
const showPassword = ref(false)

// Password strength
const strength = computed(() => {
  const p = password.value
  if (!p) return 0
  let score = 0
  if (p.length >= 8)  score++
  if (p.length >= 12) score++
  if (/[A-Z]/.test(p)) score++
  if (/[0-9]/.test(p)) score++
  if (/[^A-Za-z0-9]/.test(p)) score++
  return score
})

const strengthLabel = computed(() => {
  if (!password.value) return ''
  if (strength.value <= 1) return 'Weak'
  if (strength.value <= 3) return 'Fair'
  if (strength.value <= 4) return 'Good'
  return 'Strong'
})

const strengthColor = computed(() => {
  if (strength.value <= 1) return 'bg-red-500'
  if (strength.value <= 3) return 'bg-amber-400'
  if (strength.value <= 4) return 'bg-yellow-400'
  return 'bg-green-500'
})

const strengthWidth = computed(() => {
  return `${(strength.value / 5) * 100}%`
})

async function handleRegister() {
  error.value   = ''
  loading.value = true
  try {
    await auth.register(name.value, email.value, password.value)
    router.push('/app/notes')
  } catch (e: unknown) {
    error.value = (e as { response?: { data?: { message?: string } } })?.response?.data?.message ?? 'Registration failed'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-ink-50 dark:bg-ink-950 flex items-center justify-center p-4">
    <!-- Ambient background -->
    <div class="absolute inset-0 overflow-hidden pointer-events-none">
      <div class="absolute -top-40 -right-40 w-96 h-96 rounded-full bg-amber-400/8 dark:bg-amber-500/5 blur-3xl" />
      <div class="absolute -bottom-40 -left-40 w-96 h-96 rounded-full bg-amber-300/10 dark:bg-amber-600/5 blur-3xl" />
    </div>

    <div class="w-full max-w-sm relative animate-fade-slide-up">
      <!-- Logo -->
      <div class="flex items-center gap-2.5 justify-center mb-10">
        <div class="w-9 h-9 bg-amber-500 rounded-lg flex items-center justify-center shadow-card">
          <BookOpen :size="18" class="text-ink-950" />
        </div>
        <span class="font-display text-2xl font-bold text-ink-900 dark:text-ink-50">Writebook</span>
      </div>

      <!-- Card -->
      <div class="bg-white rounded-dialog border border-ink-100 shadow-modal p-8 relative overflow-hidden dark:bg-ink-900 dark:border-ink-800">
        <!-- Top loading bar -->
        <div v-if="loading" class="absolute top-0 left-0 w-full h-0.5 bg-amber-100 dark:bg-amber-900/40 overflow-hidden">
          <div class="h-full bg-amber-500 animate-progress" />
        </div>

        <h1 class="font-display text-xl font-semibold text-ink-900 dark:text-ink-50 mb-6">Create account</h1>

        <form @submit.prevent="handleRegister" class="space-y-4">
          <!-- Name -->
          <div>
            <label class="input-label">Name</label>
            <input
              v-model="name"
              type="text"
              required
              autocomplete="name"
              placeholder="Your name"
              class="input-base"
            />
          </div>

          <!-- Email -->
          <div>
            <label class="input-label">Email</label>
            <input
              v-model="email"
              type="email"
              required
              autocomplete="email"
              placeholder="you@example.com"
              class="input-base"
            />
          </div>

          <!-- Password -->
          <div>
            <label class="input-label">Password</label>
            <div class="relative">
              <input
                v-model="password"
                :type="showPassword ? 'text' : 'password'"
                required
                minlength="8"
                autocomplete="new-password"
                placeholder="Min. 8 characters"
                class="input-base pr-10"
              />
              <button
                type="button"
                @click="showPassword = !showPassword"
                class="absolute right-3 top-1/2 -translate-y-1/2 text-ink-400 hover:text-ink-700 dark:hover:text-ink-200 transition-colors"
                :aria-label="showPassword ? 'Hide password' : 'Show password'"
              >
                <component :is="showPassword ? EyeOff : Eye" :size="16" />
              </button>
            </div>

            <!-- Password strength indicator -->
            <Transition
              enter-active-class="transition-all duration-200 ease-out"
              enter-from-class="opacity-0 -translate-y-1"
              enter-to-class="opacity-100 translate-y-0"
            >
              <div v-if="password" class="mt-2 space-y-1.5">
                <div class="h-1 w-full bg-ink-100 dark:bg-ink-800 rounded-full overflow-hidden">
                  <div
                    class="h-full rounded-full transition-all duration-400"
                    :class="strengthColor"
                    :style="{ width: strengthWidth }"
                  />
                </div>
                <div class="flex items-center justify-between">
                  <span class="text-xs font-ui text-ink-400 dark:text-ink-600">Strength</span>
                  <div class="flex items-center gap-1">
                    <Check v-if="strength === 5" :size="11" class="text-green-500" />
                    <span
                      class="text-xs font-ui font-medium"
                      :class="{
                        'text-red-500': strength <= 1,
                        'text-amber-500': strength === 2 || strength === 3,
                        'text-yellow-500': strength === 4,
                        'text-green-500': strength === 5,
                      }"
                    >{{ strengthLabel }}</span>
                  </div>
                </div>
              </div>
            </Transition>
          </div>

          <!-- Error -->
          <Transition
            enter-active-class="transition-all duration-200 ease-out"
            enter-from-class="opacity-0 -translate-y-1"
            enter-to-class="opacity-100 translate-y-0"
            leave-active-class="transition-all duration-150"
            leave-from-class="opacity-100"
            leave-to-class="opacity-0"
          >
            <div
              v-if="error"
              class="flex items-start gap-2.5 p-3 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800/50 rounded-lg"
            >
              <AlertCircle :size="15" class="text-red-600 dark:text-red-400 shrink-0 mt-0.5" />
              <p class="text-sm text-red-700 dark:text-red-400 font-ui">{{ error }}</p>
            </div>
          </Transition>

          <!-- Submit -->
          <button
            type="submit"
            :disabled="loading"
            class="w-full py-2.5 flex items-center justify-center gap-2
                   bg-amber-500 hover:bg-amber-600 active:bg-amber-700
                   disabled:opacity-60 disabled:pointer-events-none
                   text-ink-950 rounded-lg font-ui font-semibold text-sm
                   transition-all duration-150 active:scale-[0.99] shadow-card"
          >
            <Loader2 v-if="loading" :size="15" class="animate-spin" />
            {{ loading ? 'Creating account…' : 'Create account' }}
          </button>
        </form>

        <p class="mt-6 text-center text-sm text-ink-500 dark:text-ink-400 font-ui">
          Already have an account?
          <RouterLink to="/login" class="text-amber-600 dark:text-amber-500 hover:text-amber-700 font-semibold ml-1">
            Sign in
          </RouterLink>
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
@keyframes progress {
  0%   { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}
.animate-progress {
  width: 100%;
  animation: progress 1.5s infinite ease-in-out;
}
</style>
