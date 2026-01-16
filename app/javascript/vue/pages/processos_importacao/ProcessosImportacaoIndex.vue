<template>
  <Head title="Processos de Importacao" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Processos de Importacao</h1>
        <Link
          href="/processos_importacao/new"
          class="inline-flex items-center gap-2 px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark transition-colors"
        >
          <PlusIcon class="h-5 w-5" />
          Novo Processo
        </Link>
      </div>

      <!-- Tabela -->
      <DataTable
        :data="processos"
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

        <!-- Fornecedor -->
        <template #cell-fornecedor="{ row }">
          <div class="text-sm">
            <div class="font-medium text-gray-900">{{ row.fornecedor.nome }}</div>
            <div class="text-gray-500">{{ row.fornecedor.pais }}</div>
          </div>
        </template>

        <!-- Valor FOB -->
        <template #cell-valorFob="{ row }">
          <div v-if="row.valorFob" class="text-sm font-medium text-gray-900">
            {{ row.moeda }} {{ formatNumber(row.valorFob) }}
          </div>
          <span v-else class="text-gray-400">-</span>
        </template>

        <!-- Chegada Prevista -->
        <template #cell-dataChegadaPrevista="{ row }">
          <div v-if="row.dataChegadaPrevista" class="text-sm text-gray-900">
            {{ formatDate(row.dataChegadaPrevista) }}
          </div>
          <span v-else class="text-gray-400">-</span>
        </template>

        <!-- Situacao (dias ate chegada ou atraso) -->
        <template #cell-situacao="{ row }">
          <div class="text-center">
            <span
              v-if="row.situacaoDias !== null && row.situacaoDias !== undefined"
              :class="[
                'inline-flex items-center justify-center w-8 h-8 rounded-full text-sm font-bold',
                row.situacaoDias < 0 ? 'bg-red-100 text-red-700' : 'bg-green-100 text-green-700'
              ]"
              :title="row.situacaoDias < 0 ? `${Math.abs(row.situacaoDias)} dias de atraso` : `${row.situacaoDias} dias para chegada`"
            >
              {{ Math.abs(row.situacaoDias) }}
            </span>
            <span v-else class="text-gray-400">-</span>
          </div>
        </template>

        <!-- Desvio -->
        <template #cell-desvioPercentual="{ row }">
          <div v-if="row.desvioPercentual != null" class="text-sm font-medium" :class="desvioClass(row.desvioPercentual)">
            {{ Number(row.desvioPercentual) > 0 ? '+' : '' }}{{ Number(row.desvioPercentual).toFixed(1) }}%
          </div>
          <span v-else class="text-gray-400">-</span>
        </template>
      </DataTable>
    </div>

    <!-- Modal de confirmacao -->
    <ConfirmationModal
      v-model="confirmModalOpen"
      title="Remover Processo"
      message="Tem certeza que deseja remover este processo de importacao?"
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
import type { ProcessoImportacaoList, SelectOption, ProcessoStatus } from '../../types/importacao'
import { formatDate } from '../../utils'

interface Props {
  usuario: UserInfo
  processos: ProcessoImportacaoList[]
  statusOptions: SelectOption[]
  modalOptions: SelectOption[]
  fornecedoresOptions: SelectOption[]
  pagination: PaginationConfig
  filters: {
    status?: string
    modal?: string
    fornecedorId?: number
    search?: string
  }
}

const props = defineProps<Props>()

const loading = ref(false)
const confirmModalOpen = ref(false)
const processoToDelete = ref<ProcessoImportacaoList | null>(null)

const columns: DataTableColumn<ProcessoImportacaoList>[] = [
  { key: 'numero', label: 'Numero', sortable: true, width: 'w-32' },
  { key: 'statusLabel', label: 'Status', sortable: true, width: 'w-32', slot: 'cell-statusLabel' },
  { key: 'fornecedor', label: 'Fornecedor', sortable: false, slot: 'cell-fornecedor' },
  { key: 'modalLabel', label: 'Modal', sortable: true, width: 'w-24' },
  { key: 'valorFob', label: 'Valor FOB', sortable: true, width: 'w-32', slot: 'cell-valorFob' },
  { key: 'dataChegadaPrevista', label: 'Chegada Prevista', sortable: true, width: 'w-32', slot: 'cell-dataChegadaPrevista' },
  { key: 'situacao', label: 'Situacao', sortable: true, width: 'w-24', slot: 'cell-situacao' },
  { key: 'desvioPercentual', label: 'Desvio', sortable: true, width: 'w-24', slot: 'cell-desvioPercentual' }
]

function statusClass(status: ProcessoStatus): string {
  switch (status) {
    case 'planejado':
      return 'bg-gray-100 text-gray-800'
    case 'aprovado':
      return 'bg-blue-100 text-blue-800'
    case 'em_transito':
      return 'bg-yellow-100 text-yellow-800'
    case 'desembaracado':
      return 'bg-purple-100 text-purple-800'
    case 'finalizado':
      return 'bg-green-100 text-green-800'
    case 'cancelado':
      return 'bg-red-100 text-red-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

function desvioClass(desvio: number): string {
  if (desvio > 10) return 'text-red-600'
  if (desvio > 5) return 'text-yellow-600'
  if (desvio < -5) return 'text-green-600'
  return 'text-gray-600'
}

function formatNumber(value: number): string {
  return new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value)
}

const tableFilters = computed<DataTableFilter<ProcessoImportacaoList>[]>(() => [
  {
    key: 'search',
    label: 'Buscar',
    type: 'text',
    placeholder: 'Buscar por numero...',
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
    key: 'modal',
    label: 'Modal',
    type: 'select',
    options: props.modalOptions.map(m => ({ value: m.value as string, label: m.label })),
    placeholder: 'Todos os modais',
    defaultValue: props.filters.modal || null
  },
  {
    key: 'fornecedor_id',
    label: 'Fornecedor',
    type: 'select',
    options: props.fornecedoresOptions.map(f => ({ value: String(f.value), label: f.label })),
    placeholder: 'Todos os fornecedores',
    defaultValue: props.filters.fornecedorId ? String(props.filters.fornecedorId) : null
  }
])

function handleView(processo: ProcessoImportacaoList) {
  router.visit(`/processos_importacao/${processo.id}`)
}

function handleEdit(processo: ProcessoImportacaoList) {
  if (!processo.editavel) {
    return
  }
  router.visit(`/processos_importacao/${processo.id}/edit`)
}

function handleDelete(processo: ProcessoImportacaoList) {
  if (!processo.editavel) {
    return
  }
  processoToDelete.value = processo
  confirmModalOpen.value = true
}

function confirmDelete() {
  if (!processoToDelete.value) return

  router.delete(`/processos_importacao/${processoToDelete.value.id}`, {
    onStart: () => { loading.value = true },
    onFinish: () => {
      loading.value = false
      confirmModalOpen.value = false
      processoToDelete.value = null
    }
  })
}

function handleFilter(filters: Record<string, unknown>) {
  loading.value = true
  router.get('/processos_importacao', {
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
  router.get('/processos_importacao', {
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
  router.get('/processos_importacao', {
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
