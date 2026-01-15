<template>
  <div class="flex items-center justify-between px-4 py-3 border-t border-gray-200 bg-gray-50">
    <!-- Info -->
    <div class="flex items-center gap-4">
      <span class="text-sm text-gray-700">
        Mostrando
        <span class="font-medium">{{ startItem }}</span>
        a
        <span class="font-medium">{{ endItem }}</span>
        de
        <span class="font-medium">{{ total }}</span>
        resultados
      </span>

      <!-- Per page selector -->
      <div class="flex items-center gap-2">
        <label class="text-sm text-gray-700">Por página:</label>
        <select
          :value="perPage"
          class="px-2 py-1 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-brand-primary"
          @change="$emit('per-page-change', Number(($event.target as HTMLSelectElement).value))"
        >
          <option v-for="option in perPageOptionsList" :key="option" :value="option">
            {{ option }}
          </option>
        </select>
      </div>
    </div>

    <!-- Navigation -->
    <div class="flex items-center gap-1">
      <!-- First page -->
      <button
        type="button"
        class="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-200 rounded disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="currentPage === 1"
        @click="$emit('page-change', 1)"
      >
        <ChevronDoubleLeftIcon class="h-4 w-4" />
      </button>

      <!-- Previous page -->
      <button
        type="button"
        class="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-200 rounded disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="currentPage === 1"
        @click="$emit('page-change', currentPage - 1)"
      >
        <ChevronLeftIcon class="h-4 w-4" />
      </button>

      <!-- Page numbers -->
      <template v-for="page in visiblePages" :key="page">
        <span v-if="page === '...'" class="px-2 text-gray-500">...</span>
        <button
          v-else
          type="button"
          class="min-w-[32px] h-8 px-2 text-sm rounded"
          :class="page === currentPage
            ? 'bg-brand-primary text-white'
            : 'text-gray-700 hover:bg-gray-200'"
          @click="$emit('page-change', page)"
        >
          {{ page }}
        </button>
      </template>

      <!-- Next page -->
      <button
        type="button"
        class="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-200 rounded disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="currentPage === totalPages"
        @click="$emit('page-change', currentPage + 1)"
      >
        <ChevronRightIcon class="h-4 w-4" />
      </button>

      <!-- Last page -->
      <button
        type="button"
        class="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-200 rounded disabled:opacity-50 disabled:cursor-not-allowed"
        :disabled="currentPage === totalPages"
        @click="$emit('page-change', totalPages)"
      >
        <ChevronDoubleRightIcon class="h-4 w-4" />
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  ChevronDoubleLeftIcon,
  ChevronDoubleRightIcon
} from '@heroicons/vue/24/outline'

interface Props {
  currentPage: number
  perPage: number
  total: number
  perPageOptions?: number[]
}

const props = withDefaults(defineProps<Props>(), {
  perPageOptions: () => [10, 25, 50, 100]
})

defineEmits<{
  'page-change': [page: number]
  'per-page-change': [perPage: number]
}>()

const perPageOptionsList = computed(() => props.perPageOptions)

const totalPages = computed(() => Math.ceil(props.total / props.perPage) || 1)

const startItem = computed(() => {
  if (props.total === 0) return 0
  return (props.currentPage - 1) * props.perPage + 1
})

const endItem = computed(() => {
  return Math.min(props.currentPage * props.perPage, props.total)
})

const visiblePages = computed((): (number | '...')[] => {
  const pages: (number | '...')[] = []
  const total = totalPages.value
  const current = props.currentPage
  const delta = 2

  if (total <= 7) {
    for (let i = 1; i <= total; i++) {
      pages.push(i)
    }
    return pages
  }

  pages.push(1)

  if (current > delta + 2) {
    pages.push('...')
  }

  const start = Math.max(2, current - delta)
  const end = Math.min(total - 1, current + delta)

  for (let i = start; i <= end; i++) {
    pages.push(i)
  }

  if (current < total - delta - 1) {
    pages.push('...')
  }

  pages.push(total)

  return pages
})
</script>
