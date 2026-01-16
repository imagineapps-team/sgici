<template>
  <Head title="Dashboard" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header com filtros de periodo -->
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <h1 class="text-2xl font-bold text-gray-900">Dashboard</h1>

        <div class="flex items-center gap-3">
          <!-- Filtros de periodo rapido -->
          <div class="flex rounded-lg border border-gray-200 bg-white">
            <button
              v-for="periodo in periodos"
              :key="periodo.key"
              @click="handleFiltrarPeriodo(periodo.key)"
              :class="[
                'px-3 py-1.5 text-sm font-medium transition-colors',
                periodoAtivo === periodo.key
                  ? 'bg-brand-primary text-white'
                  : 'text-gray-600 hover:bg-gray-50'
              ]"
            >
              {{ periodo.label }}
            </button>
          </div>
        </div>
      </div>

      <!-- KPIs -->
      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        <div
          v-for="kpi in kpis"
          :key="kpi.key"
          class="bg-white rounded-lg shadow p-4"
        >
          <div class="text-sm text-gray-500">{{ kpi.label }}</div>
          <div class="text-2xl font-bold text-gray-900 mt-1">{{ kpi.valor }}</div>
          <div v-if="kpi.sublabel" class="text-xs text-gray-400 mt-1">{{ kpi.sublabel }}</div>
        </div>
      </div>

      <!-- Grid Principal -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Processos por Status -->
        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Processos por Status</h3>
          <div v-if="isLoading" class="h-64 flex items-center justify-center">
            <span class="text-gray-400">Carregando...</span>
          </div>
          <div v-else class="space-y-3">
            <div
              v-for="item in processosPorStatus"
              :key="item.status"
              class="flex items-center justify-between"
            >
              <div class="flex items-center gap-2">
                <span
                  :class="[
                    'w-3 h-3 rounded-full',
                    statusColor(item.status)
                  ]"
                ></span>
                <span class="text-sm text-gray-700">{{ item.statusLabel }}</span>
              </div>
              <div class="flex items-center gap-4">
                <span class="text-sm font-medium text-gray-900">{{ item.total }}</span>
                <span v-if="item.valorTotal > 0" class="text-xs text-gray-500">
                  USD {{ formatNumber(item.valorTotal) }}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Comparativo de Custos -->
        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">Custos por Categoria</h3>
          <div v-if="isLoading" class="h-64 flex items-center justify-center">
            <span class="text-gray-400">Carregando...</span>
          </div>
          <div v-else-if="custosComparativo.length === 0" class="h-64 flex items-center justify-center">
            <span class="text-gray-400">Sem dados no periodo</span>
          </div>
          <div v-else class="space-y-3">
            <div
              v-for="custo in custosComparativo"
              :key="custo.categoria"
              class="space-y-1"
            >
              <div class="flex items-center justify-between text-sm">
                <span class="text-gray-700">{{ custo.categoria }}</span>
                <span :class="variacaoClass(Number(custo.variacao))">
                  {{ Number(custo.variacao) > 0 ? '+' : '' }}{{ Number(custo.variacao).toFixed(1) }}%
                </span>
              </div>
              <div class="flex gap-2 h-2">
                <div
                  class="bg-blue-200 rounded"
                  :style="{ width: `${(custo.previsto / maxCusto) * 100}%` }"
                  :title="`Previsto: R$ ${formatNumber(custo.previsto)}`"
                ></div>
                <div
                  class="bg-green-200 rounded"
                  :style="{ width: `${(custo.real / maxCusto) * 100}%` }"
                  :title="`Real: R$ ${formatNumber(custo.real)}`"
                ></div>
              </div>
            </div>
            <div class="flex items-center gap-4 mt-4 text-xs text-gray-500">
              <span class="flex items-center gap-1"><span class="w-3 h-3 bg-blue-200 rounded"></span> Previsto</span>
              <span class="flex items-center gap-1"><span class="w-3 h-3 bg-green-200 rounded"></span> Real</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Tabelas -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Proximas Chegadas -->
        <div class="bg-white rounded-lg shadow">
          <div class="p-4 border-b border-gray-100">
            <h3 class="text-lg font-semibold text-gray-900">Proximas Chegadas</h3>
          </div>
          <div v-if="isLoading" class="p-4 text-center text-gray-400">
            Carregando...
          </div>
          <div v-else-if="proximasChegadas.length === 0" class="p-4 text-center text-gray-400">
            Nenhuma chegada prevista
          </div>
          <ul v-else class="divide-y divide-gray-100">
            <li
              v-for="processo in proximasChegadas"
              :key="processo.id"
              class="p-4 hover:bg-gray-50 cursor-pointer"
              @click="handleViewProcesso(processo.id)"
            >
              <div class="flex items-center justify-between">
                <div>
                  <div class="font-medium text-gray-900">{{ processo.numero }}</div>
                  <div class="text-sm text-gray-500">{{ processo.fornecedor }}</div>
                </div>
                <div class="text-right">
                  <div class="text-sm font-medium" :class="processo.diasParaChegada && processo.diasParaChegada < 3 ? 'text-yellow-600' : 'text-gray-600'">
                    {{ formatDate(processo.dataChegadaPrevista) }}
                  </div>
                  <div v-if="processo.diasParaChegada !== null" class="text-xs text-gray-400">
                    em {{ processo.diasParaChegada }} dias
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </div>

        <!-- Processos Atrasados -->
        <div class="bg-white rounded-lg shadow">
          <div class="p-4 border-b border-gray-100">
            <h3 class="text-lg font-semibold text-gray-900">Processos Atrasados</h3>
          </div>
          <div v-if="isLoading" class="p-4 text-center text-gray-400">
            Carregando...
          </div>
          <div v-else-if="processosAtrasados.length === 0" class="p-4 text-center text-green-600">
            Nenhum processo atrasado
          </div>
          <ul v-else class="divide-y divide-gray-100">
            <li
              v-for="processo in processosAtrasados"
              :key="processo.id"
              class="p-4 hover:bg-gray-50 cursor-pointer"
              @click="handleViewProcesso(processo.id)"
            >
              <div class="flex items-center justify-between">
                <div>
                  <div class="font-medium text-gray-900">{{ processo.numero }}</div>
                  <div class="text-sm text-gray-500">{{ processo.fornecedor }}</div>
                </div>
                <div class="text-right">
                  <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800">
                    Atrasado
                  </span>
                </div>
              </div>
            </li>
          </ul>
        </div>

        <!-- Ultimos Processos -->
        <div class="bg-white rounded-lg shadow">
          <div class="p-4 border-b border-gray-100">
            <h3 class="text-lg font-semibold text-gray-900">Ultimos Processos</h3>
          </div>
          <div v-if="isLoading" class="p-4 text-center text-gray-400">
            Carregando...
          </div>
          <div v-else-if="ultimosProcessos.length === 0" class="p-4 text-center text-gray-400">
            Nenhum processo encontrado
          </div>
          <ul v-else class="divide-y divide-gray-100">
            <li
              v-for="processo in ultimosProcessos"
              :key="processo.id"
              class="p-4 hover:bg-gray-50 cursor-pointer"
              @click="handleViewProcesso(processo.id)"
            >
              <div class="flex items-center justify-between">
                <div>
                  <div class="font-medium text-gray-900">{{ processo.numero }}</div>
                  <div class="text-sm text-gray-500">{{ processo.fornecedor }}</div>
                </div>
                <span
                  :class="[
                    'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium',
                    statusBadgeClass(processo.status)
                  ]"
                >
                  {{ processo.statusLabel }}
                </span>
              </div>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Head, router } from '@inertiajs/vue3'
import AppLayout from '../../layouts/AppLayout.vue'
import type { UserInfo } from '../../types/navigation'
import type { DashboardImportacaoMetrics, ProcessoResumo, ProcessoPorStatus, CustoPorCategoria, ProcessoStatus } from '../../types/importacao'
import { formatDate } from '../../utils'
import api from '../../lib/axios'

interface Props {
  usuario: UserInfo
  filtrosPadrao: {
    dataInicial: string
    dataFinal: string
  }
}

const props = defineProps<Props>()

const isLoading = ref(false)
const periodoAtivo = ref<'mes' | 'trimestre' | 'ano'>('mes')

const periodos = [
  { key: 'mes', label: 'Mes' },
  { key: 'trimestre', label: 'Trimestre' },
  { key: 'ano', label: 'Ano' }
] as const

// Data state
const metricsData = ref<DashboardImportacaoMetrics | null>(null)

// Computed values
const kpis = computed(() => {
  if (!metricsData.value) {
    return [
      { key: 'ativos', label: 'Processos Ativos', valor: '-' },
      { key: 'transito', label: 'Em Transito', valor: '-' },
      { key: 'valor', label: 'Valor em Transito', valor: '-', sublabel: 'USD' },
      { key: 'variacao', label: 'Variacao Media', valor: '-' },
      { key: 'alertas', label: 'Alertas', valor: '-' },
      { key: 'leadtime', label: 'Lead Time Medio', valor: '-', sublabel: 'dias' }
    ]
  }

  const { kpis: k } = metricsData.value

  return [
    { key: 'ativos', label: 'Processos Ativos', valor: k.processosAtivos.toString() },
    { key: 'transito', label: 'Em Transito', valor: k.processosEmTransito.toString() },
    { key: 'valor', label: 'Valor em Transito', valor: formatNumber(k.valorEmTransitoUsd), sublabel: 'USD' },
    { key: 'variacao', label: 'Variacao Media', valor: `${k.variacaoMediaCusto > 0 ? '+' : ''}${k.variacaoMediaCusto}%` },
    { key: 'alertas', label: 'Alertas', valor: k.alertasPendentes.toString() },
    { key: 'leadtime', label: 'Lead Time Medio', valor: k.leadTimeMedio.toString(), sublabel: 'dias' }
  ]
})

const processosPorStatus = computed<ProcessoPorStatus[]>(() => metricsData.value?.processosPorStatus || [])
const custosComparativo = computed<CustoPorCategoria[]>(() => metricsData.value?.custosComparativo || [])
const proximasChegadas = computed<ProcessoResumo[]>(() => metricsData.value?.proximasChegadas || [])
const processosAtrasados = computed<ProcessoResumo[]>(() => metricsData.value?.processosAtrasados || [])
const ultimosProcessos = computed<ProcessoResumo[]>(() => metricsData.value?.ultimosProcessos || [])

const maxCusto = computed(() => {
  if (!custosComparativo.value.length) return 1
  return Math.max(...custosComparativo.value.flatMap(c => [c.previsto, c.real]))
})

// Functions
function formatNumber(value: number): string {
  return new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value)
}

function statusColor(status: ProcessoStatus): string {
  const colors: Record<ProcessoStatus, string> = {
    planejado: 'bg-gray-400',
    aprovado: 'bg-blue-400',
    em_transito: 'bg-yellow-400',
    desembaracado: 'bg-purple-400',
    finalizado: 'bg-green-400',
    cancelado: 'bg-red-400'
  }
  return colors[status] || 'bg-gray-400'
}

function statusBadgeClass(status: ProcessoStatus): string {
  const classes: Record<ProcessoStatus, string> = {
    planejado: 'bg-gray-100 text-gray-800',
    aprovado: 'bg-blue-100 text-blue-800',
    em_transito: 'bg-yellow-100 text-yellow-800',
    desembaracado: 'bg-purple-100 text-purple-800',
    finalizado: 'bg-green-100 text-green-800',
    cancelado: 'bg-red-100 text-red-800'
  }
  return classes[status] || 'bg-gray-100 text-gray-800'
}

function variacaoClass(variacao: number): string {
  if (variacao > 10) return 'text-red-600 font-medium'
  if (variacao > 5) return 'text-yellow-600'
  if (variacao < -5) return 'text-green-600'
  return 'text-gray-600'
}

function getPeriodoDates(periodo: 'mes' | 'trimestre' | 'ano') {
  const hoje = new Date()
  let dataInicial: Date

  switch (periodo) {
    case 'mes':
      dataInicial = new Date(hoje.getFullYear(), hoje.getMonth(), 1)
      break
    case 'trimestre':
      dataInicial = new Date(hoje.getFullYear(), hoje.getMonth() - 2, 1)
      break
    case 'ano':
      dataInicial = new Date(hoje.getFullYear(), 0, 1)
      break
  }

  return {
    data_inicial: dataInicial.toISOString().split('T')[0],
    data_final: hoje.toISOString().split('T')[0]
  }
}

async function fetchMetrics(periodo: 'mes' | 'trimestre' | 'ano' = 'mes') {
  isLoading.value = true

  try {
    const params = getPeriodoDates(periodo)
    const response = await api.get('/dashboard/metrics', { params })
    metricsData.value = response.data
  } catch (err) {
    console.error('Erro ao carregar metricas:', err)
  } finally {
    isLoading.value = false
  }
}

function handleFiltrarPeriodo(periodo: 'mes' | 'trimestre' | 'ano') {
  periodoAtivo.value = periodo
  fetchMetrics(periodo)
}

function handleViewProcesso(id: number) {
  router.visit(`/processos_importacao/${id}`)
}

onMounted(() => {
  fetchMetrics(periodoAtivo.value)
})
</script>
