<template>
  <Head title="Dashboard" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header com filtros de periodo -->
      <DashboardHeaderFiltros
        :filtros="filtros"
        :periodo-ativo="periodoAtivo"
        @filtrar-periodo="handleFiltrarPeriodo"
        @aplicar-filtro="handleAplicarFiltro"
        @update:filtros="handleUpdateFiltros"
      />

      <!-- Abas Resumo/Detalhes -->
      <ITabs v-model="abaAtiva" :tabs="abas">
        <!-- ABA RESUMO -->
        <template #resumo>
          <DashboardTabResumo
            :is-loading="isLoading"
            :resumo-participacao="resumoParticipacao"
            :kpis-formatados="kpisFormatados"
            :indicadores-config="indicadores"
            :indicadores-data="indicadoresData"
            :chart-distribuicao="chartDistribuicaoTipoAcao"
            :chart-evolucao="chartEvolucao"
          />
        </template>

        <!-- ABA DETALHES -->
        <template #detalhes>
          <DashboardTabDetalhes
            :is-loading="isLoading"
            :eventos-ativos="eventosAtivos"
            :eventos-ativos-markers="eventosAtivosMarkers"
            :colunas-eventos-ativos="colunasEventosAtivos"
            :resumo-participacao="resumoParticipacao"
            :total-gerado-por-acao="totalGeradoPorAcao"
            :economia-agrupada-por-acao="economiaAgrupadaPorAcao"
            :totais-total-gerado="totaisTotalGerado"
            :resumo-por-acao="resumoPorAcao"
            :resumo-doacoes="resumoDoacoes"
            :total-doacoes="totalDoacoes"
            :colunas-total-gerado="colunasTotalGerado"
            :colunas-resumo-por-acao="colunasResumoPorAcao"
            :colunas-doacoes="colunasDoacoes"
          />
        </template>
      </ITabs>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Head } from '@inertiajs/vue3'
import AppLayout from '../../layouts/AppLayout.vue'
import { ITabs } from '../../components/ITabs'
import DashboardHeaderFiltros from '../../components/Dashboard/DashboardHeaderFiltros.vue'
import DashboardTabResumo from '../../components/Dashboard/DashboardTabResumo.vue'
import DashboardTabDetalhes from '../../components/Dashboard/DashboardTabDetalhes.vue'
import { useDashboard } from '../../composables/useDashboard'
import type { UserInfo } from '../../types/navigation'
import type { FiltrosDashboard, PeriodoKey } from '../../types/dashboard'

interface IndicadorConfig {
  icone: string
  label: string
  descricao: string
}

interface Props {
  usuario: UserInfo
  indicadores: Record<string, IndicadorConfig>
  filtrosPadrao: FiltrosDashboard
}

const props = defineProps<Props>()

// Abas
const abaAtiva = ref('resumo')
const abas = [
  { key: 'resumo', label: 'Resumo' },
  { key: 'detalhes', label: 'Detalhes' }
]

// Composable principal do dashboard
const {
  // Estado global
  isLoading,
  filtros,
  periodoAtivo,
  resumoParticipacao,
  // KPIs
  kpisFormatados,
  indicadores: indicadoresData,
  // Eventos
  eventosAtivos,
  eventosAtivosMarkers,
  colunasEventosAtivos,
  // Tabelas
  totalGeradoPorAcao,
  economiaAgrupadaPorAcao,
  totaisTotalGerado,
  resumoPorAcao,
  resumoDoacoes,
  totalDoacoes,
  colunasTotalGerado,
  colunasResumoPorAcao,
  colunasDoacoes,
  // Charts
  chartDistribuicaoTipoAcao,
  chartEvolucao,
  // Actions
  fetchMetrics,
  atualizarFiltros,
  filtrarPorPeriodo
} = useDashboard(props.filtrosPadrao)

// Handlers para eventos do header de filtros
const handleFiltrarPeriodo = (periodo: PeriodoKey) => {
  filtrarPorPeriodo(periodo)
}

const handleAplicarFiltro = () => {
  atualizarFiltros({
    dataInicial: filtros.dataInicial,
    dataFinal: filtros.dataFinal
  })
}

const handleUpdateFiltros = (novos: Partial<FiltrosDashboard>) => {
  if (novos.dataInicial) filtros.dataInicial = novos.dataInicial
  if (novos.dataFinal) filtros.dataFinal = novos.dataFinal
}

onMounted(() => {
  fetchMetrics()
})
</script>
