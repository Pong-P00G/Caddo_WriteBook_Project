<script setup lang="ts">
import { RouterView } from 'vue-router';
import { useAuthStore } from './store/auth';

const authStore = useAuthStore();
authStore.init();

</script>

<template>
  <div class="min-h-screen bg-parchment text-ink-800 font-body">
    <router-view />
  </div>
</template>