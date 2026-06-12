<script setup lang="ts">
import { RouterView, useRoute } from 'vue-router'
import AppSidebar from '@/components/Sidebar.vue'
import AppHeader  from '@/components/Header.vue'

const route = useRoute()
const isEditorRoute = () => route.name === 'editor'
</script>

<template>
  <div class="flex h-screen bg-parchment overflow-hidden">
    <!-- Sidebar -->
    <AppSidebar />

    <!-- Main content -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <AppHeader v-if="!isEditorRoute()" />
      <main class="flex-1 overflow-y-auto">
        <RouterView />
      </main>
    </div>
  </div>
</template>