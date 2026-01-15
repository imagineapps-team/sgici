import { ref, computed } from 'vue'
import type {
  TotalGeradoPorAcao,
  CalculoEconomiaEnergetica,
  ResumoPorAcao,
  ResumoDoacao,
  EconomiaGrupo,
  TotaisTotalGerado
} from '../types/dashboard'
import type { DataTableColumn } from '../types/datatable'
import { formatNumber } from '../utils'

export function useDashboardTabelas() {
  const totalGeradoPorAcao = ref<TotalGeradoPorAcao[]>([])
  const calculoEconomiaEnergetica = ref<CalculoEconomiaEnergetica[]>([])
  const resumoPorAcao = ref<ResumoPorAcao[]>([])
  const resumoDoacoes = ref<ResumoDoacao[]>([])

  // Computed: agrupa economia por ação
  const economiaAgrupadaPorAcao = computed<EconomiaGrupo[]>(() => {
    if (!calculoEconomiaEnergetica.value?.length) return []

    const agrupado: Record<string, CalculoEconomiaEnergetica[]> = {}
    calculoEconomiaEnergetica.value.forEach(item => {
      if (!agrupado[item.acao]) agrupado[item.acao] = []
      agrupado[item.acao].push(item)
    })

    return Object.entries(agrupado).map(([acao, items]) => ({ acao, items }))
  })

  // Computed: totais
  const totaisTotalGerado = computed<TotaisTotalGerado | null>(() => {
    if (!totalGeradoPorAcao.value?.length) return null

    return {
      quantidade: totalGeradoPorAcao.value.reduce((sum, item) => sum + (item.quantidade || 0), 0),
      valor: totalGeradoPorAcao.value.reduce((sum, item) => sum + (item.valor || 0), 0),
      kwheco: totalGeradoPorAcao.value.reduce((sum, item) => sum + (item.kwheco || 0), 0)
    }
  })

  const totalDoacoes = computed<number>(() => {
    if (!resumoDoacoes.value?.length) return 0
    return resumoDoacoes.value.reduce((sum, item) => sum + (item.bonus_total || 0), 0)
  })

  // Colunas
  const colunasTotalGerado: DataTableColumn<TotalGeradoPorAcao>[] = [
    { key: 'acao', label: 'Ação' },
    { key: 'quantidade', label: 'QTD (KG)', align: 'right', format: (v) => formatNumber(v, 2) },
    { key: 'valor', label: 'Valor (R$)', align: 'right', format: (v) => formatNumber(v, 2) },
    { key: 'kwheco', label: 'Economia (KW/H)', align: 'right', format: (v) => formatNumber(v, 2) }
  ]

  const colunasResumoPorAcao: DataTableColumn<ResumoPorAcao>[] = [
    { key: 'acao', label: 'Ação' },
    { key: 'local', label: 'Local' },
    { key: 'quantidade', label: 'QTD (KG)', align: 'right', format: (v) => formatNumber(v, 2) },
    { key: 'valor', label: 'Valor (R$)', align: 'right', format: (v) => formatNumber(v, 2) },
    { key: 'kwheco', label: 'KWH/ECO', align: 'right', format: (v) => formatNumber(v, 2) }
  ]

  const colunasDoacoes: DataTableColumn<ResumoDoacao>[] = [
    { key: 'recebedor', label: 'Recebedor' },
    { key: 'bonus_total', label: 'Bônus Total (R$)', align: 'right', format: (v) => formatNumber(v, 2) }
  ]

  // Setters
  const setTabelasData = (data: {
    total_gerado_por_acao?: TotalGeradoPorAcao[]
    calculo_economia_energetica?: CalculoEconomiaEnergetica[]
    resumo_por_acao?: ResumoPorAcao[]
    resumo_doacoes?: ResumoDoacao[]
  }) => {
    if (data.total_gerado_por_acao) totalGeradoPorAcao.value = data.total_gerado_por_acao
    if (data.calculo_economia_energetica) calculoEconomiaEnergetica.value = data.calculo_economia_energetica
    if (data.resumo_por_acao) resumoPorAcao.value = data.resumo_por_acao
    if (data.resumo_doacoes) resumoDoacoes.value = data.resumo_doacoes
  }

  return {
    // Refs
    totalGeradoPorAcao,
    calculoEconomiaEnergetica,
    resumoPorAcao,
    resumoDoacoes,
    // Computed
    economiaAgrupadaPorAcao,
    totaisTotalGerado,
    totalDoacoes,
    // Colunas
    colunasTotalGerado,
    colunasResumoPorAcao,
    colunasDoacoes,
    // Setters
    setTabelasData
  }
}
