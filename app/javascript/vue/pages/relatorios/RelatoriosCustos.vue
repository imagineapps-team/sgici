<template>
  <Head title="Analise de Custos" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Analise de Custos</h1>
          <p class="mt-1 text-sm text-gray-500">Comparativo de custos previstos vs reais por categoria</p>
        </div>
        <div class="flex items-center gap-3">
          <button
            @click="exportarExcel"
            :disabled="loading || dados.length === 0"
            class="inline-flex items-center gap-2 px-4 py-2 text-sm bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50"
          >
            <ArrowDownTrayIcon class="h-4 w-4" />
            Excel
          </button>
          <Link href="/relatorios" class="text-brand-primary hover:underline">
            &larr; Voltar
          </Link>
        </div>
      </div>

      <!-- Filtros -->
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-sm font-medium text-gray-700 mb-4">Filtros</h3>
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <!-- Periodo -->
          <IInput
            v-model="filtros.dataInicio"
            label="De"
            type="date"
          />

          <IInput
            v-model="filtros.dataFim"
            label="Até"
            type="date"
          />

          <!-- Fornecedor -->
          <ISelect
            v-model="filtros.fornecedorId"
            label="Fornecedor"
            :options="fornecedoresOptions"
            placeholder="Todos"
            searchable
          />

          <div class="flex items-end">
            <button
              @click="buscarDados"
              :disabled="loading"
              class="w-full inline-flex items-center justify-center gap-2 px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark disabled:opacity-50"
            >
              <MagnifyingGlassIcon class="h-4 w-4" />
              {{ loading ? 'Buscando...' : 'Buscar' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Grafico -->
      <div class="bg-white rounded-lg shadow p-6">
        <h3 class="text-lg font-semibold text-gray-900 mb-4">Grafico Comparativo</h3>

        <!-- Loading overlay -->
        <div v-show="loading" class="h-80 flex items-center justify-center">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary"></div>
        </div>

        <!-- Empty state -->
        <div v-show="!loading && dados.length === 0" class="h-80 flex items-center justify-center text-gray-500">
          <div class="text-center">
            <ChartBarIcon class="mx-auto h-12 w-12 text-gray-300" />
            <p class="mt-2">Nenhum dado encontrado para o periodo selecionado</p>
          </div>
        </div>

        <!-- Chart container - sempre no DOM para ECharts funcionar -->
        <div v-show="!loading && dados.length > 0" ref="chartRef" class="h-80"></div>
      </div>

      <!-- Tabela -->
      <div class="bg-white rounded-lg shadow overflow-hidden">
        <div class="px-6 py-4 border-b border-gray-200">
          <h3 class="text-lg font-semibold text-gray-900">Detalhamento por Categoria</h3>
          <p v-if="periodo" class="text-sm text-gray-500">
            Periodo: {{ formatDate(periodo.inicio) }} a {{ formatDate(periodo.fim) }}
          </p>
        </div>

        <div v-if="dados.length === 0" class="p-8 text-center text-gray-500">
          <CurrencyDollarIcon class="mx-auto h-12 w-12 text-gray-300" />
          <p class="mt-2">Nenhum dado encontrado</p>
        </div>

        <div v-else class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Categoria</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Previsto</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Real</th>
                <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">Variacao</th>
                <th class="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase">%</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="item in dados" :key="item.categoria" class="hover:bg-gray-50">
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                  {{ item.categoria }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 text-right">
                  {{ formatMoney(item.previsto) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900 text-right">
                  {{ formatMoney(item.real) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-right" :class="variacaoClass(item.variacao)">
                  {{ formatMoney(item.real - item.previsto) }}
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-center">
                  <span
                    :class="[
                      'px-2 py-1 text-xs rounded-full font-medium',
                      variacaoBadgeClass(item.variacao)
                    ]"
                  >
                    {{ item.variacao > 0 ? '+' : '' }}{{ item.variacao.toFixed(1) }}%
                  </span>
                </td>
              </tr>
            </tbody>
            <tfoot class="bg-gray-50">
              <tr>
                <td class="px-6 py-3 text-sm font-semibold text-gray-900">Total</td>
                <td class="px-6 py-3 text-sm font-semibold text-gray-900 text-right">{{ formatMoney(totalPrevisto) }}</td>
                <td class="px-6 py-3 text-sm font-semibold text-gray-900 text-right">{{ formatMoney(totalReal) }}</td>
                <td class="px-6 py-3 text-sm font-semibold text-right" :class="variacaoClass(variacaoTotal)">
                  {{ formatMoney(totalReal - totalPrevisto) }}
                </td>
                <td class="px-6 py-3 text-center">
                  <span
                    :class="[
                      'px-2 py-1 text-xs rounded-full font-medium',
                      variacaoBadgeClass(variacaoTotal)
                    ]"
                  >
                    {{ variacaoTotal > 0 ? '+' : '' }}{{ variacaoTotal.toFixed(1) }}%
                  </span>
                </td>
              </tr>
            </tfoot>
          </table>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted, watch, nextTick } from 'vue'
import { Head, Link } from '@inertiajs/vue3'
import {
  MagnifyingGlassIcon,
  ArrowDownTrayIcon,
  ChartBarIcon,
  CurrencyDollarIcon
} from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import { ISelect } from '../../components/ISelect'
import { IInput } from '../../components/IInput'
import type { UserInfo } from '../../types/navigation'
import type { SelectOption } from '../../components/ISelect/types'
import { formatDate, formatMoney } from '../../utils'
import { useNotifications } from '../../composables/useNotification'
import api from '../../lib/axios'
import * as echarts from 'echarts/core'
import { BarChart } from 'echarts/charts'
import {
  TooltipComponent,
  LegendComponent,
  GridComponent
} from 'echarts/components'
import { CanvasRenderer } from 'echarts/renderers'

// Registrar componentes ECharts
echarts.use([BarChart, TooltipComponent, LegendComponent, GridComponent, CanvasRenderer])

interface CustoRelatorio {
  categoria: string
  previsto: number
  real: number
  variacao: number
}

interface Props {
  usuario: UserInfo
  categoriaOptions: SelectOption[]
  fornecedoresOptions: SelectOption[]
}

const props = defineProps<Props>()
const { error: showError } = useNotifications()

const loading = ref(false)
const dados = ref<CustoRelatorio[]>([])
const periodo = ref<{ inicio: string; fim: string } | null>(null)
const chartRef = ref<HTMLElement | null>(null)
let chartInstance: echarts.ECharts | null = null

const filtros = ref({
  dataInicio: new Date(new Date().getFullYear(), 0, 1).toISOString().split('T')[0],
  dataFim: new Date().toISOString().split('T')[0],
  fornecedorId: ''
})

// Computed totals
const totalPrevisto = computed(() => dados.value.reduce((sum, item) => sum + item.previsto, 0))
const totalReal = computed(() => dados.value.reduce((sum, item) => sum + item.real, 0))
const variacaoTotal = computed(() => {
  if (totalPrevisto.value === 0) return 0
  return ((totalReal.value - totalPrevisto.value) / totalPrevisto.value) * 100
})

async function buscarDados() {
  loading.value = true
  try {
    const response = await api.post('/relatorios/custos/data', {
      data_inicio: filtros.value.dataInicio || null,
      data_fim: filtros.value.dataFim || null,
      fornecedor_id: filtros.value.fornecedorId || null
    })
    dados.value = response.data.data
    periodo.value = response.data.periodo
  } catch (err) {
    console.error('Erro ao buscar dados:', err)
    showError('Erro ao buscar dados do relatório')
  } finally {
    loading.value = false
    // Renderizar grafico apos loading=false para que o chartRef exista no DOM
    await nextTick()
    renderChart()
  }
}

function renderChart() {
  if (!chartRef.value || dados.value.length === 0) {
    return
  }

  // Verificar dimensoes do container
  const rect = chartRef.value.getBoundingClientRect()
  if (rect.width === 0 || rect.height === 0) {
    // Container nao visivel ainda, tentar novamente
    setTimeout(() => renderChart(), 50)
    return
  }

  // Inicializar ou reutilizar instancia
  if (!chartInstance) {
    chartInstance = echarts.init(chartRef.value)
  } else {
    // Resize para garantir dimensoes corretas
    chartInstance.resize()
  }

  const categorias = dados.value.map(d => d.categoria)
  const previstos = dados.value.map(d => d.previsto)
  const reais = dados.value.map(d => d.real)

  const option: echarts.EChartsCoreOption = {
    tooltip: {
      trigger: 'axis',
      axisPointer: { type: 'shadow' },
      formatter: (params: any) => {
        const cat = params[0]?.axisValue || ''
        const prev = params[0]?.value || 0
        const real = params[1]?.value || 0
        const variacao = prev > 0 ? ((real - prev) / prev * 100).toFixed(1) : '0'
        return `<strong>${cat}</strong><br/>
                Previsto: R$ ${prev.toLocaleString('pt-BR')}<br/>
                Real: R$ ${real.toLocaleString('pt-BR')}<br/>
                Variacao: ${variacao}%`
      }
    },
    legend: {
      data: ['Previsto', 'Real'],
      bottom: 0
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '15%',
      top: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: categorias,
      axisLabel: {
        rotate: categorias.length > 3 ? 30 : 0,
        interval: 0,
        fontSize: 11
      }
    },
    yAxis: {
      type: 'value',
      axisLabel: {
        formatter: (value: number) => {
          if (value >= 1000000) return `R$ ${(value / 1000000).toFixed(1)}M`
          if (value >= 1000) return `R$ ${(value / 1000).toFixed(0)}k`
          return `R$ ${value}`
        }
      }
    },
    series: [
      {
        name: 'Previsto',
        type: 'bar',
        data: previstos,
        itemStyle: { color: '#60a5fa' },
        barGap: '10%'
      },
      {
        name: 'Real',
        type: 'bar',
        data: reais,
        itemStyle: { color: '#f97316' }
      }
    ]
  }

  chartInstance.setOption(option, true)
}

function exportarExcel() {
  // Construir URL com filtros
  const params = new URLSearchParams()
  if (filtros.value.dataInicio) params.append('data_inicio', filtros.value.dataInicio)
  if (filtros.value.dataFim) params.append('data_fim', filtros.value.dataFim)
  if (filtros.value.fornecedorId) params.append('fornecedor_id', filtros.value.fornecedorId)

  // Download via window.location
  window.location.href = `/relatorios/custos/excel?${params.toString()}`
}

function variacaoClass(variacao: number): string {
  if (variacao > 10) return 'text-red-600 font-medium'
  if (variacao > 5) return 'text-yellow-600'
  if (variacao < -5) return 'text-green-600'
  return 'text-gray-600'
}

function variacaoBadgeClass(variacao: number): string {
  if (variacao > 10) return 'bg-red-100 text-red-800'
  if (variacao > 5) return 'bg-yellow-100 text-yellow-800'
  if (variacao < -5) return 'bg-green-100 text-green-800'
  return 'bg-gray-100 text-gray-800'
}

// Resize handler
function handleResize() {
  if (chartInstance) {
    chartInstance.resize()
  }
}

onMounted(() => {
  buscarDados()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  if (chartInstance) {
    chartInstance.dispose()
    chartInstance = null
  }
})
</script>
