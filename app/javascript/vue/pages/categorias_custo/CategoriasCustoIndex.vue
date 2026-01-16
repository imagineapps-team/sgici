<template>
  <Head title="Categorias de Custo" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Categorias de Custo</h1>
        <Link
          href="/categorias_custo/new"
          class="inline-flex items-center px-4 py-2 bg-brand-primary text-white rounded-lg hover:bg-brand-primary-dark"
        >
          Nova Categoria
        </Link>
      </div>

      <DataTable
        :data="categorias"
        :columns="columns"
        row-key="id"
        :default-actions="{ edit: true, delete: true }"
        @edit="handleEdit"
        @delete="handleDelete"
      >
        <template #cell-grupoLabel="{ row }">
          <span class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-purple-100 text-purple-800">
            {{ row.grupoLabel }}
          </span>
        </template>
        <template #cell-obrigatorio="{ row }">
          <span v-if="row.obrigatorio" class="text-green-600">Sim</span>
          <span v-else class="text-gray-400">Nao</span>
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
        title="Excluir Categoria"
        :message="`Tem certeza que deseja excluir a categoria ${selectedCategoria?.nome}?`"
        confirm-text="Excluir"
        type="danger"
        @confirm="confirmDeleteCategoria"
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

interface Categoria {
  id: number
  nome: string
  codigo: string | null
  tipo: string
  tipoLabel: string
  grupo: string
  grupoLabel: string
  ordem: number
  obrigatorio: boolean
  ativo: boolean
  ativoLabel: string
}

interface Props {
  usuario: UserInfo
  categorias: Categoria[]
}

defineProps<Props>()

const columns: DataTableColumn[] = [
  { key: 'ordem', label: '#', align: 'center' },
  { key: 'codigo', label: 'Codigo' },
  { key: 'nome', label: 'Nome', sortable: true },
  { key: 'tipoLabel', label: 'Tipo' },
  { key: 'grupoLabel', label: 'Grupo' },
  { key: 'obrigatorio', label: 'Obrigatorio', align: 'center' },
  { key: 'ativoLabel', label: 'Status' }
]

const confirmDelete = ref(false)
const selectedCategoria = ref<Categoria | null>(null)

function handleEdit(categoria: Categoria) {
  router.visit(`/categorias_custo/${categoria.id}/edit`)
}

function handleDelete(categoria: Categoria) {
  selectedCategoria.value = categoria
  confirmDelete.value = true
}

function confirmDeleteCategoria() {
  if (selectedCategoria.value) {
    router.delete(`/categorias_custo/${selectedCategoria.value.id}`)
  }
  confirmDelete.value = false
}
</script>
