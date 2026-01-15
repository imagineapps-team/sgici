<template>
  <Head title="Histórico de Participação" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-4">
          <Link
            href="/relatorios"
            class="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeftIcon class="h-5 w-5" />
          </Link>
          <h1 class="text-2xl font-bold text-gray-900">Histórico de Participação (Dados Gerais)</h1>
        </div>
      </div>

      <!-- Filtros -->
      <div class="bg-white rounded-lg border border-gray-200 shadow-sm p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Filtros</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <!-- Evento/Coleta -->
          <ISelect
            v-model="filters.eventos"
            label="Coleta/Evento"
            :options="eventos"
            mode="multiple"
            placeholder="Todas as coletas"
            searchable
          />

          <!-- Contrato (NUC) -->
          <IInput
            v-model="filters.contrato_numero"
            label="Contrato (NUC)"
            placeholder="Digite o NUC"
          />

          <!-- Código da Reciclagem -->
          <IInput
            v-model="filters.codigo"
            label="Código da Reciclagem"
            placeholder="Digite o código"
          />

          <!-- Modelo -->
          <ISelect
            v-model="filters.modelo"
            label="Modelo do Relatório"
            :options="modelos"
            placeholder="Selecione o modelo"
          />

          <!-- Data Inicial -->
          <IInput
            v-model="filters.data_inicial"
            label="Data Inicial"
            type="date"
          />

          <!-- Data Final -->
          <IInput
            v-model="filters.data_final"
            label="Data Final"
            type="date"
          />

          <!-- Status -->
          <ISelect
            v-model="filters.status"
            label="Status"
            :options="statusOptions"
            placeholder="Todos exceto cancelados"
          />
        </div>

        <!-- Botões de Ação -->
        <div class="flex flex-wrap items-center gap-3 mt-6 pt-4 border-t border-gray-200">
          <button
            @click="buscar"
            :disabled="loading"
            class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
          >
            <MagnifyingGlassIcon class="h-5 w-5" />
            {{ loading ? 'Pesquisando...' : 'Pesquisar' }}
          </button>

          <button
            @click="exportExcel"
            :disabled="!hasData || exporting"
            class="inline-flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 transition-colors"
          >
            <TableCellsIcon class="h-5 w-5" />
            Excel
          </button>

          <button
            @click="exportPdf"
            :disabled="!hasData || exporting"
            class="inline-flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 transition-colors"
          >
            <DocumentArrowDownIcon class="h-5 w-5" />
            PDF
          </button>

          <button
            @click="limparFiltros"
            class="inline-flex items-center gap-2 px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition-colors"
          >
            <XMarkIcon class="h-5 w-5" />
            Limpar
          </button>
        </div>
      </div>

      <!-- Tabela de Resultados -->
      <div class="bg-white rounded-lg border border-gray-200 shadow-sm">
        <div v-if="loading" class="flex items-center justify-center py-12">
          <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
          <span class="ml-3 text-gray-500">Carregando dados...</span>
        </div>

        <div v-else-if="!hasData && searched" class="text-center py-12">
          <UserGroupIcon class="mx-auto h-12 w-12 text-gray-400" />
          <h3 class="mt-2 text-sm font-semibold text-gray-900">Nenhum resultado encontrado</h3>
          <p class="mt-1 text-sm text-gray-500">Tente ajustar os filtros da pesquisa.</p>
        </div>

        <div v-else-if="!searched" class="text-center py-12">
          <MagnifyingGlassIcon class="mx-auto h-12 w-12 text-gray-400" />
          <h3 class="mt-2 text-sm font-semibold text-gray-900">Aplique os filtros</h3>
          <p class="mt-1 text-sm text-gray-500">Selecione os filtros e clique em "Pesquisar" para visualizar os dados.</p>
        </div>

        <div v-else class="overflow-x-auto">
          <!-- Tabela Dados Gerais (DG) -->
          <table v-if="filters.modelo === 'DG'" class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Código</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Data</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">NUC</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nome</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Comunidade</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipo</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Evento</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Peso (Kg)</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Bônus (R$)</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">KWh Eco</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="(item, index) in dados" :key="index" class="hover:bg-gray-50">
                <td class="px-4 py-3 text-sm text-gray-900 font-mono">{{ item.rec_codigo }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.data_cadastro }}</td>
                <td class="px-4 py-3 text-sm text-gray-900">{{ item.nuc }}</td>
                <td class="px-4 py-3 text-sm text-gray-900">{{ item.nome }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.comunidade }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.tipo }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.evento }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.reciclagens_total_peso }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.reciclagens_total_valor }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right">{{ item.kwheco }}</td>
                <td class="px-4 py-3">
                  <span :class="statusClass(item.status)">
                    {{ item.status_label }}
                  </span>
                </td>
              </tr>
            </tbody>
            <tfoot class="bg-gray-100">
              <tr>
                <td colspan="7" class="px-4 py-3 text-sm font-bold text-gray-900">Total</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.peso }}</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.bonus }}</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.kwheco }}</td>
                <td class="px-4 py-3"></td>
              </tr>
            </tfoot>
          </table>

          <!-- Tabela Agrupado por Resíduo (AR) -->
          <table v-else class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">NUC</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Nome</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Comunidade</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipo</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Resíduo</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Peso (Kg)</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Bônus (R$)</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="(item, index) in dados" :key="index" class="hover:bg-gray-50">
                <td class="px-4 py-3 text-sm text-gray-900">{{ item.nuc }}</td>
                <td class="px-4 py-3 text-sm text-gray-900">{{ item.nome }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.comunidade }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.tipo }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.residuo }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.reciclagens_total_peso }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.reciclagens_total_valor }}</td>
              </tr>
            </tbody>
            <tfoot class="bg-gray-100">
              <tr>
                <td colspan="5" class="px-4 py-3 text-sm font-bold text-gray-900">Total</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.peso }}</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.bonus }}</td>
              </tr>
            </tfoot>
          </table>
        </div>

        <!-- Contador de resultados -->
        <div v-if="hasData" class="px-4 py-3 bg-gray-50 border-t border-gray-200 text-sm text-gray-500">
          {{ dados.length }} registro(s) encontrado(s)
        </div>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, reactive, computed, watch } from 'vue'
import { Head, Link } from '@inertiajs/vue3'
import {
  ArrowLeftIcon,
  MagnifyingGlassIcon,
  TableCellsIcon,
  DocumentArrowDownIcon,
  XMarkIcon,
  UserGroupIcon
} from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import { IInput } from '../../components/IInput'
import { ISelect } from '../../components/ISelect'
import { useNotifications } from '../../composables/useNotification'
import api from '../../lib/axios'
import type { UserInfo } from '../../types/navigation'
import type { SelectOption } from '../../components/ISelect/types'

interface Props {
  usuario: UserInfo
  eventos: SelectOption[]
  modelos: SelectOption[]
  statusOptions: SelectOption[]
}

const props = defineProps<Props>()
const { error: showError } = useNotifications()

const loading = ref(false)
const exporting = ref(false)
const searched = ref(false)
const dados = ref<any[]>([])

const filters = reactive({
  eventos: [] as (string | number)[],
  contrato_numero: '',
  codigo: '',
  data_inicial: '',
  data_final: '',
  modelo: 'DG',
  status: ['-X'] as (string | number)[]
})

const hasData = computed(() => dados.value.length > 0)

const totais = computed(() => {
  if (!hasData.value) return { peso: '0,00', bonus: '0,00', kwheco: '0,00' }

  const parseNumber = (str: string) => {
    if (!str) return 0
    return parseFloat(str.replace(/\./g, '').replace(',', '.')) || 0
  }

  const peso = dados.value.reduce((sum, item) => sum + parseNumber(item.reciclagens_total_peso), 0)
  const bonus = dados.value.reduce((sum, item) => sum + parseNumber(item.reciclagens_total_valor), 0)
  const kwheco = dados.value.reduce((sum, item) => sum + parseNumber(item.kwheco), 0)

  const formatNumber = (num: number) => num.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

  return {
    peso: formatNumber(peso),
    bonus: formatNumber(bonus),
    kwheco: formatNumber(kwheco)
  }
})

function statusClass(status: string) {
  const classes: Record<string, string> = {
    'R': 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800',
    'T': 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800',
    'P': 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800',
    'X': 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800'
  }
  return classes[status] || 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800'
}

async function buscar() {
  if (!filters.data_inicial && !filters.data_final && filters.eventos.length === 0 && !filters.codigo && !filters.contrato_numero) {
    showError('Informe um evento, um período de datas, um código ou um contrato antes de pesquisar')
    return
  }

  loading.value = true
  searched.value = true
  dados.value = []

  try {
    const response = await api.post('/relatorios/historico_participacao/data', {
      modelo: filters.modelo,
      data_inicial: filters.data_inicial,
      data_final: filters.data_final,
      eventos: filters.eventos,
      contrato_numero: filters.contrato_numero,
      codigo: filters.codigo,
      status: filters.status
    })
    dados.value = response.data
  } catch (err: any) {
    showError(err.response?.data?.error || 'Erro ao buscar dados do relatório')
  } finally {
    loading.value = false
  }
}

function exportExcel() {
  exporting.value = true
  const params = new URLSearchParams({
    modelo: filters.modelo,
    data_inicial: filters.data_inicial,
    data_final: filters.data_final,
    contrato_numero: filters.contrato_numero,
    codigo: filters.codigo
  })
  filters.eventos.forEach(e => params.append('eventos[]', String(e)))
  filters.status.forEach(s => params.append('status[]', String(s)))

  window.location.href = `/relatorios/historico_participacao/excel?${params.toString()}`
  setTimeout(() => { exporting.value = false }, 2000)
}

function exportPdf() {
  exporting.value = true
  const params = new URLSearchParams({
    modelo: filters.modelo,
    data_inicial: filters.data_inicial,
    data_final: filters.data_final,
    contrato_numero: filters.contrato_numero,
    codigo: filters.codigo
  })
  filters.eventos.forEach(e => params.append('eventos[]', String(e)))
  filters.status.forEach(s => params.append('status[]', String(s)))

  window.location.href = `/relatorios/historico_participacao/pdf?${params.toString()}`
  setTimeout(() => { exporting.value = false }, 2000)
}

function limparFiltros() {
  filters.eventos = []
  filters.contrato_numero = ''
  filters.codigo = ''
  filters.data_inicial = ''
  filters.data_final = ''
  filters.modelo = 'DG'
  filters.status = ['-X']
  dados.value = []
  searched.value = false
}

// Limpa dados ao mudar o modelo para forçar nova pesquisa
watch(() => filters.modelo, (newValue, oldValue) => {
  if (oldValue !== undefined) {
    dados.value = []
    searched.value = false
  }
})
</script>
