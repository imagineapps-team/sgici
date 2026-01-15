import { ref, reactive } from 'vue'
import type { FiltrosDashboard, PeriodoKey } from '../types/dashboard'

export function useDashboardFiltros(filtrosPadrao?: FiltrosDashboard) {
  const filtros = reactive<FiltrosDashboard>({
    dataInicial: filtrosPadrao?.dataInicial || new Date().toISOString().slice(0, 7) + '-01',
    dataFinal: filtrosPadrao?.dataFinal || new Date().toISOString().slice(0, 10)
  })

  const periodoAtivo = ref<PeriodoKey | null>('mes')

  const atualizarFiltros = (novos: Partial<FiltrosDashboard>) => {
    if (novos.dataInicial) filtros.dataInicial = novos.dataInicial
    if (novos.dataFinal) filtros.dataFinal = novos.dataFinal
  }

  const filtrarPorPeriodo = (periodo: PeriodoKey) => {
    periodoAtivo.value = periodo
    const hoje = new Date()
    let inicio: Date
    let fim: Date = hoje

    switch (periodo) {
      case 'hoje':
        inicio = hoje
        break
      case 'semana':
        inicio = new Date(hoje)
        inicio.setDate(hoje.getDate() - hoje.getDay())
        break
      case 'mes':
        inicio = new Date(hoje.getFullYear(), hoje.getMonth(), 1)
        break
      case 'anterior':
        inicio = new Date(hoje.getFullYear(), hoje.getMonth() - 1, 1)
        fim = new Date(hoje.getFullYear(), hoje.getMonth(), 0)
        break
      case 'ano':
        inicio = new Date(hoje.getFullYear(), 0, 1)
        break
      default:
        inicio = new Date(hoje.getFullYear(), hoje.getMonth(), 1)
    }

    filtros.dataInicial = inicio.toISOString().slice(0, 10)
    filtros.dataFinal = fim.toISOString().slice(0, 10)
  }

  return {
    filtros,
    periodoAtivo,
    atualizarFiltros,
    filtrarPorPeriodo
  }
}
