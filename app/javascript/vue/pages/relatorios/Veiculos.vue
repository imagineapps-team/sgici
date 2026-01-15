<template>
  <Head title="Veiculos" />

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
          <h1 class="text-2xl font-bold text-gray-900">Relatorio de Veiculos</h1>
        </div>
      </div>

      <!-- Filtros -->
      <div class="bg-white rounded-lg border border-gray-200 shadow-sm p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Filtros</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <!-- Tipo de Veiculo -->
          <ISelect
            v-model="filters.tipo_veiculo"
            label="Tipo de Veiculo"
            :options="tipoVeiculos"
            mode="multiple"
            placeholder="Todos os tipos"
            searchable
          />

          <!-- Placa -->
          <ISelect
            v-model="filters.placa"
            label="Placa"
            :options="veiculosPlacas"
            mode="multiple"
            placeholder="Todas as placas"
            searchable
          />

          <!-- Tipo de Residuo -->
          <ISelect
            v-model="filters.recurso"
            label="Tipo de Residuo"
            :options="tipoRecursos"
            mode="multiple"
            placeholder="Todos os residuos"
            searchable
          />

          <!-- Local da Acao -->
          <ISelect
            v-model="filters.local"
            label="Local da Acao"
            :options="locais"
            mode="multiple"
            placeholder="Todos os locais"
            searchable
          />

          <!-- Data Inicial -->
          <IInput
            v-model="filters.data_inicial"
            label="Data Inicial"
            type="date"
            required
          />

          <!-- Data Final -->
          <IInput
            v-model="filters.data_final"
            label="Data Final"
            type="date"
            required
          />

          <!-- Modelo -->
          <ISelect
            v-model="filters.modelo"
            label="Modelo do Relatorio"
            :options="modelos"
            placeholder="Selecione o modelo"
          />

          <!-- Status -->
          <ISelect
            v-model="filters.status"
            label="Status"
            :options="statusOptions"
            mode="multiple"
            placeholder="Todos (exceto Cancelados)"
          />
        </div>

        <!-- Botoes de Acao -->
        <div class="flex flex-wrap items-center gap-3 mt-6 pt-4 border-t border-gray-200">
          <button
            @click="buscar"
            :disabled="loading || !canSearch"
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
          <TruckIcon class="mx-auto h-12 w-12 text-gray-400" />
          <h3 class="mt-2 text-sm font-semibold text-gray-900">Nenhum resultado encontrado</h3>
          <p class="mt-1 text-sm text-gray-500">Tente ajustar os filtros da pesquisa.</p>
        </div>

        <div v-else-if="!searched" class="text-center py-12">
          <MagnifyingGlassIcon class="mx-auto h-12 w-12 text-gray-400" />
          <h3 class="mt-2 text-sm font-semibold text-gray-900">Aplique os filtros</h3>
          <p class="mt-1 text-sm text-gray-500">Informe as datas e clique em "Pesquisar".</p>
        </div>

        <div v-else class="overflow-x-auto">
          <!-- Tabela RG - Geral -->
          <table v-if="filters.modelo === 'RG'" class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Veiculo</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Placa</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipo Residuo</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Local</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Valor (R$)</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Qtd (Kg)</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Data</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="(item, index) in dados" :key="index" class="hover:bg-gray-50">
                <td class="px-4 py-3 text-sm text-gray-900 font-medium">{{ item.veiculo_tipo }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.placa }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.recurso_tipo }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.local_acao }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.bonus_total }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.quantidade_total }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.data_cadastro }}</td>
              </tr>
            </tbody>
            <tfoot class="bg-gray-100">
              <tr>
                <td colspan="4" class="px-4 py-3 text-sm font-bold text-gray-900">Total</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.bonus }}</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.quantidade }}</td>
                <td></td>
              </tr>
            </tfoot>
          </table>

          <!-- Tabela RR - Por Tipo de Residuo -->
          <table v-else-if="filters.modelo === 'RR'" class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Veiculo</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Placa</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Tipo Residuo</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Valor (R$)</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Qtd (Kg)</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Data</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="(item, index) in dados" :key="index" class="hover:bg-gray-50">
                <td class="px-4 py-3 text-sm text-gray-900 font-medium">{{ item.veiculo_tipo }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.placa }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.recurso_tipo }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.bonus_total }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.quantidade_total }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.data_cadastro }}</td>
              </tr>
            </tbody>
            <tfoot class="bg-gray-100">
              <tr>
                <td colspan="3" class="px-4 py-3 text-sm font-bold text-gray-900">Total</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.bonus }}</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.quantidade }}</td>
                <td></td>
              </tr>
            </tfoot>
          </table>

          <!-- Tabela RV - Por Veiculo -->
          <table v-else-if="filters.modelo === 'RV'" class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Veiculo</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Placa</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Valor (R$)</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Qtd (Kg)</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Data</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="(item, index) in dados" :key="index" class="hover:bg-gray-50">
                <td class="px-4 py-3 text-sm text-gray-900 font-medium">{{ item.veiculo_tipo }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.placa }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.bonus_total }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.quantidade_total }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.data_cadastro }}</td>
              </tr>
            </tbody>
            <tfoot class="bg-gray-100">
              <tr>
                <td colspan="2" class="px-4 py-3 text-sm font-bold text-gray-900">Total</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.bonus }}</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.quantidade }}</td>
                <td></td>
              </tr>
            </tfoot>
          </table>

          <!-- Tabela RL - Por Local -->
          <table v-else class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Veiculo</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Placa</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Local</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Valor (R$)</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Qtd (Kg)</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Data</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="(item, index) in dados" :key="index" class="hover:bg-gray-50">
                <td class="px-4 py-3 text-sm text-gray-900 font-medium">{{ item.veiculo_tipo }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.placa }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.local_acao }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.bonus_total }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.quantidade_total }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.data_cadastro }}</td>
              </tr>
            </tbody>
            <tfoot class="bg-gray-100">
              <tr>
                <td colspan="3" class="px-4 py-3 text-sm font-bold text-gray-900">Total</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.bonus }}</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.quantidade }}</td>
                <td></td>
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
  TruckIcon
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
  tipoVeiculos: SelectOption[]
  veiculosPlacas: SelectOption[]
  tipoRecursos: SelectOption[]
  locais: SelectOption[]
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
  tipo_veiculo: [] as (string | number)[],
  placa: [] as (string | number)[],
  recurso: [] as (string | number)[],
  local: [] as (string | number)[],
  data_inicial: '',
  data_final: '',
  modelo: 'RG',
  status: [] as (string | number)[]
})

const hasData = computed(() => dados.value.length > 0)
const canSearch = computed(() => filters.data_inicial && filters.data_final)

const totais = computed(() => {
  if (!hasData.value) return { bonus: '0,00', quantidade: '0,00' }

  const parseNumber = (str: string) => {
    if (!str) return 0
    return parseFloat(str.replace(/\./g, '').replace(',', '.')) || 0
  }

  const bonus = dados.value.reduce((sum, item) => sum + parseNumber(item.bonus_total), 0)
  const quantidade = dados.value.reduce((sum, item) => sum + parseNumber(item.quantidade_total), 0)

  const formatNumber = (num: number) => num.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })

  return {
    bonus: formatNumber(bonus),
    quantidade: formatNumber(quantidade)
  }
})

async function buscar() {
  if (!filters.data_inicial || !filters.data_final) {
    showError('Informe as datas inicial e final')
    return
  }

  loading.value = true
  searched.value = true
  dados.value = []

  try {
    const response = await api.post('/relatorios/veiculos/data', {
      modelo: filters.modelo,
      data_inicial: filters.data_inicial,
      data_final: filters.data_final,
      tipo_veiculo: filters.tipo_veiculo,
      placa: filters.placa,
      recurso: filters.recurso,
      local: filters.local,
      status: filters.status
    })
    dados.value = response.data
  } catch (err: any) {
    showError(err.response?.data?.error || 'Erro ao buscar dados do relatorio')
  } finally {
    loading.value = false
  }
}

function buildParams() {
  const params = new URLSearchParams({
    modelo: filters.modelo,
    data_inicial: filters.data_inicial,
    data_final: filters.data_final
  })
  filters.tipo_veiculo.forEach(v => params.append('tipo_veiculo[]', String(v)))
  filters.placa.forEach(v => params.append('placa[]', String(v)))
  filters.recurso.forEach(v => params.append('recurso[]', String(v)))
  filters.local.forEach(v => params.append('local[]', String(v)))
  filters.status.forEach(v => params.append('status[]', String(v)))
  return params.toString()
}

function exportExcel() {
  exporting.value = true
  window.location.href = `/relatorios/veiculos/excel?${buildParams()}`
  setTimeout(() => { exporting.value = false }, 2000)
}

function exportPdf() {
  exporting.value = true
  window.location.href = `/relatorios/veiculos/pdf?${buildParams()}`
  setTimeout(() => { exporting.value = false }, 2000)
}

function limparFiltros() {
  filters.tipo_veiculo = []
  filters.placa = []
  filters.recurso = []
  filters.local = []
  filters.data_inicial = ''
  filters.data_final = ''
  filters.modelo = 'RG'
  filters.status = []
  dados.value = []
  searched.value = false
}

// Limpa dados ao mudar o modelo para forcar nova pesquisa
watch(() => filters.modelo, (newValue, oldValue) => {
  if (oldValue !== undefined) {
    dados.value = []
    searched.value = false
  }
})
</script>
