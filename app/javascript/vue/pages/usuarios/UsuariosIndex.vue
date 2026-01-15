<template>
  <Head title="Usuários" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Cadastro de Usuários</h1>
        <Link
          href="/usuarios/new"
          class="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
        >
          <PlusIcon class="h-5 w-5" />
          Novo Usuário
        </Link>
      </div>

      <!-- Tabela -->
      <DataTable
        :data="usuarios"
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
      </DataTable>
    </div>

    <!-- Modal de confirmacao -->
    <ConfirmationModal
      v-model="confirmModalOpen"
      title="Remover Usuário"
      message="Tem certeza que deseja remover este usuário?"
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

interface UsuarioItem {
  id: number
  nome: string
  login: string
  perfil: string | null
  contexto: string | null
  status: string
  statusLabel: string
}

interface PerfilItem {
  id: number
  nome: string
}

interface StatusOption {
  value: string
  label: string
}

interface Props {
  usuario: UserInfo
  usuarios: UsuarioItem[]
  perfis: PerfilItem[]
  statusOptions: StatusOption[]
  pagination: PaginationConfig
  filters: {
    search?: string
    perfil_id?: string
    status?: string
  }
}

const props = defineProps<Props>()

const loading = ref(false)
const confirmModalOpen = ref(false)
const usuarioToDelete = ref<UsuarioItem | null>(null)

const columns: DataTableColumn<UsuarioItem>[] = [
  { key: 'id', label: 'ID', sortable: true, width: 'w-20' },
  { key: 'nome', label: 'Nome', sortable: true },
  { key: 'login', label: 'Login', sortable: true },
  { key: 'perfil', label: 'Perfil', sortable: true },
  { key: 'contexto', label: 'Contexto', sortable: true },
  { key: 'statusLabel', label: 'Status', sortable: true, width: 'w-24', slot: 'cell-statusLabel' }
]

function statusClass(status: string): string {
  switch (status) {
    case 'A':
      return 'bg-green-100 text-green-800'
    case 'I':
      return 'bg-red-100 text-red-800'
    default:
      return 'bg-gray-100 text-gray-800'
  }
}

const perfilOptions = computed(() =>
  props.perfis.map(p => ({ value: String(p.id), label: p.nome }))
)

const statusSelectOptions = computed(() =>
  props.statusOptions.map(s => ({ value: s.value, label: s.label }))
)

const tableFilters = computed<DataTableFilter<UsuarioItem>[]>(() => [
  {
    key: 'search',
    label: 'Buscar',
    type: 'text',
    placeholder: 'Buscar por nome ou login...',
    defaultValue: props.filters.search || null
  },
  {
    key: 'perfil_id',
    label: 'Perfil',
    type: 'select',
    options: perfilOptions.value,
    placeholder: 'Todos os perfis',
    defaultValue: props.filters.perfil_id || null
  },
  {
    key: 'status',
    label: 'Status',
    type: 'select',
    options: statusSelectOptions.value,
    placeholder: 'Todos os status',
    defaultValue: props.filters.status || null
  }
])

function handleEdit(usuario: UsuarioItem) {
  router.visit(`/usuarios/${usuario.id}/edit`)
}

function handleDelete(usuario: UsuarioItem) {
  usuarioToDelete.value = usuario
  confirmModalOpen.value = true
}

function confirmDelete() {
  if (!usuarioToDelete.value) return

  router.delete(`/usuarios/${usuarioToDelete.value.id}`, {
    onStart: () => { loading.value = true },
    onFinish: () => {
      loading.value = false
      confirmModalOpen.value = false
      usuarioToDelete.value = null
    }
  })
}

function handleFilter(filters: Record<string, unknown>) {
  loading.value = true
  router.get('/usuarios', {
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
  router.get('/usuarios', {
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
  router.get('/usuarios', {
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
