<template>
  <div class="w-full">
    <label
      v-if="label"
      :for="selectId"
      class="block text-sm font-medium text-gray-700 mb-1"
    >
      {{ label }}
      <span v-if="required" class="text-red-500">*</span>
    </label>

    <!-- Single Select -->
    <template v-if="mode === 'single'">
      <div
        v-if="searchable"
        v-click-outside="closeDropdown"
        class="relative"
      >
        <div
          class="w-full px-3 py-2 border rounded-lg cursor-pointer flex items-center justify-between gap-2"
          :class="[
            error ? 'border-red-500' : 'border-gray-300',
            disabled ? 'bg-gray-100 cursor-not-allowed' : 'bg-white',
            isOpen ? 'ring-2 ring-brand-primary border-brand-primary' : ''
          ]"
          @click="!disabled && toggleDropdown()"
        >
          <span class="truncate" :class="selectedLabel ? 'text-gray-900' : 'text-gray-400'">
            {{ selectedLabel || placeholder }}
          </span>
          <ChevronDownIcon
            class="h-5 w-5 text-gray-400 transition-transform flex-shrink-0"
            :class="{ 'rotate-180': isOpen }"
          />
        </div>

        <!-- Dropdown -->
        <Transition
          enter-active-class="transition duration-100 ease-out"
          enter-from-class="transform scale-95 opacity-0"
          enter-to-class="transform scale-100 opacity-100"
          leave-active-class="transition duration-75 ease-in"
          leave-from-class="transform scale-100 opacity-100"
          leave-to-class="transform scale-95 opacity-0"
        >
          <div
            v-if="isOpen"
            class="absolute z-50 mt-1 w-full bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-hidden"
          >
            <!-- Search Input -->
            <div class="p-2 border-b">
              <input
                ref="searchInputRef"
                v-model="searchQuery"
                type="text"
                :placeholder="searchPlaceholder"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-primary focus:border-brand-primary text-sm"
                @click.stop
              />
              <!-- Action Button -->
              <button
                v-if="actionLabel && onAction"
                type="button"
                class="mt-2 w-full flex items-center justify-center gap-2 px-3 py-2 text-sm font-medium text-brand-primary bg-brand-primary-select rounded-lg hover:bg-brand-primary-tag transition-colors"
                @click.stop="handleAction"
              >
                <PlusIcon class="h-4 w-4" />
                {{ actionLabel }}
              </button>
            </div>

            <!-- Options -->
            <div class="overflow-y-auto max-h-48">
              <div
                v-if="filteredOptions.length === 0"
                class="px-3 py-2 text-sm text-gray-500 text-center"
              >
                {{ emptyText }}
              </div>
              <div
                v-for="option in filteredOptions"
                :key="option.value"
                class="px-3 py-2 cursor-pointer hover:bg-gray-100 text-sm truncate"
                :class="{
                  'bg-brand-primary-select text-brand-primary': option.value === modelValue,
                  'text-gray-400 cursor-not-allowed': option.disabled
                }"
                :title="option.label"
                @click="!option.disabled && selectOption(option)"
              >
                {{ option.label }}
              </div>
            </div>
          </div>
        </Transition>
      </div>

      <!-- Simple Select (not searchable) -->
      <select
        v-else
        :id="selectId"
        :value="modelValue"
        :disabled="disabled"
        class="w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-brand-primary focus:border-brand-primary transition-colors appearance-none bg-no-repeat bg-right pr-10"
        :class="[
          error ? 'border-red-500' : 'border-gray-300',
          disabled ? 'bg-gray-100 cursor-not-allowed' : 'bg-white'
        ]"
        @change="handleSelectChange"
      >
        <option value="" disabled>{{ placeholder }}</option>
        <option
          v-for="option in options"
          :key="option.value"
          :value="option.value"
          :disabled="option.disabled"
        >
          {{ option.label }}
        </option>
      </select>
    </template>

    <!-- Multiple Select (Dropdown with Tags) -->
    <template v-else>
      <div
        v-click-outside="closeDropdown"
        class="relative"
      >
        <div
          class="w-full min-h-[42px] px-3 py-2 border rounded-lg cursor-pointer flex items-center justify-between gap-2"
          :class="[
            error ? 'border-red-500' : 'border-gray-300',
            disabled ? 'bg-gray-100 cursor-not-allowed' : 'bg-white',
            isOpen ? 'ring-2 ring-brand-primary border-brand-primary' : ''
          ]"
          @click="!disabled && toggleDropdown()"
        >
          <div class="flex-1 flex flex-wrap gap-1">
            <!-- Selected Tags -->
            <span
              v-for="val in selectedValues"
              :key="val"
              class="inline-flex items-center gap-1 px-2 py-0.5 bg-brand-primary-tag text-brand-primary-dark text-xs rounded-full"
            >
              {{ getOptionLabel(val) }}
              <button
                type="button"
                class="hover:text-brand-primary"
                @click.stop="toggleOption(val)"
              >
                <XMarkIcon class="h-3 w-3" />
              </button>
            </span>
            <!-- Placeholder when empty -->
            <span v-if="selectedValues.length === 0" class="text-gray-400">
              {{ placeholder }}
            </span>
          </div>
          <ChevronDownIcon
            class="h-5 w-5 text-gray-400 transition-transform flex-shrink-0"
            :class="{ 'rotate-180': isOpen }"
          />
        </div>

        <!-- Dropdown -->
        <Transition
          enter-active-class="transition duration-100 ease-out"
          enter-from-class="transform scale-95 opacity-0"
          enter-to-class="transform scale-100 opacity-100"
          leave-active-class="transition duration-75 ease-in"
          leave-from-class="transform scale-100 opacity-100"
          leave-to-class="transform scale-95 opacity-0"
        >
          <div
            v-if="isOpen"
            class="absolute z-50 mt-1 w-full bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-hidden"
          >
            <!-- Search Input -->
            <div v-if="searchable" class="p-2 border-b">
              <input
                ref="searchInputRef"
                v-model="searchQuery"
                type="text"
                :placeholder="searchPlaceholder"
                class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-brand-primary focus:border-brand-primary text-sm"
                @click.stop
              />
            </div>

            <!-- Options -->
            <div class="overflow-y-auto max-h-48">
              <div
                v-if="filteredOptions.length === 0"
                class="px-3 py-2 text-sm text-gray-500 text-center"
              >
                {{ emptyText }}
              </div>
              <label
                v-for="option in filteredOptions"
                :key="option.value"
                class="flex items-center gap-2 px-3 py-2 hover:bg-gray-100 cursor-pointer"
                :class="{ 'opacity-50 cursor-not-allowed': option.disabled }"
                @click.stop
              >
                <input
                  type="checkbox"
                  :checked="isChecked(option.value)"
                  :disabled="option.disabled || disabled"
                  class="h-4 w-4 accent-brand-primary border-gray-300 rounded focus:ring-brand-primary"
                  @change="toggleOption(option.value)"
                />
                <span class="text-sm text-gray-700">{{ option.label }}</span>
              </label>
            </div>
          </div>
        </Transition>
      </div>
    </template>

    <p v-if="error" class="mt-1 text-sm text-red-500">
      {{ error }}
    </p>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, nextTick } from 'vue'
import { ChevronDownIcon, PlusIcon, XMarkIcon } from '@heroicons/vue/24/outline'
import type { ISelectProps, SelectOption } from './types'

const props = withDefaults(defineProps<ISelectProps>(), {
  mode: 'single',
  required: false,
  disabled: false,
  searchable: false,
  placeholder: 'Selecione...',
  emptyText: 'Nenhuma opção encontrada',
  searchPlaceholder: 'Pesquisar...'
})

const emit = defineEmits<{
  'update:modelValue': [value: string | number | null | (string | number)[]]
  change: [value: string | number | null | (string | number)[]]
}>()

function handleAction() {
  isOpen.value = false
  searchQuery.value = ''
  props.onAction?.()
}

const selectId = computed(() => props.id || `select-${Math.random().toString(36).substr(2, 9)}`)

const isOpen = ref(false)
const searchQuery = ref('')
const searchInputRef = ref<HTMLInputElement | null>(null)

const filteredOptions = computed(() => {
  if (!props.options) return []
  if (!searchQuery.value) return props.options

  const query = searchQuery.value.toLowerCase()
  return props.options.filter(option =>
    option.label.toLowerCase().includes(query)
  )
})

const selectedLabel = computed(() => {
  if (props.mode === 'single' && props.options) {
    const selected = props.options.find(opt => opt.value === props.modelValue)
    return selected?.label || ''
  }
  return ''
})

const selectedValues = computed(() => {
  if (props.mode === 'multiple' && Array.isArray(props.modelValue)) {
    return props.modelValue
  }
  return []
})

function getOptionLabel(value: string | number): string {
  const option = props.options?.find(opt => opt.value === value)
  return option?.label || String(value)
}

function closeDropdown() {
  isOpen.value = false
  searchQuery.value = ''
}

function toggleDropdown() {
  isOpen.value = !isOpen.value
  if (isOpen.value) {
    nextTick(() => {
      searchInputRef.value?.focus()
    })
  } else {
    searchQuery.value = ''
  }
}

function selectOption(option: SelectOption) {
  emit('update:modelValue', option.value)
  emit('change', option.value)
  isOpen.value = false
  searchQuery.value = ''
}

function handleSelectChange(event: Event) {
  const target = event.target as HTMLSelectElement
  const value = target.value === '' ? null : (isNaN(Number(target.value)) ? target.value : Number(target.value))
  emit('update:modelValue', value)
  emit('change', value)
}

function isChecked(value: string | number): boolean {
  if (!Array.isArray(props.modelValue)) return false
  return props.modelValue.includes(value)
}

function toggleOption(value: string | number) {
  if (!Array.isArray(props.modelValue)) {
    emit('update:modelValue', [value])
    emit('change', [value])
    return
  }

  const newValue = isChecked(value)
    ? props.modelValue.filter(v => v !== value)
    : [...props.modelValue, value]

  emit('update:modelValue', newValue)
  emit('change', newValue)
}
</script>
