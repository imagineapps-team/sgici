import { ref, onMounted, onUnmounted, watch, type Ref } from 'vue'
import * as echarts from 'echarts/core'
import {
  BarChart,
  LineChart,
  PieChart
} from 'echarts/charts'
import {
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent,
  DatasetComponent
} from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'
import type { EChartsOption } from 'echarts'
import { useBranding } from './useBranding'

// Registrar componentes necessários
echarts.use([
  BarChart,
  LineChart,
  PieChart,
  TitleComponent,
  TooltipComponent,
  LegendComponent,
  GridComponent,
  DatasetComponent,
  CanvasRenderer
])

export interface ChartColors {
  primary: string
  secondary: string
  accent: string
  success: string
  warning: string
  danger: string
  info: string
}

export function useECharts(chartRef: Ref<HTMLElement | null>) {
  const { primaryColor, secondaryColor } = useBranding()

  let chartInstance: echarts.ECharts | null = null
  const isLoading = ref(false)

  // Cores padrão para gráficos
  const chartColors: ChartColors = {
    primary: primaryColor.value || '#006cb6',
    secondary: secondaryColor.value || '#10B981',
    accent: '#F59E0B',
    success: '#22C55E',
    warning: '#EAB308',
    danger: '#EF4444',
    info: '#3B82F6'
  }

  // Paleta de cores para categorias
  const categoryColors = [
    '#006cb6', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6',
    '#EC4899', '#14B8A6', '#F97316', '#84CC16', '#6366F1'
  ]

  const initChart = () => {
    if (!chartRef.value) return

    chartInstance = echarts.init(chartRef.value)

    // Responsivo
    window.addEventListener('resize', handleResize)
  }

  const handleResize = () => {
    chartInstance?.resize()
  }

  const setOption = (option: EChartsOption) => {
    if (!chartInstance) {
      initChart()
    }
    chartInstance?.setOption(option)
  }

  const showLoading = () => {
    isLoading.value = true
    chartInstance?.showLoading({
      text: 'Carregando...',
      color: chartColors.primary,
      maskColor: 'rgba(255, 255, 255, 0.8)'
    })
  }

  const hideLoading = () => {
    isLoading.value = false
    chartInstance?.hideLoading()
  }

  const clear = () => {
    chartInstance?.clear()
  }

  const dispose = () => {
    chartInstance?.dispose()
    chartInstance = null
    window.removeEventListener('resize', handleResize)
  }

  // Gráfico de barras padrão
  const createBarChart = (
    data: { categoria: string; valor: number }[],
    options?: {
      title?: string
      xAxisLabel?: string
      yAxisLabel?: string
      horizontal?: boolean
    }
  ): EChartsOption => {
    const categories = data.map(d => d.categoria)
    const values = data.map(d => d.valor)

    return {
      title: options?.title ? { text: options.title, left: 'center' } : undefined,
      tooltip: {
        trigger: 'axis',
        axisPointer: { type: 'shadow' }
      },
      grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        containLabel: true
      },
      xAxis: options?.horizontal
        ? { type: 'value', name: options?.xAxisLabel }
        : { type: 'category', data: categories, name: options?.xAxisLabel },
      yAxis: options?.horizontal
        ? { type: 'category', data: categories, name: options?.yAxisLabel }
        : { type: 'value', name: options?.yAxisLabel },
      series: [{
        type: 'bar',
        data: values.map((v, i) => ({
          value: v,
          itemStyle: { color: categoryColors[i % categoryColors.length] }
        })),
        emphasis: { focus: 'series' }
      }]
    }
  }

  // Gráfico de linhas para evolução temporal
  const createLineChart = (
    data: {
      periodos: string[]
      series: { name: string; data: number[] }[]
    },
    options?: {
      title?: string
      yAxisLabel?: string
      smooth?: boolean
    }
  ): EChartsOption => {
    return {
      title: options?.title ? { text: options.title, left: 'center' } : undefined,
      tooltip: {
        trigger: 'axis'
      },
      legend: {
        data: data.series.map(s => s.name),
        bottom: 0
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
        data: data.periodos
      },
      yAxis: {
        type: 'value',
        name: options?.yAxisLabel
      },
      series: data.series.map((s, i) => ({
        name: s.name,
        type: 'line' as const,
        smooth: options?.smooth ?? true,
        data: s.data,
        itemStyle: { color: categoryColors[i % categoryColors.length] },
        areaStyle: { opacity: 0.1 }
      }))
    }
  }

  // Gráfico de pizza
  const createPieChart = (
    data: { name: string; value: number }[],
    options?: {
      title?: string
      donut?: boolean
    }
  ): EChartsOption => {
    return {
      title: options?.title ? { text: options.title, left: 'center' } : undefined,
      tooltip: {
        trigger: 'item',
        formatter: '{b}: {c} ({d}%)'
      },
      legend: {
        orient: 'vertical',
        left: 'left'
      },
      series: [{
        type: 'pie',
        radius: options?.donut ? ['40%', '70%'] : '70%',
        center: ['50%', '50%'],
        data: data.map((d, i) => ({
          ...d,
          itemStyle: { color: categoryColors[i % categoryColors.length] }
        })),
        emphasis: {
          itemStyle: {
            shadowBlur: 10,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        }
      }]
    }
  }

  onMounted(() => {
    if (chartRef.value) {
      initChart()
    }
  })

  onUnmounted(() => {
    dispose()
  })

  // Assistir mudanças no ref do elemento
  watch(chartRef, (newRef) => {
    if (newRef && !chartInstance) {
      initChart()
    }
  })

  return {
    chartInstance,
    isLoading,
    chartColors,
    categoryColors,
    initChart,
    setOption,
    showLoading,
    hideLoading,
    clear,
    dispose,
    createBarChart,
    createLineChart,
    createPieChart
  }
}
