<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition-opacity duration-200"
      leave-active-class="transition-opacity duration-200"
      enter-from-class="opacity-0"
      leave-to-class="opacity-0"
    >
      <div
        v-if="isLoading"
        class="fixed inset-0 z-[100] flex items-center justify-center"
      >
        <!-- Overlay -->
        <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" />

        <!-- Loading Content -->
        <div class="relative flex flex-col items-center gap-4">
          <!-- Spinner -->
          <div class="relative">
            <div class="w-16 h-16 border-4 border-white/30 rounded-full" />
            <div class="absolute top-0 left-0 w-16 h-16 border-4 border-transparent border-t-white rounded-full animate-spin" />
          </div>

          <!-- Message -->
          <p v-if="loadingMessage" class="text-white text-sm font-medium">
            {{ loadingMessage }}
          </p>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { useLoading } from '../../composables/useLoading'

const { isLoading, loadingMessage } = useLoading()
</script>
