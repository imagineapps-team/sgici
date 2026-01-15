<template>
  <div class="p-4 border-b border-gray-200 bg-gray-50">
    <div class="flex flex-wrap gap-4 items-end">
      <div
        v-for="filter in filters"
        :key="String(filter.key)"
        class="flex-1 min-w-[200px] max-w-[300px]"
      >
        <label class="block text-sm font-medium text-gray-700 mb-1">
          {{ filter.label }}
        </label>

        <!-- Text -->
        <input
          v-if="filter.type === 'text'"
          type="text"
          :placeholder="filter.placeholder"
          :value="String(modelValue[filter.key] ?? '')"
          class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-brand-primary"
          @input="onInput(filter.key, ($event.target as HTMLInputElement).value)"
        />

        <!-- Number -->
        <input
          v-else-if="filter.type === 'number'"
          type="number"
          :placeholder="filter.placeholder"
          :value="modelValue[filter.key] ?? ''"
          class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-brand-primary"
          @input="onInput(filter.key, ($event.target as HTMLInputElement).valueAsNumber)"
        />

        <!-- Select -->
        <select
          v-else-if="filter.type === 'select'"
          :value="modelValue[filter.key] ?? ''"
          class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-brand-primary"
          @change="onInput(filter.key, ($event.target as HTMLSelectElement).value)"
        >
          <option value="">{{ filter.placeholder ?? 'Selecione...' }}</option>
          <option
            v-for="option in filter.options"
            :key="String(option.value)"
            :value="option.value"
          >
            {{ option.label }}
          </option>
        </select>

        <!-- Date -->
        <input
          v-else-if="filter.type === 'date'"
          type="date"
          :value="String(modelValue[filter.key] ?? '')"
          class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-brand-primary"
          @input="onInput(filter.key, ($event.target as HTMLInputElement).value)"
        />

        <!-- Date Range -->
        <div v-else-if="filter.type === 'dateRange'" class="flex gap-2">
          <input
            type="date"
            :value="getDateRangeValue(filter.key, 'start')"
            class="flex-1 px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-brand-primary"
            @input="onDateRangeInput(filter.key, 'start', ($event.target as HTMLInputElement).value)"
          />
          <input
            type="date"
            :value="getDateRangeValue(filter.key, 'end')"
            class="flex-1 px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-brand-primary"
            @input="onDateRangeInput(filter.key, 'end', ($event.target as HTMLInputElement).value)"
          />
        </div>

        <!-- Boolean -->
        <select
          v-else-if="filter.type === 'boolean'"
          :value="modelValue[filter.key] ?? ''"
          class="w-full px-3 py-2 border border-gray-300 rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-brand-primary focus:border-brand-primary"
          @change="onBooleanInput(filter.key, ($event.target as HTMLSelectElement).value)"
        >
          <option value="">{{ filter.placeholder ?? 'Todos' }}</option>
          <option value="true">Sim</option>
          <option value="false">Não</option>
        </select>
      </div>

      <!-- Botão limpar -->
      <button
        type="button"
        class="px-4 py-2 text-sm text-gray-600 hover:text-gray-800 hover:bg-gray-200 rounded-md"
        @click="clearFilters"
      >
        Limpar filtros
      </button>
    </div>
  </div>
</template>

<script setup lang="ts" generic="T extends Record<string, unknown>">
import type { DataTableFilter, FilterValues, DateRange } from '../../types/datatable'

interface Props {
  filters: DataTableFilter<T>[]
  modelValue: FilterValues<T>
}

const props = defineProps<Props>()

const emit = defineEmits<{
  'update:modelValue': [value: FilterValues<T>]
}>()

function onInput(key: keyof T | string, value: string | number | boolean | null): void {
  emit('update:modelValue', {
    ...props.modelValue,
    [key]: value === '' ? null : value
  })
}

function onBooleanInput(key: keyof T | string, value: string): void {
  let boolValue: boolean | null = null
  if (value === 'true') boolValue = true
  if (value === 'false') boolValue = false

  emit('update:modelValue', {
    ...props.modelValue,
    [key]: boolValue
  })
}

function getDateRangeValue(key: keyof T | string, field: 'start' | 'end'): string {
  const value = props.modelValue[key]
  if (value && typeof value === 'object' && 'start' in value) {
    const dateRange = value as DateRange
    return dateRange[field] ?? ''
  }
  return ''
}

function onDateRangeInput(key: keyof T | string, field: 'start' | 'end', value: string): void {
  const current = props.modelValue[key]
  const currentRange: DateRange = (current && typeof current === 'object' && 'start' in current)
    ? current as DateRange
    : { start: null, end: null }

  emit('update:modelValue', {
    ...props.modelValue,
    [key]: {
      ...currentRange,
      [field]: value || null
    }
  })
}

function clearFilters(): void {
  emit('update:modelValue', {})
}
</script>
