<template>
  <Head title="Reciclador por Evento" />

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
          <h1 class="text-2xl font-bold text-gray-900">Reciclador por Evento</h1>
        </div>
      </div>

      <!-- Filtros -->
      <div class="bg-white rounded-lg border border-gray-200 shadow-sm p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Filtros</h2>

        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <!-- Evento -->
          <ISelect
            v-model="filters.eventos"
            label="Evento"
            :options="eventos"
            mode="multiple"
            placeholder="Todos os eventos"
            searchable
          />

          <!-- Reciclador -->
          <ISelect
            v-model="filters.reciclador"
            label="Reciclador"
            :options="recicladores"
            placeholder="Todos os recicladores"
            searchable
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

        <!-- Botoes de Acao -->
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
          <TruckIcon class="mx-auto h-12 w-12 text-gray-400" />
          <h3 class="mt-2 text-sm font-semibold text-gray-900">Nenhum resultado encontrado</h3>
          <p class="mt-1 text-sm text-gray-500">Tente ajustar os filtros da pesquisa.</p>
        </div>

        <div v-else-if="!searched" class="text-center py-12">
          <MagnifyingGlassIcon class="mx-auto h-12 w-12 text-gray-400" />
          <h3 class="mt-2 text-sm font-semibold text-gray-900">Aplique os filtros</h3>
          <p class="mt-1 text-sm text-gray-500">Selecione os filtros e clique em "Pesquisar" para visualizar os dados.</p>
        </div>

        <div v-else class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reciclador</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Evento</th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Residuo</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Qtd Coletado (Kg)</th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">Valor (R$)</th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <tr v-for="(item, index) in dados" :key="index" class="hover:bg-gray-50">
                <td class="px-4 py-3 text-sm text-gray-900">{{ item.reciclador }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.evento }}</td>
                <td class="px-4 py-3 text-sm text-gray-500">{{ item.residuo }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.qtd_coletado }}</td>
                <td class="px-4 py-3 text-sm text-gray-900 text-right font-medium">{{ item.valor }}</td>
              </tr>
            </tbody>
            <tfoot class="bg-gray-100">
              <tr>
                <td colspan="3" class="px-4 py-3 text-sm font-bold text-gray-900">Total</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.qtd_coletado }}</td>
                <td class="px-4 py-3 text-sm font-bold text-gray-900 text-right">{{ totais.valor }}</td>
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
import { ref, reactive, computed } from 'vue'
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
  eventos: SelectOption[]
  recicladores: SelectOption[]
  statusOptions: SelectOption[]
}

interface DadoItem {
  reciclador: string
  evento: string
  residuo: string
  qtd_coletado: string
  valor: string
  qtd_coletado_raw: number
  valor_raw: number
}

interface Totais {
  qtd_coletado: string
  valor: string
}

const props = defineProps<Props>()
const { error: showError } = useNotifications()

const loading = ref(false)
const exporting = ref(false)
const searched = ref(false)
const dados = ref<DadoItem[]>([])
const totais = ref<Totais>({ qtd_coletado: '0,00', valor: '0,00' })

const filters = reactive({
  eventos: [] as (string | number)[],
  reciclador: null as string | number | null,
  data_inicial: '',
  data_final: '',
  status: '-X' as string | number
})

const hasData = computed(() => dados.value.length > 0)

async function buscar() {
  if (!filters.data_inicial && !filters.data_final && filters.eventos.length === 0) {
    showError('Informe um evento ou um periodo de datas antes de pesquisar')
    return
  }

  loading.value = true
  searched.value = true
  dados.value = []

  try {
    const response = await api.post('/relatorios/historico_reciclador_evento/data', {
      data_inicial: filters.data_inicial,
      data_final: filters.data_final,
      eventos: filters.eventos,
      reciclador: filters.reciclador,
      status: filters.status ? [filters.status] : ['-X']
    })
    dados.value = response.data.data
    totais.value = response.data.totais
  } catch (err: any) {
    showError(err.response?.data?.error || 'Erro ao buscar dados do relatorio')
  } finally {
    loading.value = false
  }
}

function exportExcel() {
  exporting.value = true
  const params = new URLSearchParams({
    data_inicial: filters.data_inicial,
    data_final: filters.data_final
  })
  if (filters.reciclador) {
    params.append('reciclador', String(filters.reciclador))
  }
  filters.eventos.forEach(e => params.append('eventos[]', String(e)))
  if (filters.status) {
    params.append('status[]', String(filters.status))
  }

  window.location.href = `/relatorios/historico_reciclador_evento/excel?${params.toString()}`
  setTimeout(() => { exporting.value = false }, 2000)
}

function exportPdf() {
  exporting.value = true
  const params = new URLSearchParams({
    data_inicial: filters.data_inicial,
    data_final: filters.data_final
  })
  if (filters.reciclador) {
    params.append('reciclador', String(filters.reciclador))
  }
  filters.eventos.forEach(e => params.append('eventos[]', String(e)))
  if (filters.status) {
    params.append('status[]', String(filters.status))
  }

  window.location.href = `/relatorios/historico_reciclador_evento/pdf?${params.toString()}`
  setTimeout(() => { exporting.value = false }, 2000)
}

function limparFiltros() {
  filters.eventos = []
  filters.reciclador = null
  filters.data_inicial = ''
  filters.data_final = ''
  filters.status = '-X'
  dados.value = []
  totais.value = { qtd_coletado: '0,00', valor: '0,00' }
  searched.value = false
}
</script>
