<script setup lang="ts">
import { ref, watch, computed } from 'vue'

export interface TabItem {
  key: string
  label: string
  disabled?: boolean
}

interface Props {
  tabs: TabItem[]
  modelValue?: string
  variant?: 'underline' | 'pills' | 'boxed'
}

const props = withDefaults(defineProps<Props>(), {
  modelValue: '',
  variant: 'underline'
})

const emit = defineEmits<{
  'update:modelValue': [value: string]
}>()

const activeTab = ref(props.modelValue || props.tabs[0]?.key || '')

watch(() => props.modelValue, (newValue) => {
  if (newValue) activeTab.value = newValue
})

const selectTab = (tab: TabItem) => {
  if (tab.disabled) return
  activeTab.value = tab.key
  emit('update:modelValue', tab.key)
}

const tabClasses = computed(() => {
  return (tab: TabItem) => {
    const isActive = activeTab.value === tab.key
    const base = 'whitespace-nowrap font-medium text-sm transition-colors focus:outline-none'

    if (tab.disabled) {
      return `${base} cursor-not-allowed opacity-50`
    }

    if (props.variant === 'underline') {
      return `${base} py-3 px-1 border-b-2 ${
        isActive
          ? 'border-brand-primary text-brand-primary'
          : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
      }`
    }

    if (props.variant === 'pills') {
      return `${base} py-2 px-4 rounded-lg ${
        isActive
          ? 'bg-brand-primary text-white'
          : 'text-gray-500 hover:bg-gray-100 hover:text-gray-700'
      }`
    }

    if (props.variant === 'boxed') {
      return `${base} py-2 px-4 border ${
        isActive
          ? 'bg-white border-gray-200 border-b-white -mb-px text-brand-primary'
          : 'bg-gray-50 border-transparent text-gray-500 hover:text-gray-700'
      }`
    }

    return base
  }
})

const navClasses = computed(() => {
  if (props.variant === 'underline') {
    return 'border-b border-gray-200 -mb-px flex space-x-8'
  }
  if (props.variant === 'pills') {
    return 'flex space-x-2'
  }
  if (props.variant === 'boxed') {
    return 'flex border-b border-gray-200'
  }
  return 'flex space-x-8'
})
</script>

<template>
  <div>
    <!-- Tab headers -->
    <div :class="variant === 'boxed' ? '' : ''">
      <nav :class="navClasses">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          @click="selectTab(tab)"
          :class="tabClasses(tab)"
          :disabled="tab.disabled"
          type="button"
        >
          {{ tab.label }}
        </button>
      </nav>
    </div>

    <!-- Tab content -->
    <div class="pt-6">
      <template v-for="tab in tabs" :key="tab.key">
        <div v-show="activeTab === tab.key">
          <slot :name="tab.key" />
        </div>
      </template>
    </div>
  </div>
</template>
