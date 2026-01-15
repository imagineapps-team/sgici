<script setup lang="ts">
import type { EChartsOption } from 'echarts'
import type { ResumoParticipacao, IndicadorAmbiental, KpiFormatado } from '../../types/dashboard'
import DashboardKpiCard from './DashboardKpiCard.vue'
import DashboardIndicadorCard from './DashboardIndicadorCard.vue'
import DashboardChart from './DashboardChart.vue'
import { formatNumberCompact } from '../../utils'

interface IndicadorConfig {
  icone: string
  label: string
  descricao: string
}

interface Props {
  isLoading: boolean
  resumoParticipacao: ResumoParticipacao | null
  kpisFormatados: KpiFormatado[]
  indicadoresConfig: Record<string, IndicadorConfig>
  indicadoresData: Record<string, IndicadorAmbiental>
  chartDistribuicao: EChartsOption | null
  chartEvolucao: EChartsOption | null
}

defineProps<Props>()
</script>

<template>
  <div class="space-y-6">
    <!-- Card de Clientes Beneficiados com grafico -->
    <div class="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      <h2 class="text-lg font-semibold text-gray-800 mb-4">Clientes Beneficiados</h2>
      <div class="flex flex-col md:flex-row items-center gap-6">
        <!-- Total de beneficiarios (esquerda) -->
        <div class="flex-shrink-0 text-center md:text-left md:pr-6 md:border-r border-gray-200">
          <div v-if="isLoading" class="animate-pulse">
            <div class="h-16 bg-gray-200 rounded w-32 mb-2"></div>
            <div class="h-4 bg-gray-200 rounded w-24"></div>
          </div>
          <template v-else>
            <p class="text-5xl font-bold text-brand-primary">
              {{ formatNumberCompact(resumoParticipacao?.participantes_unicos || 0) }}
            </p>
            <p class="text-sm text-gray-500 mt-1">Total de Beneficiarios</p>
            <p class="text-xs text-gray-400">no periodo selecionado</p>
          </template>
        </div>

        <!-- Grafico de distribuicao (direita) -->
        <div class="flex-1 w-full">
          <DashboardChart
            :option="chartDistribuicao"
            :loading="isLoading"
            height="200px"
            bare
          />
        </div>
      </div>
    </div>

    <!-- KPIs Principais (4 cards) -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
      <DashboardKpiCard
        v-for="kpi in kpisFormatados"
        :key="kpi.key"
        :titulo="kpi.label"
        :valor="kpi.valorFormatado"
        :unidade="kpi.unidade"
        :icone="kpi.icone"
        :loading="isLoading"
      />
    </div>

    <!-- Gráfico de evolução temporal (largura total) -->
    <DashboardChart
      titulo="Evolução Mensal de Coleta por Ecoponto"
      :option="chartEvolucao"
      :loading="isLoading"
      height="400px"
    />

    <!-- Indicadores Ambientais (10 cards) -->
    <div>
      <h2 class="text-lg font-semibold text-gray-800 mb-4">Desempenho Ambiental</h2>
      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4">
        <DashboardIndicadorCard
          v-for="(config, key) in indicadoresConfig"
          :key="key"
          :icone="config.icone"
          :label="config.label"
          :valor="indicadoresData[key]?.valor || 0"
          :unidade="indicadoresData[key]?.unidade || ''"
          :descricao="config.descricao"
          :formula="indicadoresData[key]?.formula"
          :fonte="indicadoresData[key]?.fonte"
          :loading="isLoading"
        />
      </div>
    </div>

    <!-- Referências -->
    <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
      <h3 class="text-sm font-semibold text-gray-700 mb-2">Referências</h3>
      <div class="text-xs text-gray-500 space-y-1">
        <p>* CO2 evitado: GHG Protocol Brasil (2024)</p>
        <p>* Arvores preservadas: Embrapa ILPF</p>
        <p>* Agua economizada: BIR / WWF</p>
        <p>* Equivalências energéticas: Especificações técnicas de equipamentos</p>
      </div>
    </div>
  </div>
</template>
