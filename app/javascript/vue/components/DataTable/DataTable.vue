<template>
  <div class="bg-white rounded-lg shadow overflow-hidden">
    <!-- Filtros -->
    <DataTableFilters
      v-if="filters?.length"
      :filters="filters"
      :model-value="filterValues"
      @update:model-value="onFilterChange"
    />

    <!-- Tabela -->
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <!-- Checkbox header -->
            <th v-if="selectable" class="w-12 px-4 py-3">
              <input
                type="checkbox"
                class="h-4 w-4 accent-brand-primary border-gray-300 rounded focus:ring-brand-primary"
                :checked="allSelected"
                :indeterminate="someSelected && !allSelected"
                @change="toggleSelectAll"
              />
            </th>

            <!-- Colunas -->
            <th
              v-for="column in columns"
              :key="String(column.key)"
              class="px-4 py-3 text-xs font-medium text-gray-500 uppercase tracking-wider"
              :class="[
                column.width,
                column.align === 'center' ? 'text-center' : column.align === 'right' ? 'text-right' : 'text-left',
                column.sortable ? 'cursor-pointer hover:bg-gray-100 select-none' : ''
              ]"
              @click="column.sortable && onSort(column.key)"
            >
              <div class="flex items-center gap-1" :class="{ 'justify-center': column.align === 'center', 'justify-end': column.align === 'right' }">
                <span>{{ column.label }}</span>
                <template v-if="column.sortable">
                  <ChevronUpIcon
                    v-if="sortConfig?.key === column.key && sortConfig.direction === 'asc'"
                    class="h-4 w-4"
                  />
                  <ChevronDownIcon
                    v-else-if="sortConfig?.key === column.key && sortConfig.direction === 'desc'"
                    class="h-4 w-4"
                  />
                  <ChevronUpDownIcon v-else class="h-4 w-4 text-gray-400" />
                </template>
              </div>
            </th>

            <!-- Coluna de ações -->
            <th v-if="hasActions" class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider w-32">
              Ações
            </th>
          </tr>
        </thead>

        <tbody class="divide-y divide-gray-200">
          <!-- Loading -->
          <tr v-if="loading">
            <td :colspan="totalColumns" class="px-4 py-8 text-center">
              <div class="flex items-center justify-center gap-2 text-gray-500">
                <ArrowPathIcon class="h-5 w-5 animate-spin" />
                <span>Carregando...</span>
              </div>
            </td>
          </tr>

          <!-- Empty -->
          <tr v-else-if="!data.length">
            <td :colspan="totalColumns" class="px-4 py-8 text-center text-gray-500">
              {{ emptyMessage }}
            </td>
          </tr>

          <!-- Rows -->
          <template v-else>
            <tr
              v-for="(row, index) in data"
              :key="String(row[rowKey])"
              :class="[
                index % 2 === 0 ? 'bg-white' : 'bg-gray-50',
                'hover:bg-gray-100'
              ]"
            >
            <!-- Checkbox -->
            <td v-if="selectable" class="w-12 px-4 py-3">
              <input
                type="checkbox"
                class="h-4 w-4 accent-brand-primary border-gray-300 rounded focus:ring-brand-primary"
                :checked="isSelected(row)"
                @change="toggleSelect(row)"
              />
            </td>

            <!-- Cells -->
            <td
              v-for="column in columns"
              :key="String(column.key)"
              class="px-4 py-3 text-sm text-gray-900"
              :class="[
                column.align === 'center' ? 'text-center' : column.align === 'right' ? 'text-right' : 'text-left'
              ]"
            >
              <slot
                v-if="column.slot"
                :name="column.slot"
                :row="row"
                :value="getCellValue(row, column.key)"
              >
                {{ formatCellValue(row, column) }}
              </slot>
              <template v-else>
                {{ formatCellValue(row, column) }}
              </template>
            </td>

            <!-- Actions -->
            <td v-if="hasActions" class="px-4 py-3 text-right">
              <div class="flex items-center justify-end gap-1">
                <!-- Default Edit -->
                <button
                  v-if="defaultActions?.edit"
                  type="button"
                  class="p-1.5 text-gray-500 hover:text-brand-primary hover:bg-brand-primary-select rounded"
                  title="Editar"
                  @click="$emit('edit', row)"
                >
                  <PencilIcon class="h-4 w-4" />
                </button>

                <!-- Default Delete -->
                <button
                  v-if="defaultActions?.delete"
                  type="button"
                  class="p-1.5 text-gray-500 hover:text-red-600 hover:bg-red-50 rounded"
                  title="Remover"
                  @click="$emit('delete', row)"
                >
                  <TrashIcon class="h-4 w-4" />
                </button>

                <!-- Custom Actions -->
                <template v-for="action in visibleActions(row)" :key="action.id">
                  <button
                    type="button"
                    class="p-1.5 rounded"
                    :class="getActionClasses(action)"
                    :title="action.label"
                    :disabled="action.disabled?.(row)"
                    @click="onCustomAction(action, row)"
                  >
                    <component :is="getActionIcon(action.icon)" class="h-4 w-4" />
                  </button>
                </template>
              </div>
            </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>

    <!-- Paginação -->
    <DataTablePagination
      v-if="pagination"
      :current-page="pagination.currentPage"
      :per-page="pagination.perPage"
      :total="pagination.total"
      :per-page-options="pagination.perPageOptions"
      @page-change="$emit('page-change', $event)"
      @per-page-change="$emit('per-page-change', $event)"
    />
  </div>
</template>

<script setup lang="ts" generic="T extends Record<string, unknown>">
import { computed, ref, type Component } from 'vue'
import {
  ChevronUpIcon,
  ChevronDownIcon,
  ChevronUpDownIcon,
  PencilIcon,
  TrashIcon,
  ArrowPathIcon,
  EyeIcon,
  DocumentDuplicateIcon,
  ArrowDownTrayIcon
} from '@heroicons/vue/24/outline'
import DataTableFilters from './DataTableFilters.vue'
import DataTablePagination from './DataTablePagination.vue'
import type {
  DataTableColumn,
  DataTableAction,
  DataTableFilter,
  FilterValues,
  SortConfig,
  PaginationConfig
} from '../../types/datatable'

interface Props {
  data: T[]
  columns: DataTableColumn<T>[]
  rowKey: keyof T
  actions?: DataTableAction<T>[]
  defaultActions?: {
    edit?: boolean
    delete?: boolean
  }
  filters?: DataTableFilter<T>[]
  pagination?: PaginationConfig
  loading?: boolean
  emptyMessage?: string
  selectable?: boolean
  selected?: T[]
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  emptyMessage: 'Nenhum registro encontrado',
  selectable: false,
  selected: () => []
})

const emit = defineEmits<{
  edit: [row: T]
  delete: [row: T]
  action: [actionId: string, row: T]
  sort: [sort: SortConfig<T>]
  filter: [filters: FilterValues<T>]
  'page-change': [page: number]
  'per-page-change': [perPage: number]
  'update:selected': [selected: T[]]
}>()

// Estado
const sortConfig = ref<SortConfig<T> | null>(null)
const filterValues = ref<FilterValues<T>>({})

// Computed
const hasActions = computed(() => {
  return props.defaultActions?.edit || props.defaultActions?.delete || (props.actions?.length ?? 0) > 0
})

const totalColumns = computed(() => {
  let count = props.columns.length
  if (props.selectable) count++
  if (hasActions.value) count++
  return count
})

const allSelected = computed(() => {
  return props.data.length > 0 && props.selected?.length === props.data.length
})

const someSelected = computed(() => {
  return (props.selected?.length ?? 0) > 0
})

// Métodos
function getCellValue(row: T, key: keyof T | string): unknown {
  if (typeof key === 'string' && key.includes('.')) {
    return key.split('.').reduce((obj, k) => (obj as Record<string, unknown>)?.[k], row as unknown)
  }
  return row[key as keyof T]
}

function formatCellValue(row: T, column: DataTableColumn<T>): string {
  const value = getCellValue(row, column.key)
  if (column.format) {
    return column.format(value as T[keyof T], row)
  }
  if (value === null || value === undefined) return '-'
  return String(value)
}

function onSort(key: keyof T | string): void {
  if (sortConfig.value?.key === key) {
    sortConfig.value = {
      key,
      direction: sortConfig.value.direction === 'asc' ? 'desc' : 'asc'
    }
  } else {
    sortConfig.value = { key, direction: 'asc' }
  }
  emit('sort', sortConfig.value)
}

function onFilterChange(values: FilterValues<T>): void {
  filterValues.value = values
  emit('filter', values)
}

function visibleActions(row: T): DataTableAction<T>[] {
  return props.actions?.filter(action => action.visible?.(row) ?? true) ?? []
}

function getActionClasses(action: DataTableAction<T>): string {
  const variants: Record<string, string> = {
    primary: 'text-gray-500 hover:text-brand-primary hover:bg-brand-primary-select',
    secondary: 'text-gray-500 hover:text-gray-700 hover:bg-gray-100',
    danger: 'text-gray-500 hover:text-red-600 hover:bg-red-50',
    warning: 'text-gray-500 hover:text-yellow-600 hover:bg-yellow-50'
  }
  return variants[action.variant ?? 'primary']
}

const actionIconMap: Record<string, Component> = {
  eye: EyeIcon,
  copy: DocumentDuplicateIcon,
  download: ArrowDownTrayIcon,
  edit: PencilIcon,
  trash: TrashIcon
}

function getActionIcon(icon?: string): Component {
  return actionIconMap[icon ?? ''] ?? EyeIcon
}

function onCustomAction(action: DataTableAction<T>, row: T): void {
  action.handler(row)
  emit('action', action.id, row)
}

function isSelected(row: T): boolean {
  return props.selected?.some(item => item[props.rowKey] === row[props.rowKey]) ?? false
}

function toggleSelect(row: T): void {
  const newSelected = isSelected(row)
    ? props.selected?.filter(item => item[props.rowKey] !== row[props.rowKey]) ?? []
    : [...(props.selected ?? []), row]
  emit('update:selected', newSelected)
}

function toggleSelectAll(): void {
  emit('update:selected', allSelected.value ? [] : [...props.data])
}
</script>
