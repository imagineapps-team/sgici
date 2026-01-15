<template>
  <Head title="Unidades de Medida" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Unidades de Medida</h1>
        <Link
          href="/unidade_medidas/new"
          class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <PlusIcon class="h-5 w-5" />
          Nova Unidade
        </Link>
      </div>

      <!-- Tabela -->
      <DataTable
        :data="unidadeMedidas"
        :columns="columns"
        row-key="id"
        :default-actions="{ edit: true, delete: true }"
        :filters="tableFilters"
        :pagination="pagination"
        :loading="loading"
        @edit="handleEdit"
        @delete="handleDelete"
        @filter="handleFilter"
        @page-change="handlePageChange"
        @per-page-change="handlePerPageChange"
      />
    </div>

    <!-- Modal de confirmacao -->
    <ConfirmationModal
      v-model="confirmModalOpen"
      title="Remover Unidade de Medida"
      message="Tem certeza que deseja remover esta unidade de medida?"
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

interface UnidadeMedida {
  id: number
  nome: string
  sigla: string
}

interface Props {
  usuario: UserInfo
  unidadeMedidas: UnidadeMedida[]
  pagination: PaginationConfig
  filters: {
    nome?: string
  }
}

const props = defineProps<Props>()

const loading = ref(false)
const confirmModalOpen = ref(false)
const unidadeToDelete = ref<UnidadeMedida | null>(null)

const columns: DataTableColumn<UnidadeMedida>[] = [
  { key: 'id', label: 'ID', sortable: true, width: 'w-20' },
  { key: 'nome', label: 'Nome', sortable: true },
  { key: 'sigla', label: 'Sigla', sortable: true, width: 'w-32' }
]

const tableFilters = computed<DataTableFilter<UnidadeMedida>[]>(() => [
  {
    key: 'nome',
    label: 'Nome',
    type: 'text',
    placeholder: 'Buscar por nome...',
    defaultValue: props.filters.nome || null
  }
])

function handleEdit(unidade: UnidadeMedida) {
  router.visit(`/unidade_medidas/${unidade.id}/edit`)
}

function handleDelete(unidade: UnidadeMedida) {
  unidadeToDelete.value = unidade
  confirmModalOpen.value = true
}

function confirmDelete() {
  if (!unidadeToDelete.value) return

  router.delete(`/unidade_medidas/${unidadeToDelete.value.id}`, {
    onStart: () => { loading.value = true },
    onFinish: () => {
      loading.value = false
      confirmModalOpen.value = false
      unidadeToDelete.value = null
    }
  })
}

function handleFilter(filters: Record<string, unknown>) {
  loading.value = true
  router.get('/unidade_medidas', {
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
  router.get('/unidade_medidas', {
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
  router.get('/unidade_medidas', {
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
