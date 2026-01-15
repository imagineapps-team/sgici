<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  icone: string
  label: string
  valor: number
  unidade: string
  descricao: string
  formula?: string
  fonte?: string
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  loading: false
})

const iconeSrc = computed(() => {
  const icones: Record<string, string> = {
    'co2': '🌍',
    'arvore': '🌳',
    'carro': '🚗',
    'chuveiro': '🚿',
    'ar-condicionado': '❄️',
    'lampada-led': '💡',
    'televisao': '📺',
    'agua': '💧',
    'piscina': '🏊',
    'carvao': '⚫'
  }
  return icones[props.icone] || '📊'
})

const valorFormatado = computed(() => {
  if (props.valor >= 1000000) {
    return (props.valor / 1000000).toFixed(2) + 'M'
  } else if (props.valor >= 1000) {
    return (props.valor / 1000).toFixed(2) + 'K'
  }
  return props.valor.toFixed(2).replace('.', ',')
})
</script>

<template>
  <div
    class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-all hover:border-brand-primary/30 group"
    :title="formula || ''"
  >
    <div class="flex items-start gap-4">
      <div class="text-4xl flex-shrink-0">
        {{ iconeSrc }}
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-gray-500 uppercase tracking-wide truncate">
          {{ label }}
        </p>
        <div v-if="loading" class="animate-pulse mt-1">
          <div class="h-6 bg-gray-200 rounded w-20"></div>
        </div>
        <template v-else>
          <p class="mt-1 text-2xl font-bold text-gray-900">
            {{ valorFormatado }}
            <span class="text-sm font-normal text-gray-500">{{ unidade }}</span>
          </p>
          <p class="text-xs text-gray-400 mt-1 line-clamp-2">
            {{ descricao }}
          </p>
        </template>
      </div>
    </div>

    <!-- Tooltip com fonte (aparece no hover) -->
    <div
      v-if="fonte"
      class="mt-2 pt-2 border-t border-gray-100 opacity-0 group-hover:opacity-100 transition-opacity"
    >
      <p class="text-xs text-gray-400">
        <span class="font-medium">Fonte:</span> {{ fonte }}
      </p>
    </div>
  </div>
</template>
