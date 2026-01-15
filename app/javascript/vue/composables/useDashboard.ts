import { ref } from 'vue'
import api from '../lib/axios'
import { useDashboardFiltros } from './useDashboardFiltros'
import { useDashboardKpis } from './useDashboardKpis'
import { useDashboardEventos } from './useDashboardEventos'
import { useDashboardTabelas } from './useDashboardTabelas'
import { useDashboardCharts } from './useDashboardCharts'
import type {
  FiltrosDashboard,
  DashboardMetrics,
  ResumoParticipacao,
  EvolucaoData,
  PeriodoKey
} from '../types/dashboard'

export function useDashboard(filtrosPadrao?: FiltrosDashboard) {
  // Estado global
  const isLoading = ref(false)
  const error = ref<string | null>(null)
  const metrics = ref<DashboardMetrics | null>(null)
  const resumoParticipacao = ref<ResumoParticipacao | null>(null)
  const evolucao = ref<EvolucaoData | null>(null)

  // Composição dos composables especializados
  const filtrosComposable = useDashboardFiltros(filtrosPadrao)
  const kpisComposable = useDashboardKpis()
  const eventosComposable = useDashboardEventos()
  const tabelasComposable = useDashboardTabelas()
  const chartsComposable = useDashboardCharts(resumoParticipacao, evolucao)

  // Fetch principal que alimenta todos
  const fetchMetrics = async () => {
    isLoading.value = true
    error.value = null

    try {
      const response = await api.get('/dashboard/metrics', {
        params: {
          data_inicial: filtrosComposable.filtros.dataInicial,
          data_final: filtrosComposable.filtros.dataFinal
        }
      })

      metrics.value = response.data
      resumoParticipacao.value = response.data.resumo_participacao
      evolucao.value = response.data.evolucao

      // Distribui dados para cada composable
      kpisComposable.setKpis(response.data.kpis)
      kpisComposable.setIndicadores(response.data.indicadores_ambientais)
      eventosComposable.setEventosAtivos(response.data.eventos_ativos)
      tabelasComposable.setTabelasData({
        total_gerado_por_acao: response.data.total_gerado_por_acao,
        calculo_economia_energetica: response.data.calculo_economia_energetica,
        resumo_por_acao: response.data.resumo_por_acao,
        resumo_doacoes: response.data.resumo_doacoes
      })
    } catch (err: any) {
      error.value = err.message || 'Erro ao carregar métricas'
      console.error('Erro ao buscar métricas:', err)
    } finally {
      isLoading.value = false
    }
  }

  // Wrapper para atualizar filtros e recarregar
  const atualizarFiltros = (novos: Partial<FiltrosDashboard>) => {
    filtrosComposable.atualizarFiltros(novos)
    fetchMetrics()
  }

  const filtrarPorPeriodo = (periodo: PeriodoKey) => {
    filtrosComposable.filtrarPorPeriodo(periodo)
    fetchMetrics()
  }

  return {
    // Estado global
    isLoading,
    error,
    metrics,
    resumoParticipacao,
    evolucao,

    // Filtros
    filtros: filtrosComposable.filtros,
    periodoAtivo: filtrosComposable.periodoAtivo,
    atualizarFiltros,
    filtrarPorPeriodo,

    // KPIs
    kpis: kpisComposable.kpis,
    kpisFormatados: kpisComposable.kpisFormatados,
    indicadores: kpisComposable.indicadores,

    // Eventos
    eventosAtivos: eventosComposable.eventosAtivos,
    eventosAtivosMarkers: eventosComposable.eventosAtivosMarkers,
    colunasEventosAtivos: eventosComposable.colunasEventosAtivos,

    // Tabelas
    totalGeradoPorAcao: tabelasComposable.totalGeradoPorAcao,
    calculoEconomiaEnergetica: tabelasComposable.calculoEconomiaEnergetica,
    resumoPorAcao: tabelasComposable.resumoPorAcao,
    resumoDoacoes: tabelasComposable.resumoDoacoes,
    economiaAgrupadaPorAcao: tabelasComposable.economiaAgrupadaPorAcao,
    totaisTotalGerado: tabelasComposable.totaisTotalGerado,
    totalDoacoes: tabelasComposable.totalDoacoes,
    colunasTotalGerado: tabelasComposable.colunasTotalGerado,
    colunasResumoPorAcao: tabelasComposable.colunasResumoPorAcao,
    colunasDoacoes: tabelasComposable.colunasDoacoes,

    // Charts
    chartDistribuicaoTipoAcao: chartsComposable.chartDistribuicaoTipoAcao,
    chartEvolucao: chartsComposable.chartEvolucao,
    CATEGORY_COLORS: chartsComposable.CATEGORY_COLORS,

    // Actions
    fetchMetrics
  }
}

// Re-export types para conveniência
export type {
  KpiData,
  IndicadorAmbiental,
  EventoAtivo,
  TipoAcaoData,
  EcopontoLocalData,
  ResumoParticipacao,
  TotalGeradoPorAcao,
  CalculoEconomiaEnergetica,
  ResumoPorAcao,
  ResumoDoacao,
  EvolucaoData,
  DashboardMetrics,
  FiltrosDashboard,
  PeriodoKey
} from '../types/dashboard'
