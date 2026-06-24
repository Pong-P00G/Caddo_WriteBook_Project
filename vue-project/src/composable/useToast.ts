import { ref } from 'vue'

interface Toast {
  id: number
  message: string
  type: 'success' | 'error' | 'info'
}

let counter = 0
const toasts = ref<Toast[]>([])

export function useToast() {
  function showToast(message: string, type: Toast['type'] = 'info') {
    const id = ++counter
    toasts.value.push({ id, message, type })
  }

  function removeToast(id: number) {
    toasts.value = toasts.value.filter(t => t.id !== id)
  }

  return { toasts, showToast, removeToast }
}
