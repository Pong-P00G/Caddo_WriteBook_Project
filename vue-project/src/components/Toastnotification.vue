<script setup lang="ts">
import { onMounted } from 'vue'
import { CheckCircle2, XCircle, Info, X } from 'lucide-vue-next'

const props = withDefaults(defineProps<{
  id: number
  message: string
  type?: 'success' | 'error' | 'info'
  duration?: number
}>(), {
  type: 'info',
  duration: 3500,
})

const emit = defineEmits<{ (e: 'close', id: number): void }>()

onMounted(() => {
  setTimeout(() => emit('close', props.id), props.duration)
})

const styles = {
  success: 'bg-green-50 border-green-200 text-green-800',
  error:   'bg-red-50   border-red-200   text-red-800',
  info:    'bg-ink-50 border-ink-200 text-ink-800 dark:bg-ink-800 dark:border-ink-700 dark:text-ink-100',
}

const icons = { success: CheckCircle2, error: XCircle, info: Info }
</script>

<template>
  <div
    class="flex items-start gap-3 w-80 px-4 py-3 rounded-xl border shadow-md font-ui text-sm transition-all"
    :class="styles[type]"
  >
    <component :is="icons[type]" :size="16" class="shrink-0 mt-0.5" />
    <span class="flex-1">{{ message }}</span>
    <button @click="emit('close', id)" class="shrink-0 opacity-50 hover:opacity-100 transition-opacity">
      <X :size="14" />
    </button>
  </div>
</template>
