<script setup lang="ts">
import { ref, computed } from 'vue'
import { ChevronRightIcon, InformationCircleIcon } from '@heroicons/vue/24/outline'

export interface TreeListItem {
  key: string
  label: string
  value: number | string
  tooltip?: string
  expandable?: boolean
  children?: TreeListChild[]
  actionButton?: {
    label: string
    onClick: () => void
  }
}

export interface TreeListChild {
  key: string
  label: string
  value: number | string
  actionButton?: {
    label: string
    onClick: () => void
  }
}

interface Props {
  items: TreeListItem[]
  formatValue?: (value: number | string) => string
}

const props = withDefaults(defineProps<Props>(), {
  formatValue: (value: number | string) => {
    if (typeof value === 'number') {
      return value.toLocaleString('pt-BR')
    }
    return String(value)
  }
})

const emit = defineEmits<{
  'item-click': [item: TreeListItem]
  'action-click': [item: TreeListItem | TreeListChild]
}>()

const expandedItems = ref<Set<string>>(new Set())

const toggleExpand = (item: TreeListItem) => {
  if (!item.expandable || !item.children?.length) return

  if (expandedItems.value.has(item.key)) {
    expandedItems.value.delete(item.key)
  } else {
    expandedItems.value.add(item.key)
  }
}

const isExpanded = (key: string) => expandedItems.value.has(key)
</script>

<template>
  <div class="divide-y divide-gray-200 border border-gray-200 rounded-lg bg-white">
    <div
      v-for="item in items"
      :key="item.key"
      class="group"
    >
      <!-- Item principal -->
      <div
        :class="[
          'flex items-center gap-3 px-4 py-3 transition-colors',
          item.expandable && item.children?.length
            ? 'cursor-pointer hover:bg-gray-50'
            : ''
        ]"
        @click="toggleExpand(item)"
      >
        <!-- Ícone de expansão -->
        <div class="w-5 flex-shrink-0">
          <ChevronRightIcon
            v-if="item.expandable && item.children?.length"
            :class="[
              'w-5 h-5 text-brand-primary transition-transform duration-200',
              isExpanded(item.key) ? 'rotate-90' : ''
            ]"
          />
          <InformationCircleIcon
            v-else
            class="w-5 h-5 text-gray-400"
          />
        </div>

        <!-- Badge com valor -->
        <span class="inline-flex items-center justify-center min-w-[60px] px-2.5 py-0.5 rounded-full text-sm font-medium bg-gray-100 text-gray-800">
          {{ formatValue(item.value) }}
        </span>

        <!-- Label -->
        <span class="flex-1 text-sm text-gray-700">
          {{ item.label }}
        </span>

        <!-- Tooltip -->
        <span
          v-if="item.tooltip"
          class="relative group/tooltip"
        >
          <InformationCircleIcon class="w-4 h-4 text-gray-400 hover:text-gray-600 cursor-help" />
          <span class="absolute z-10 invisible group-hover/tooltip:visible bg-gray-900 text-white text-xs rounded py-1 px-2 -top-8 left-1/2 -translate-x-1/2 whitespace-nowrap">
            {{ item.tooltip }}
          </span>
        </span>

        <!-- Botão de ação -->
        <button
          v-if="item.actionButton"
          @click.stop="item.actionButton.onClick"
          class="px-3 py-1 text-xs font-medium text-white bg-brand-primary hover:bg-brand-primary-dark rounded transition-colors"
        >
          {{ item.actionButton.label }}
        </button>
      </div>

      <!-- Subitens (quando expandido) -->
      <div
        v-if="item.expandable && item.children?.length && isExpanded(item.key)"
        class="bg-gray-50 border-t border-gray-100"
      >
        <div
          v-for="child in item.children"
          :key="child.key"
          class="flex items-center gap-3 px-4 py-2.5 pl-12"
        >
          <!-- Ícone de seta -->
          <svg class="w-4 h-4 text-brand-primary flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7l5 5m0 0l-5 5m5-5H6" />
          </svg>

          <!-- Badge com valor -->
          <span class="inline-flex items-center justify-center min-w-[50px] px-2 py-0.5 rounded-full text-xs font-medium bg-gray-200 text-gray-700">
            {{ formatValue(child.value) }}
          </span>

          <!-- Label -->
          <span class="flex-1 text-sm text-gray-600">
            {{ child.label }}
          </span>

          <!-- Botão de ação do filho -->
          <button
            v-if="child.actionButton"
            @click.stop="child.actionButton.onClick"
            class="px-2 py-0.5 text-xs font-medium text-white bg-brand-primary hover:bg-brand-primary-dark rounded transition-colors"
          >
            {{ child.actionButton.label }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>
