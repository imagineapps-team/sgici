import { computed, type Ref } from 'vue'
import type { EChartsOption } from 'echarts'
import type { ResumoParticipacao, EvolucaoData } from '../types/dashboard'

const CATEGORY_COLORS = [
  '#006cb6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6',
  '#EC4899', '#14B8A6', '#F97316', '#84CC16', '#6366F1'
]

export function useDashboardCharts(
  resumoParticipacao: Ref<ResumoParticipacao | null>,
  evolucao: Ref<EvolucaoData | null>
) {
  const chartDistribuicaoTipoAcao = computed<EChartsOption | null>(() => {
    if (!resumoParticipacao.value?.por_tipo_acao?.length) return null

    const data = resumoParticipacao.value.por_tipo_acao

    return {
      tooltip: {
        trigger: 'item',
        formatter: (params: any) => {
          return `${params.name}<br/><strong>${params.value}</strong> clientes (${params.data.percentual}%)`
        }
      },
      legend: {
        orient: 'vertical',
        right: 10,
        top: 'center',
        type: 'scroll',
        textStyle: { fontSize: 10 }
      },
      series: [{
        type: 'pie',
        radius: ['40%', '70%'],
        center: ['35%', '50%'],
        avoidLabelOverlap: true,
        itemStyle: {
          borderRadius: 4,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: { show: false },
        emphasis: {
          label: {
            show: true,
            fontSize: 12,
            fontWeight: 'bold'
          }
        },
        data: data.map((d, i) => ({
          name: d.tipo_acao,
          value: d.total,
          percentual: d.percentual,
          itemStyle: { color: CATEGORY_COLORS[i % CATEGORY_COLORS.length] }
        }))
      }]
    }
  })

  const chartEvolucao = computed<EChartsOption | null>(() => {
    if (!evolucao.value?.periodos?.length) return null

    return {
      tooltip: {
        trigger: 'axis'
      },
      legend: {
        data: evolucao.value.locais,
        bottom: 0,
        type: 'scroll'
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '15%',
        containLabel: true
      },
      xAxis: {
        type: 'category',
        boundaryGap: false,
        data: evolucao.value.periodos
      },
      yAxis: {
        type: 'value',
        name: 'Total Coletado (kg)'
      },
      series: evolucao.value.series.map((s, i) => ({
        name: s.name,
        type: 'line' as const,
        smooth: true,
        data: s.data,
        itemStyle: { color: CATEGORY_COLORS[i % CATEGORY_COLORS.length] },
        areaStyle: { opacity: 0.1 }
      }))
    }
  })

  return {
    chartDistribuicaoTipoAcao,
    chartEvolucao,
    CATEGORY_COLORS
  }
}
