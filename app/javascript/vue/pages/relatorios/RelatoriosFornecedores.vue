<template>
  <Head title="Performance Fornecedores" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Performance Fornecedores</h1>
          <p class="mt-1 text-sm text-gray-500">Indicadores de desempenho por fornecedor</p>
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
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <!-- Pais -->
          <ISelect
            v-model="filtros.pais"
            label="País"
            :options="paisOptions"
            placeholder="Todos"
            searchable
          />

          <!-- Ordenacao -->
          <ISelect
            v-model="ordenacao"
            label="Ordenar por"
            :options="ordenacaoOptions"
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

      <!-- KPIs -->
      <div v-if="dados.length > 0" class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Total Fornecedores</p>
          <p class="text-2xl font-bold text-gray-900">{{ dados.length }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Total Processos</p>
          <p class="text-2xl font-bold text-gray-900">{{ kpis.totalProcessos }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Valor Total FOB</p>
          <p class="text-2xl font-bold text-gray-900">{{ formatMoney(kpis.valorTotalFob) }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Lead Time Medio</p>
          <p class="text-2xl font-bold text-gray-900">{{ kpis.leadTimeMedio.toFixed(1) }} dias</p>
        </div>
      </div>

      <!-- Tabela -->
      <div class="bg-white rounded-lg shadow overflow-hidden">
        <div v-if="loading" class="p-8 text-center text-gray-500">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary mx-auto"></div>
          <p class="mt-2">Carregando dados...</p>
        </div>

        <div v-else-if="dados.length === 0" class="p-8 text-center text-gray-500">
          <BuildingOfficeIcon class="mx-auto h-12 w-12 text-gray-300" />
          <p class="mt-2">Nenhum fornecedor encontrado. Ajuste os filtros e clique em Buscar.</p>
        </div>

        <div v-else class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Fornecedor</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Pais</th>
                <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Processos</th>
                <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Ativos</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Valor FOB</th>
                <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Lead Time</th>
                <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Desvio</th>
                <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Score</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="fornecedor in dadosOrdenados" :key="fornecedor.id" class="hover:bg-gray-50">
                <td class="px-4 py-3 whitespace-nowrap">
                  <Link :href="`/fornecedores/${fornecedor.id}`" class="text-brand-primary hover:underline font-medium">
                    {{ fornecedor.nome }}
                  </Link>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500">
                  {{ fornecedor.pais || '-' }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900 text-center">
                  {{ fornecedor.totalProcessos }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-center">
                  <span v-if="fornecedor.processosAtivos > 0" class="text-blue-600 font-medium">
                    {{ fornecedor.processosAtivos }}
                  </span>
                  <span v-else class="text-gray-400">0</span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900 text-right">
                  {{ formatMoney(fornecedor.valorTotalFob) }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-center">
                  <span v-if="fornecedor.leadTimeMedio" :class="leadTimeClass(fornecedor.leadTimeMedio)">
                    {{ fornecedor.leadTimeMedio.toFixed(1) }}d
                  </span>
                  <span v-else class="text-gray-400">-</span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-center">
                  <span v-if="fornecedor.desvioMedio !== 0" :class="desvioClass(fornecedor.desvioMedio)">
                    {{ fornecedor.desvioMedio > 0 ? '+' : '' }}{{ fornecedor.desvioMedio.toFixed(1) }}%
                  </span>
                  <span v-else class="text-gray-400">-</span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-center">
                  <span
                    v-if="fornecedor.score != null"
                    :class="[
                      'px-2 py-1 text-xs rounded-full font-medium',
                      scoreClass(Number(fornecedor.score))
                    ]"
                  >
                    {{ Number(fornecedor.score).toFixed(1) }}
                  </span>
                  <span v-else class="text-gray-400">-</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { Head, Link } from '@inertiajs/vue3'
import {
  MagnifyingGlassIcon,
  ArrowDownTrayIcon,
  BuildingOfficeIcon
} from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import { ISelect } from '../../components/ISelect'
import type { UserInfo } from '../../types/navigation'
import type { SelectOption } from '../../components/ISelect/types'
import { formatMoney } from '../../utils'
import { useNotifications } from '../../composables/useNotification'
import api from '../../lib/axios'

interface FornecedorRelatorio {
  id: number
  nome: string
  pais: string | null
  totalProcessos: number
  processosAtivos: number
  valorTotalFob: number
  leadTimeMedio: number
  desvioMedio: number
  score: number | null
}

interface Props {
  usuario: UserInfo
  paisOptions: SelectOption[]
}

const props = defineProps<Props>()
const { error: showError } = useNotifications()

const loading = ref(false)
const dados = ref<FornecedorRelatorio[]>([])
const ordenacao = ref('score')

const filtros = ref({
  pais: ''
})

const ordenacaoOptions: SelectOption[] = [
  { value: 'nome', label: 'Nome' },
  { value: 'totalProcessos', label: 'Total de Processos' },
  { value: 'valorTotalFob', label: 'Valor Total FOB' },
  { value: 'leadTimeMedio', label: 'Lead Time Médio' },
  { value: 'desvioMedio', label: 'Desvio Médio' },
  { value: 'score', label: 'Score' }
]

// KPIs
const kpis = computed(() => {
  const totalProcessos = dados.value.reduce((sum, f) => sum + f.totalProcessos, 0)
  const valorTotalFob = dados.value.reduce((sum, f) => sum + f.valorTotalFob, 0)
  const fornecedoresComLeadTime = dados.value.filter(f => f.leadTimeMedio > 0)
  const leadTimeMedio = fornecedoresComLeadTime.length > 0
    ? fornecedoresComLeadTime.reduce((sum, f) => sum + f.leadTimeMedio, 0) / fornecedoresComLeadTime.length
    : 0

  return {
    totalProcessos,
    valorTotalFob,
    leadTimeMedio
  }
})

// Dados ordenados
const dadosOrdenados = computed(() => {
  return [...dados.value].sort((a, b) => {
    const field = ordenacao.value as keyof FornecedorRelatorio
    if (field === 'nome') {
      return a.nome.localeCompare(b.nome)
    }
    const aVal = (a[field] as number) || 0
    const bVal = (b[field] as number) || 0
    return bVal - aVal
  })
})

async function buscarDados() {
  loading.value = true
  try {
    const response = await api.post('/relatorios/fornecedores/data', {
      pais: filtros.value.pais || null
    })
    // Suporta ambos formatos: { data: [...] } ou [...]
    dados.value = Array.isArray(response.data) ? response.data : (response.data?.data || [])
  } catch (err) {
    console.error('Erro ao buscar dados:', err)
    showError('Erro ao buscar dados do relatório')
    dados.value = []
  } finally {
    loading.value = false
  }
}

function exportarExcel() {
  // Construir URL com filtros
  const params = new URLSearchParams()
  if (filtros.value.pais) params.append('pais', filtros.value.pais)

  // Download via window.location
  window.location.href = `/relatorios/fornecedores/excel?${params.toString()}`
}

function leadTimeClass(leadTime: number): string {
  if (leadTime > 60) return 'text-red-600 font-medium'
  if (leadTime > 45) return 'text-yellow-600'
  return 'text-green-600'
}

function desvioClass(desvio: number): string {
  if (desvio > 10) return 'text-red-600 font-medium'
  if (desvio > 5) return 'text-yellow-600'
  if (desvio < -5) return 'text-green-600'
  return 'text-gray-600'
}

function scoreClass(score: number): string {
  if (score >= 8) return 'bg-green-100 text-green-800'
  if (score >= 6) return 'bg-blue-100 text-blue-800'
  if (score >= 4) return 'bg-yellow-100 text-yellow-800'
  return 'bg-red-100 text-red-800'
}

onMounted(() => {
  buscarDados()
})
</script>
