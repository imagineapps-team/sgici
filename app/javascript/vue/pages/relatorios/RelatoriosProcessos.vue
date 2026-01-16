<template>
  <Head title="Relatorio de Processos" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">Relatorio de Processos</h1>
          <p class="mt-1 text-sm text-gray-500">Visao geral dos processos de importacao</p>
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
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          <!-- Status -->
          <ISelect
            v-model="filtros.status"
            label="Status"
            :options="statusOptions"
            placeholder="Todos"
          />

          <!-- Modal -->
          <ISelect
            v-model="filtros.modal"
            label="Modal"
            :options="modalOptions"
            placeholder="Todos"
          />

          <!-- Fornecedor -->
          <ISelect
            v-model="filtros.fornecedorId"
            label="Fornecedor"
            :options="fornecedoresOptions"
            placeholder="Todos"
            searchable
          />

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
        </div>

        <div class="mt-4 flex justify-end">
          <button
            @click="buscarDados"
            :disabled="loading"
            class="inline-flex items-center gap-2 px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark disabled:opacity-50"
          >
            <MagnifyingGlassIcon class="h-4 w-4" />
            {{ loading ? 'Buscando...' : 'Buscar' }}
          </button>
        </div>
      </div>

      <!-- KPIs -->
      <div v-if="totais" class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Total de Processos</p>
          <p class="text-2xl font-bold text-gray-900">{{ totais.quantidade }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Valor FOB Total</p>
          <p class="text-2xl font-bold text-gray-900">{{ formatMoney(totais.valorFobTotal) }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Custo Previsto Total</p>
          <p class="text-2xl font-bold text-gray-900">{{ formatMoney(totais.custoPrevistoTotal) }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Custo Real Total</p>
          <p class="text-2xl font-bold text-gray-900">{{ formatMoney(totais.custoRealTotal) }}</p>
        </div>
      </div>

      <!-- Tabela -->
      <div class="bg-white rounded-lg shadow overflow-hidden">
        <div v-if="loading" class="p-8 text-center text-gray-500">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-brand-primary mx-auto"></div>
          <p class="mt-2">Carregando dados...</p>
        </div>

        <div v-else-if="dados.length === 0" class="p-8 text-center text-gray-500">
          <DocumentChartBarIcon class="mx-auto h-12 w-12 text-gray-300" />
          <p class="mt-2">Nenhum processo encontrado. Ajuste os filtros e clique em Buscar.</p>
        </div>

        <div v-else class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Numero</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Fornecedor</th>
                <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Status</th>
                <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Modal</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Valor FOB</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Custo Previsto</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Custo Real</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase">Desvio</th>
                <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Lead Time</th>
                <th class="px-4 py-3 text-center text-xs font-medium text-gray-500 uppercase">Data</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="processo in dados" :key="processo.id" class="hover:bg-gray-50">
                <td class="px-4 py-3 whitespace-nowrap">
                  <Link :href="`/processos_importacao/${processo.id}`" class="text-brand-primary hover:underline font-medium">
                    {{ processo.numero }}
                  </Link>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900">{{ processo.fornecedor }}</td>
                <td class="px-4 py-3 whitespace-nowrap text-center">
                  <span :class="['px-2 py-1 text-xs rounded-full', statusClass(processo.status)]">
                    {{ processo.statusLabel }}
                  </span>
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500 text-center">{{ processo.modal }}</td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900 text-right">{{ formatMoney(processo.valorFob) }}</td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900 text-right">{{ formatMoney(processo.custoPrevistoTotal) }}</td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-900 text-right">{{ formatMoney(processo.custoRealTotal) }}</td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-right" :class="desvioClass(processo.desvioPercentual)">
                  {{ processo.desvioPercentual ? `${processo.desvioPercentual > 0 ? '+' : ''}${processo.desvioPercentual.toFixed(1)}%` : '-' }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500 text-center">
                  {{ processo.leadTimeDias ? `${processo.leadTimeDias}d` : '-' }}
                </td>
                <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500 text-center">{{ formatDate(processo.createdAt) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Head, Link } from '@inertiajs/vue3'
import {
  MagnifyingGlassIcon,
  ArrowDownTrayIcon,
  DocumentChartBarIcon
} from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import { ISelect } from '../../components/ISelect'
import { IInput } from '../../components/IInput'
import type { UserInfo } from '../../types/navigation'
import type { SelectOption } from '../../components/ISelect/types'
import { formatDate, formatMoney } from '../../utils'
import { useNotifications } from '../../composables/useNotification'
import api from '../../lib/axios'

interface ProcessoRelatorio {
  id: number
  numero: string
  fornecedor: string
  status: string
  statusLabel: string
  modal: string
  valorFob: number | null
  custoPrevistoTotal: number | null
  custoRealTotal: number | null
  desvioPercentual: number | null
  leadTimeDias: number | null
  createdAt: string
}

interface Totais {
  quantidade: number
  valorFobTotal: number
  custoPrevistoTotal: number
  custoRealTotal: number
}

interface Props {
  usuario: UserInfo
  statusOptions: SelectOption[]
  modalOptions: SelectOption[]
  fornecedoresOptions: SelectOption[]
}

const props = defineProps<Props>()
const { error: showError } = useNotifications()

const loading = ref(false)
const dados = ref<ProcessoRelatorio[]>([])
const totais = ref<Totais | null>(null)

const filtros = ref({
  status: '',
  modal: '',
  fornecedorId: '',
  dataInicio: new Date(new Date().getFullYear(), 0, 1).toISOString().split('T')[0],
  dataFim: new Date().toISOString().split('T')[0]
})

async function buscarDados() {
  loading.value = true
  try {
    const response = await api.post('/relatorios/processos/data', {
      status: filtros.value.status || null,
      modal: filtros.value.modal || null,
      fornecedor_id: filtros.value.fornecedorId || null,
      data_inicio: filtros.value.dataInicio || null,
      data_fim: filtros.value.dataFim || null
    })
    dados.value = response.data.data
    totais.value = response.data.totais
  } catch (err) {
    console.error('Erro ao buscar dados:', err)
    showError('Erro ao buscar dados do relatório')
  } finally {
    loading.value = false
  }
}

function exportarExcel() {
  // Construir URL com filtros
  const params = new URLSearchParams()
  if (filtros.value.status) params.append('status', filtros.value.status)
  if (filtros.value.modal) params.append('modal', filtros.value.modal)
  if (filtros.value.fornecedorId) params.append('fornecedor_id', filtros.value.fornecedorId)
  if (filtros.value.dataInicio) params.append('data_inicio', filtros.value.dataInicio)
  if (filtros.value.dataFim) params.append('data_fim', filtros.value.dataFim)

  // Download via window.location
  window.location.href = `/relatorios/processos/excel?${params.toString()}`
}

function statusClass(status: string): string {
  switch (status) {
    case 'planejado': return 'bg-gray-100 text-gray-800'
    case 'aprovado': return 'bg-blue-100 text-blue-800'
    case 'em_transito': return 'bg-yellow-100 text-yellow-800'
    case 'desembaracado': return 'bg-purple-100 text-purple-800'
    case 'finalizado': return 'bg-green-100 text-green-800'
    case 'cancelado': return 'bg-red-100 text-red-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}

function desvioClass(desvio: number | null): string {
  if (desvio === null) return 'text-gray-500'
  if (desvio > 10) return 'text-red-600 font-medium'
  if (desvio > 5) return 'text-yellow-600'
  if (desvio < -5) return 'text-green-600'
  return 'text-gray-600'
}

onMounted(() => {
  buscarDados()
})
</script>
