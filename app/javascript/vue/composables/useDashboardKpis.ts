import { ref, computed } from 'vue'
import type { DashboardMetrics, IndicadorAmbiental, KpiFormatado } from '../types/dashboard'

// Funções auxiliares de formatação
function formatNumber(value: number): string {
  if (value >= 1000000) {
    return (value / 1000000).toFixed(2) + 'M'
  } else if (value >= 1000) {
    return (value / 1000).toFixed(2) + 'K'
  }
  return value.toFixed(2).replace('.', ',')
}

function formatCurrency(value: number): string {
  return new Intl.NumberFormat('pt-BR', {
    style: 'currency',
    currency: 'BRL'
  }).format(value)
}

export function useDashboardKpis() {
  const kpis = ref<DashboardMetrics['kpis'] | null>(null)
  const indicadores = ref<Record<string, IndicadorAmbiental>>({})

  const kpisFormatados = computed<KpiFormatado[]>(() => {
    if (!kpis.value) return []

    return [
      {
        key: 'co2_evitado',
        ...kpis.value.co2_evitado,
        valorFormatado: formatNumber(kpis.value.co2_evitado.valor),
        icone: 'co2',
        cor: 'text-green-600'
      },
      {
        key: 'peso_total',
        ...kpis.value.peso_total,
        valorFormatado: formatNumber(kpis.value.peso_total.valor),
        icone: 'scale',
        cor: 'text-blue-600'
      },
      {
        key: 'bonus_total',
        ...kpis.value.bonus_total,
        valorFormatado: formatCurrency(kpis.value.bonus_total.valor),
        icone: 'currency',
        cor: 'text-yellow-600'
      },
      {
        key: 'kwh_economizado',
        ...kpis.value.kwh_economizado,
        valorFormatado: formatNumber(kpis.value.kwh_economizado.valor),
        icone: 'bolt',
        cor: 'text-amber-600'
      }
    ]
  })

  const setKpis = (data: DashboardMetrics['kpis']) => {
    kpis.value = data
  }

  const setIndicadores = (data: Record<string, IndicadorAmbiental>) => {
    indicadores.value = data
  }

  return {
    kpis,
    kpisFormatados,
    indicadores,
    setKpis,
    setIndicadores
  }
}
