<template>
  <Head title="Prestadores de Servico" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Prestadores de Servico</h1>
        <Link
          href="/prestadores_servico/new"
          class="inline-flex items-center px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark"
        >
          Novo Prestador
        </Link>
      </div>

      <DataTable
        :data="prestadores"
        :columns="columns"
        row-key="id"
        :default-actions="{ edit: true, delete: true }"
        @edit="handleEdit"
        @delete="handleDelete"
      >
        <template #cell-tipoLabel="{ row }">
          <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
            {{ row.tipoLabel }}
          </span>
        </template>
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
        title="Excluir Prestador"
        :message="`Tem certeza que deseja excluir o prestador ${selectedPrestador?.nome}?`"
        confirm-text="Excluir"
        type="danger"
        @confirm="confirmDeletePrestador"
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

interface Prestador {
  id: number
  nome: string
  tipo: string
  tipoLabel: string
  cnpj: string | null
  cidade: string | null
  email: string | null
  ativo: boolean
  ativoLabel: string
}

interface Props {
  usuario: UserInfo
  prestadores: Prestador[]
}

defineProps<Props>()

const columns: DataTableColumn[] = [
  { key: 'nome', label: 'Nome', sortable: true },
  { key: 'tipoLabel', label: 'Tipo' },
  { key: 'cnpj', label: 'CNPJ' },
  { key: 'cidade', label: 'Cidade' },
  { key: 'email', label: 'Email' },
  { key: 'ativoLabel', label: 'Status' }
]

const confirmDelete = ref(false)
const selectedPrestador = ref<Prestador | null>(null)

function handleEdit(prestador: Prestador) {
  router.visit(`/prestadores_servico/${prestador.id}/edit`)
}

function handleDelete(prestador: Prestador) {
  selectedPrestador.value = prestador
  confirmDelete.value = true
}

function confirmDeletePrestador() {
  if (selectedPrestador.value) {
    router.delete(`/prestadores_servico/${selectedPrestador.value.id}`)
  }
  confirmDelete.value = false
}
</script>
