<template>
  <Head title="Ocorrencias" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Ocorrencias</h1>
        <Link
          href="/ocorrencias/new"
          class="inline-flex items-center gap-2 px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark transition-colors"
        >
          <PlusIcon class="h-5 w-5" />
          Nova Ocorrencia
        </Link>
      </div>

      <!-- KPIs -->
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Abertas</p>
          <p class="text-2xl font-bold text-yellow-600">{{ kpis.totalAbertas }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Em Analise</p>
          <p class="text-2xl font-bold text-blue-600">{{ kpis.totalEmAnalise }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Criticas Ativas</p>
          <p class="text-2xl font-bold text-red-600">{{ kpis.totalCriticas }}</p>
        </div>
        <div class="bg-white rounded-lg shadow p-4">
          <p class="text-sm text-gray-500">Impacto Financeiro</p>
          <p class="text-2xl font-bold text-gray-900">{{ formatMoney(kpis.impactoTotal) }}</p>
        </div>
      </div>

      <!-- Tabela -->
      <DataTable
        :data="ocorrencias"
        :columns="columns"
        row-key="id"
        :default-actions="{ view: true, edit: true, delete: true }"
        :filters="tableFilters"
        :pagination="pagination"
        :loading="loading"
        @view="handleView"
        @edit="handleEdit"
        @delete="handleDelete"
        @filter="handleFilter"
        @page-change="handlePageChange"
        @per-page-change="handlePerPageChange"
      >
        <!-- Status badge -->
        <template #cell-statusLabel="{ row }">
          <span
            :class="[
              'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
              statusClass(row.status)
            ]"
          >
            {{ row.statusLabel }}
          </span>
        </template>

        <!-- Gravidade badge -->
        <template #cell-gravidadeLabel="{ row }">
          <span
            :class="[
              'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
              gravidadeClass(row.gravidade)
            ]"
          >
            {{ row.gravidadeLabel }}
          </span>
        </template>

        <!-- Processo -->
        <template #cell-processo="{ row }">
          <Link
            :href="`/processos_importacao/${row.processo.id}`"
            class="text-brand-primary hover:underline"
          >
            {{ row.processo.numero }}
          </Link>
        </template>

        <!-- Impacto Financeiro -->
        <template #cell-impactoFinanceiro="{ row }">
          <span v-if="row.impactoFinanceiro" class="font-medium text-red-600">
            {{ formatMoney(row.impactoFinanceiro) }}
          </span>
          <span v-else class="text-gray-400">-</span>
        </template>

        <!-- Dias Aberto -->
        <template #cell-diasAberto="{ row }">
          <span v-if="row.diasAberto !== null" :class="diasAbertoClass(row.diasAberto)">
            {{ row.diasAberto }}d
          </span>
          <span v-else class="text-gray-400">-</span>
        </template>
      </DataTable>
    </div>

    <!-- Modal de confirmacao -->
    <ConfirmationModal
      v-model="confirmModalOpen"
      title="Remover Ocorrencia"
      message="Tem certeza que deseja remover esta ocorrencia?"
      confirm-text="Remover"
      type="danger"
      @confirm="confirmDelete"
    />
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Head, Link, router } from '@inertiajs/vue3'
import { PlusIcon } from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import { DataTable } from '../../components/DataTable'
import ConfirmationModal from '../../components/ConfirmationModal/ConfirmationModal.vue'
import type { DataTableColumn, DataTableFilter, PaginationConfig } from '../../types/datatable'
import type { UserInfo } from '../../types/navigation'
import type { SelectOption } from '../../components/ISelect/types'
import { formatMoney } from '../../utils'

interface OcorrenciaList {
  id: number
  titulo: string
  tipo: string
  tipoLabel: string
  gravidade: string
  gravidadeLabel: string
  status: string
  statusLabel: string
  processo: { id: number; numero: string }
  criadoPor: { id: number; nome: string }
  responsavel: { id: number; nome: string } | null
  dataOcorrencia: string
  impactoFinanceiro: number | null
  diasAberto: number | null
  createdAt: string
}

interface Kpis {
  totalAbertas: number
  totalEmAnalise: number
  totalCriticas: number
  impactoTotal: number
}

interface Props {
  usuario: UserInfo
  ocorrencias: OcorrenciaList[]
  statusOptions: SelectOption[]
  tipoOptions: SelectOption[]
  gravidadeOptions: SelectOption[]
  processosOptions: SelectOption[]
  pagination: PaginationConfig
  filters: {
    status?: string
    tipo?: string
    gravidade?: string
    processoId?: number
    search?: string
  }
  kpis: Kpis
}

const props = defineProps<Props>()

const loading = ref(false)
const confirmModalOpen = ref(false)
const ocorrenciaToDelete = ref<OcorrenciaList | null>(null)

const columns: DataTableColumn<OcorrenciaList>[] = [
  { key: 'titulo', label: 'Titulo', sortable: true },
  { key: 'processo', label: 'Processo', sortable: false, slot: 'cell-processo', width: 'w-32' },
  { key: 'tipoLabel', label: 'Tipo', sortable: true, width: 'w-32' },
  { key: 'gravidadeLabel', label: 'Gravidade', sortable: true, width: 'w-24', slot: 'cell-gravidadeLabel' },
  { key: 'statusLabel', label: 'Status', sortable: true, width: 'w-28', slot: 'cell-statusLabel' },
  { key: 'impactoFinanceiro', label: 'Impacto', sortable: true, width: 'w-28', slot: 'cell-impactoFinanceiro' },
  { key: 'diasAberto', label: 'Dias', sortable: true, width: 'w-20', slot: 'cell-diasAberto' }
]

function statusClass(status: string): string {
  switch (status) {
    case 'aberta': return 'bg-yellow-100 text-yellow-800'
    case 'em_analise': return 'bg-blue-100 text-blue-800'
    case 'resolvida': return 'bg-green-100 text-green-800'
    case 'cancelada': return 'bg-gray-100 text-gray-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}

function gravidadeClass(gravidade: string): string {
  switch (gravidade) {
    case 'baixa': return 'bg-green-100 text-green-800'
    case 'media': return 'bg-yellow-100 text-yellow-800'
    case 'alta': return 'bg-orange-100 text-orange-800'
    case 'critica': return 'bg-red-100 text-red-800'
    default: return 'bg-gray-100 text-gray-800'
  }
}

function diasAbertoClass(dias: number): string {
  if (dias > 14) return 'text-red-600 font-medium'
  if (dias > 7) return 'text-orange-600'
  if (dias > 3) return 'text-yellow-600'
  return 'text-green-600'
}

const tableFilters = computed<DataTableFilter<OcorrenciaList>[]>(() => [
  {
    key: 'search',
    label: 'Buscar',
    type: 'text',
    placeholder: 'Buscar por titulo...',
    defaultValue: props.filters.search || null
  },
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: props.statusOptions.map(s => ({ value: s.value as string, label: s.label })),
    placeholder: 'Todos os status',
    defaultValue: props.filters.status || null
  },
  {
    key: 'tipo',
    label: 'Tipo',
    type: 'select',
    options: props.tipoOptions.map(t => ({ value: t.value as string, label: t.label })),
    placeholder: 'Todos os tipos',
    defaultValue: props.filters.tipo || null
  },
  {
    key: 'gravidade',
    label: 'Gravidade',
    type: 'select',
    options: props.gravidadeOptions.map(g => ({ value: g.value as string, label: g.label })),
    placeholder: 'Todas',
    defaultValue: props.filters.gravidade || null
  }
])

function handleView(ocorrencia: OcorrenciaList) {
  router.visit(`/ocorrencias/${ocorrencia.id}`)
}

function handleEdit(ocorrencia: OcorrenciaList) {
  if (ocorrencia.status === 'resolvida' || ocorrencia.status === 'cancelada') {
    return
  }
  router.visit(`/ocorrencias/${ocorrencia.id}/edit`)
}

function handleDelete(ocorrencia: OcorrenciaList) {
  if (ocorrencia.status === 'resolvida') {
    return
  }
  ocorrenciaToDelete.value = ocorrencia
  confirmModalOpen.value = true
}

function confirmDelete() {
  if (!ocorrenciaToDelete.value) return

  router.delete(`/ocorrencias/${ocorrenciaToDelete.value.id}`, {
    onStart: () => { loading.value = true },
    onFinish: () => {
      loading.value = false
      confirmModalOpen.value = false
      ocorrenciaToDelete.value = null
    }
  })
}

function handleFilter(filters: Record<string, unknown>) {
  loading.value = true
  router.get('/ocorrencias', {
    ...filters,
    page: 1
  }, {
    preserveState: true,
    preserveScroll: true,
    onFinish: () => { loading.value = false }
  })
}

function handlePageChange(page: number) {
  loading.value = true
  router.get('/ocorrencias', {
    ...props.filters,
    page
  }, {
    preserveState: true,
    preserveScroll: true,
    onFinish: () => { loading.value = false }
  })
}

function handlePerPageChange(perPage: number) {
  loading.value = true
  router.get('/ocorrencias', {
    ...props.filters,
    per_page: perPage,
    page: 1
  }, {
    preserveState: true,
    preserveScroll: true,
    onFinish: () => { loading.value = false }
  })
}
</script>
