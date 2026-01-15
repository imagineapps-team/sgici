<template>
  <div class="select-none">
    <!-- Menu Item -->
    <div
      class="flex items-center gap-2 py-1.5 px-2 rounded hover:bg-gray-50 group"
      :style="{ paddingLeft: `${depth * 24 + 8}px` }"
    >
      <!-- Expand/Collapse Button -->
      <button
        v-if="hasChildren"
        type="button"
        @click="$emit('toggle-expand', menu.id)"
        class="w-5 h-5 flex items-center justify-center text-gray-400 hover:text-gray-600"
      >
        <ChevronRightIcon
          class="h-4 w-4 transition-transform"
          :class="{ 'rotate-90': isExpanded }"
        />
      </button>
      <span v-else class="w-5" />

      <!-- Checkbox -->
      <input
        type="checkbox"
        :id="`menu-${menu.id}`"
        :checked="isSelected"
        @change="$emit('toggle-select', menu.id, menu)"
        class="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded cursor-pointer"
      />

      <!-- Label -->
      <label
        :for="`menu-${menu.id}`"
        class="flex-1 text-sm text-gray-700 cursor-pointer"
      >
        {{ menu.nome }}
        <span v-if="menu.controller" class="text-xs text-gray-400 ml-2">
          ({{ menu.controller }}{{ menu.action ? `/${menu.action}` : '' }})
        </span>
      </label>
    </div>

    <!-- Children (recursive) -->
    <div v-if="hasChildren && isExpanded" class="border-l border-gray-200 ml-4">
      <MenuTreeItem
        v-for="child in menu.children"
        :key="child.id"
        :menu="child"
        :selected-ids="selectedIds"
        :expanded-ids="expandedIds"
        :depth="depth + 1"
        @toggle-select="(id, m) => $emit('toggle-select', id, m)"
        @toggle-expand="(id) => $emit('toggle-expand', id)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { ChevronRightIcon } from '@heroicons/vue/24/outline'

interface MenuItem {
  id: number
  nome: string
  controller: string | null
  action: string | null
  ordem: number
  children: MenuItem[]
}

interface Props {
  menu: MenuItem
  selectedIds: Set<number>
  expandedIds: Set<number>
  depth?: number
}

const props = withDefaults(defineProps<Props>(), {
  depth: 0
})

defineEmits<{
  (e: 'toggle-select', id: number, menu: MenuItem): void
  (e: 'toggle-expand', id: number): void
}>()

const hasChildren = computed(() => props.menu.children?.length > 0)
const isExpanded = computed(() => props.expandedIds.has(props.menu.id))
const isSelected = computed(() => props.selectedIds.has(props.menu.id))
</script>
