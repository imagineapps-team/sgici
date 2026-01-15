<template>
  <Head title="Bairros" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Bairros</h1>
        <Link
          href="/bairros/new"
          class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <PlusIcon class="h-5 w-5" />
          Novo Bairro
        </Link>
      </div>

      <!-- Tabela -->
      <DataTable
        :data="bairros"
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
      >
        <template #cell-localizacao="{ row }">
          {{ row.cidade }} - {{ row.uf }}
        </template>
      </DataTable>
    </div>

    <!-- Modal de confirmacao -->
    <ConfirmationModal
      v-model="confirmModalOpen"
      title="Remover Bairro"
      message="Tem certeza que deseja remover este bairro?"
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

interface Bairro {
  id: number
  nome: string
  cidade: string | null
  uf: string | null
}

interface UfItem {
  id: number
  nome: string
  sigla: string
}

interface Props {
  usuario: UserInfo
  bairros: Bairro[]
  ufs: UfItem[]
  pagination: PaginationConfig
  filters: {
    nome?: string
    uf_id?: string
    cidade_id?: string
  }
}

const props = defineProps<Props>()

const loading = ref(false)
const confirmModalOpen = ref(false)
const bairroToDelete = ref<Bairro | null>(null)

const columns: DataTableColumn<Bairro>[] = [
  { key: 'id', label: 'ID', sortable: true, width: 'w-20' },
  { key: 'nome', label: 'Nome', sortable: true },
  { key: 'localizacao', label: 'Cidade/UF', slot: 'cell-localizacao' }
]

const ufOptions = computed(() =>
  props.ufs.map(u => ({ value: String(u.id), label: `${u.sigla} - ${u.nome}` }))
)

const tableFilters = computed<DataTableFilter<Bairro>[]>(() => [
  {
    key: 'nome',
    label: 'Nome',
    type: 'text',
    placeholder: 'Buscar por nome...',
    defaultValue: props.filters.nome || null
  },
  {
    key: 'uf_id',
    label: 'UF',
    type: 'select',
    options: ufOptions.value,
    placeholder: 'Todas as UFs',
    defaultValue: props.filters.uf_id || null
  }
])

function handleEdit(bairro: Bairro) {
  router.visit(`/bairros/${bairro.id}/edit`)
}

function handleDelete(bairro: Bairro) {
  bairroToDelete.value = bairro
  confirmModalOpen.value = true
}

function confirmDelete() {
  if (!bairroToDelete.value) return

  router.delete(`/bairros/${bairroToDelete.value.id}`, {
    onStart: () => { loading.value = true },
    onFinish: () => {
      loading.value = false
      confirmModalOpen.value = false
      bairroToDelete.value = null
    }
  })
}

function handleFilter(filters: Record<string, unknown>) {
  loading.value = true
  router.get('/bairros', {
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
  router.get('/bairros', {
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
  router.get('/bairros', {
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
