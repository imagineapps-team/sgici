<script setup lang="ts">
import type { FiltrosDashboard, PeriodoKey } from '../../types/dashboard'

interface Props {
  filtros: FiltrosDashboard
  periodoAtivo: PeriodoKey | null
}

defineProps<Props>()

const emit = defineEmits<{
  'filtrar-periodo': [periodo: PeriodoKey]
  'aplicar-filtro': []
  'update:filtros': [filtros: Partial<FiltrosDashboard>]
}>()

const periodos: { key: PeriodoKey; label: string }[] = [
  { key: 'hoje', label: 'Hoje' },
  { key: 'semana', label: 'Semana' },
  { key: 'mes', label: 'Mês' },
  { key: 'anterior', label: 'Mês Anterior' },
  { key: 'ano', label: 'Ano' }
]
</script>

<template>
  <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
    <div>
      <h1 class="text-2xl font-bold text-gray-900">Dashboard Gerencial</h1>
      <p class="text-sm text-gray-500">Desempenho ambiental e métricas de reciclagem</p>
    </div>

    <!-- Filtros de período -->
    <div class="flex flex-wrap items-center gap-2">
      <button
        v-for="periodo in periodos"
        :key="periodo.key"
        @click="emit('filtrar-periodo', periodo.key)"
        :class="[
          'px-3 py-1.5 text-sm rounded-lg transition-colors',
          periodoAtivo === periodo.key
            ? 'bg-brand-primary text-white'
            : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
        ]"
      >
        {{ periodo.label }}
      </button>

      <!-- Filtro customizado -->
      <div class="flex items-center gap-2 ml-2">
        <input
          :value="filtros.dataInicial"
          @input="emit('update:filtros', { dataInicial: ($event.target as HTMLInputElement).value })"
          type="date"
          class="px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:ring-brand-primary focus:border-brand-primary"
        />
        <span class="text-gray-400">até</span>
        <input
          :value="filtros.dataFinal"
          @input="emit('update:filtros', { dataFinal: ($event.target as HTMLInputElement).value })"
          type="date"
          class="px-3 py-1.5 text-sm border border-gray-300 rounded-lg focus:ring-brand-primary focus:border-brand-primary"
        />
        <button
          @click="emit('aplicar-filtro')"
          class="px-3 py-1.5 text-sm bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark"
        >
          Aplicar
        </button>
      </div>
    </div>
  </div>
</template>
