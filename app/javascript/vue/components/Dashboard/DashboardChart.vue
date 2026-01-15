<script setup lang="ts">
import { ref, watch, onMounted, onUnmounted, nextTick } from 'vue'
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

interface Props {
  option: EChartsOption | null
  height?: string
  loading?: boolean
  titulo?: string
  bare?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  height: '300px',
  loading: false,
  bare: false
})

const chartRef = ref<HTMLElement | null>(null)
let chartInstance: echarts.ECharts | null = null
let resizeObserver: ResizeObserver | null = null

const initChart = () => {
  if (!chartRef.value) return

  // Verificar se o container tem dimensões válidas
  const rect = chartRef.value.getBoundingClientRect()
  if (rect.width === 0 || rect.height === 0) {
    // Container ainda não está visível, aguardar
    return
  }

  if (!chartInstance) {
    chartInstance = echarts.init(chartRef.value)
  }

  if (props.option) {
    chartInstance.setOption(props.option, true)
  }
}

const handleResize = () => {
  if (!chartRef.value) return

  const rect = chartRef.value.getBoundingClientRect()
  if (rect.width > 0 && rect.height > 0) {
    if (!chartInstance) {
      initChart()
    } else {
      chartInstance.resize()
    }
  }
}

// Usar ResizeObserver para detectar quando o container se torna visível
const setupResizeObserver = () => {
  if (!chartRef.value) return

  resizeObserver = new ResizeObserver((entries) => {
    for (const entry of entries) {
      if (entry.contentRect.width > 0 && entry.contentRect.height > 0) {
        nextTick(() => {
          handleResize()
        })
      }
    }
  })

  resizeObserver.observe(chartRef.value)
}

watch(
  () => props.option,
  (newOption) => {
    if (newOption) {
      nextTick(() => {
        if (chartInstance) {
          chartInstance.setOption(newOption, true)
        } else {
          initChart()
        }
      })
    }
  },
  { deep: true }
)

watch(
  () => props.loading,
  (loading) => {
    if (loading) {
      chartInstance?.showLoading({
        text: 'Carregando...',
        color: '#006cb6',
        maskColor: 'rgba(255, 255, 255, 0.8)'
      })
    } else {
      chartInstance?.hideLoading()
    }
  }
)

onMounted(() => {
  nextTick(() => {
    initChart()
    setupResizeObserver()
  })
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  chartInstance?.dispose()
  chartInstance = null
  resizeObserver?.disconnect()
  resizeObserver = null
  window.removeEventListener('resize', handleResize)
})
</script>

<template>
  <div :class="bare ? '' : 'bg-white rounded-lg shadow-sm border border-gray-200 p-4'">
    <h3 v-if="titulo && !bare" class="text-lg font-semibold text-gray-800 mb-4">
      {{ titulo }}
    </h3>
    <!-- Gráfico -->
    <div
      v-show="option || loading"
      ref="chartRef"
      :style="{ height }"
      class="w-full"
    />
    <!-- Mensagem quando não há dados -->
    <div
      v-if="!option && !loading"
      class="flex items-center justify-center text-gray-400"
      :style="{ height }"
    >
      Sem dados para exibir
    </div>
  </div>
</template>
