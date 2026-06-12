<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterLink } from 'vue-router'
import { PenLine } from 'lucide-vue-next'
import { useBooksStore } from '@/store/books'
import BookCard from '@/assets/Ui/BookCard.vue'

const store = useBooksStore()
onMounted(() => store.fetchMyBooks())
</script>

<template>
  <div class="p-6 max-w-6xl mx-auto">
    <!-- Empty state -->
    <div
      v-if="!store.loading && store.books.length === 0"
      class="flex flex-col items-center justify-center py-24 text-center"
    >
      <div class="text-6xl mb-4">📖</div>
      <h2 class="font-display text-2xl font-semibold text-ink-800 mb-2">Your shelf is empty</h2>
      <p class="text-ink-500 mb-6">Start writing your first book today.</p>
      <RouterLink
        to="/app/books/new"
        class="inline-flex items-center gap-2 px-5 py-2.5 bg-amber-500 hover:bg-amber-600 text-ink-950 rounded-lg font-ui font-medium text-sm transition-colors"
      >
        <PenLine :size="16" />
        New Book
      </RouterLink>
    </div>

    <!-- Loading -->
    <div v-else-if="store.loading" class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
      <div v-for="n in 8" :key="n" class="aspect-[3/4] bg-ink-100 rounded-xl animate-pulse" />
    </div>

    <!-- Grid -->
    <div v-else class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
      <BookCard v-for="book in store.books" :key="book._id" :book="book" />

      <!-- New book card -->
      <RouterLink
        to="/app/books/new"
        class="group flex flex-col items-center justify-center gap-3 p-5 rounded-xl border-2 border-dashed border-ink-200 hover:border-amber-400 hover:bg-amber-50/50 transition-all duration-200 min-h-[180px]"
      >
        <div class="w-10 h-10 rounded-full bg-ink-100 group-hover:bg-amber-100 flex items-center justify-center transition-colors">
          <PenLine :size="18" class="text-ink-400 group-hover:text-amber-600" />
        </div>
        <span class="text-sm text-ink-400 group-hover:text-amber-600 font-ui transition-colors">
          New Book
        </span>
      </RouterLink>
    </div>
  </div>
</template>