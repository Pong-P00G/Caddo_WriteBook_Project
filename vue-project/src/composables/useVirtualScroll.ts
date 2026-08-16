/**
 * useVirtualScroll - lightweight virtual scroll composable for Vue 3
 *
 * Renders only the items visible in the viewport (+ overscan) to keep
 * the DOM lean when the note list grows to hundreds of items.
 *
 * Usage:
 *   const { containerProps, wrapperProps, visibleItems } = useVirtualScroll({
 *     items: computed(() => filteredNotes.value),
 *     itemHeight: 88,    // px — fixed row height
 *     overscan: 5,       // extra rows rendered above/below viewport
 *   })
 *
 *   <div v-bind="containerProps">
 *     <div v-bind="wrapperProps">
 *       <NoteCard v-for="{ item, index } in visibleItems" :key="item._id" :note="item" />
 *     </div>
 *   </div>
 */

import { ref, computed, onMounted, onUnmounted, type ComputedRef, type Ref } from 'vue'

interface UseVirtualScrollOptions<T> {
  /** Reactive list of all items */
  items: ComputedRef<T[]> | Ref<T[]>
  /** Fixed item height in pixels */
  itemHeight: number
  /** Extra items rendered outside the visible window */
  overscan?: number
}

interface VirtualScrollResult<T> {
  /** Bind to the scroll container element */
  containerProps: { ref: string; onScroll: () => void; style: Record<string, string> }
  /** Bind to the inner wrapper that provides total height */
  wrapperStyle: ComputedRef<Record<string, string>>
  /** The subset of items currently visible */
  visibleItems: ComputedRef<{ item: T; index: number }[]>
  /** Currently visible index range (useful for debugging) */
  range: ComputedRef<{ start: number; end: number }>
}

export function useVirtualScroll<T>(
  options: UseVirtualScrollOptions<T>
): VirtualScrollResult<T> {
  const { items, itemHeight, overscan = 3 } = options

  const containerEl = ref<HTMLElement | null>(null)
  const scrollTop = ref(0)
  const containerHeight = ref(0)

  // Measure container on mount / resize
  let resizeObserver: ResizeObserver | null = null

  onMounted(() => {
    if (containerEl.value) {
      containerHeight.value = containerEl.value.clientHeight
      resizeObserver = new ResizeObserver((entries) => {
        containerHeight.value = entries[0].contentRect.height
      })
      resizeObserver.observe(containerEl.value)
    }
  })

  onUnmounted(() => {
    resizeObserver?.disconnect()
  })

  function onScroll() {
    scrollTop.value = containerEl.value?.scrollTop ?? 0
  }

  const range = computed(() => {
    const total = items.value.length
    const start = Math.max(0, Math.floor(scrollTop.value / itemHeight) - overscan)
    const visibleCount = Math.ceil(containerHeight.value / itemHeight)
    const end = Math.min(total - 1, start + visibleCount + overscan * 2)
    return { start, end }
  })

  const visibleItems = computed(() =>
    items.value
      .slice(range.value.start, range.value.end + 1)
      .map((item, i) => ({ item, index: range.value.start + i }))
  )

  const wrapperStyle = computed((): Record<string, string> => ({
    height: `${items.value.length * itemHeight}px`,
    position: 'relative',
  }))

  return {
    containerProps: {
      ref: 'containerEl',
      onScroll,
      style: { overflow: 'auto', height: '100%' },
    },
    wrapperStyle,
    visibleItems,
    range,
  }
}
