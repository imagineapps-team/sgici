<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  icone: string
  label: string
  valor: number
  descricao?: string
  loading?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  loading: false
})

const iconeEmoji = computed(() => {
  const icones: Record<string, string> = {
    'users': '👥',
    'star': '⭐',
    'user-plus': '➕',
    'recycle': '♻️',
    'file-contract': '📄'
  }
  return icones[props.icone] || '📊'
})

const valorFormatado = computed(() => {
  if (props.valor >= 1000000) {
    return (props.valor / 1000000).toFixed(1) + 'M'
  } else if (props.valor >= 1000) {
    return (props.valor / 1000).toFixed(1) + 'K'
  }
  return props.valor.toLocaleString('pt-BR')
})
</script>

<template>
  <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-4 hover:shadow-md transition-shadow">
    <div class="flex items-center gap-3">
      <div class="text-3xl flex-shrink-0">
        {{ iconeEmoji }}
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-xs font-medium text-gray-500 uppercase tracking-wide truncate">
          {{ label }}
        </p>
        <div v-if="loading" class="animate-pulse mt-1">
          <div class="h-7 bg-gray-200 rounded w-16"></div>
        </div>
        <p v-else class="text-2xl font-bold text-brand-primary">
          {{ valorFormatado }}
        </p>
        <p v-if="descricao" class="text-xs text-gray-400 mt-0.5 truncate">
          {{ descricao }}
        </p>
      </div>
    </div>
  </div>
</template>
