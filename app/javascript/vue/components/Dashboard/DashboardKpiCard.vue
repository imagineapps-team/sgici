<script setup lang="ts">
import { computed } from 'vue'
import {
  ChartBarIcon,
  CurrencyDollarIcon,
  ScaleIcon,
  BoltIcon
} from '@heroicons/vue/24/outline'

interface Props {
  titulo: string
  valor: string | number
  unidade: string
  icone?: 'co2' | 'scale' | 'currency' | 'bolt' | 'chart'
  cor?: string
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  icone: 'chart',
  cor: 'text-brand-primary',
  loading: false
})

const IconComponent = computed(() => {
  switch (props.icone) {
    case 'co2':
    case 'chart':
      return ChartBarIcon
    case 'scale':
      return ScaleIcon
    case 'currency':
      return CurrencyDollarIcon
    case 'bolt':
      return BoltIcon
    default:
      return ChartBarIcon
  }
})

const corBg = computed(() => {
  switch (props.icone) {
    case 'co2':
      return 'bg-green-100 text-green-600'
    case 'scale':
      return 'bg-blue-100 text-blue-600'
    case 'currency':
      return 'bg-yellow-100 text-yellow-600'
    case 'bolt':
      return 'bg-amber-100 text-amber-600'
    default:
      return 'bg-brand-primary/10 text-brand-primary'
  }
})
</script>

<template>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6 hover:shadow-md transition-shadow">
    <div class="flex items-center justify-between">
      <div class="flex-1">
        <p class="text-sm font-medium text-gray-500 uppercase tracking-wide">
          {{ titulo }}
        </p>
        <div v-if="loading" class="animate-pulse mt-2">
          <div class="h-8 bg-gray-200 rounded w-24"></div>
        </div>
        <template v-else>
          <p class="mt-2 text-3xl font-bold" :class="cor">
            {{ valor }}
          </p>
          <p class="text-sm text-gray-500 mt-1">{{ unidade }}</p>
        </template>
      </div>
      <div class="p-3 rounded-full" :class="corBg">
        <component :is="IconComponent" class="h-8 w-8" />
      </div>
    </div>
  </div>
</template>
