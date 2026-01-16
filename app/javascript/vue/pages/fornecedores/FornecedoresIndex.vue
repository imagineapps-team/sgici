<template>
  <Head title="Fornecedores" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Fornecedores</h1>
        <Link
          href="/fornecedores/new"
          class="inline-flex items-center px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark"
        >
          Novo Fornecedor
        </Link>
      </div>

      <DataTable
        :data="fornecedores"
        :columns="columns"
        row-key="id"
        :default-actions="{ edit: true, delete: true }"
        @edit="handleEdit"
        @delete="handleDelete"
      >
        <template #cell-ativoLabel="{ row }">
          <span
            :class="[
              'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium',
              row.ativo ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
            ]"
          >
            {{ row.ativoLabel }}
          </span>
        </template>
      </DataTable>

      <ConfirmationModal
        v-model="confirmDelete"
        title="Excluir Fornecedor"
        :message="`Tem certeza que deseja excluir o fornecedor ${selectedFornecedor?.nome}?`"
        confirm-text="Excluir"
        type="danger"
        @confirm="confirmDeleteFornecedor"
      />
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { Head, Link, router } from '@inertiajs/vue3'
import AppLayout from '../../layouts/AppLayout.vue'
import { DataTable } from '../../components/DataTable'
import ConfirmationModal from '../../components/ConfirmationModal/ConfirmationModal.vue'
import type { UserInfo } from '../../types/navigation'
import type { DataTableColumn } from '../../types/datatable'

interface Fornecedor {
  id: number
  nome: string
  nomeFantasia: string | null
  cnpj: string | null
  pais: string | null
  cidade: string | null
  email: string | null
  telefone: string | null
  ativo: boolean
  ativoLabel: string
  totalProcessos: number
}

interface Props {
  usuario: UserInfo
  fornecedores: Fornecedor[]
}

defineProps<Props>()

const columns: DataTableColumn[] = [
  { key: 'nome', label: 'Nome', sortable: true },
  { key: 'cnpj', label: 'CNPJ' },
  { key: 'pais', label: 'Pais' },
  { key: 'cidade', label: 'Cidade' },
  { key: 'email', label: 'Email' },
  { key: 'totalProcessos', label: 'Processos', align: 'center' },
  { key: 'ativoLabel', label: 'Status' }
]

const confirmDelete = ref(false)
const selectedFornecedor = ref<Fornecedor | null>(null)

function handleEdit(fornecedor: Fornecedor) {
  router.visit(`/fornecedores/${fornecedor.id}/edit`)
}

function handleDelete(fornecedor: Fornecedor) {
  selectedFornecedor.value = fornecedor
  confirmDelete.value = true
}

function confirmDeleteFornecedor() {
  if (selectedFornecedor.value) {
    router.delete(`/fornecedores/${selectedFornecedor.value.id}`)
  }
  confirmDelete.value = false
}
</script>
