<template>
  <Head title="Eventos Logisticos" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Eventos Logisticos</h1>
      </div>

      <div class="bg-white rounded-lg shadow p-4">
        <p class="text-gray-500">
          Os eventos logisticos sao registrados automaticamente durante o rastreamento
          ou manualmente dentro de cada processo de importacao.
        </p>
        <Link
          href="/processos_importacao"
          class="mt-4 inline-flex items-center text-brand-primary hover:underline"
        >
          Ir para Processos de Importacao &rarr;
        </Link>
      </div>

      <DataTable
        :data="eventos"
        :columns="columns"
        row-key="id"
      >
        <template #cell-tipoLabel="{ row }">
          <span
            :class="[
              'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium',
              tipoClass(row.tipo)
            ]"
          >
            {{ row.tipoLabel }}
          </span>
        </template>
        <template #cell-diasAtraso="{ row }">
          <span v-if="row.diasAtraso && row.diasAtraso > 0" class="text-red-600 font-medium">
            {{ row.diasAtraso }} dias
          </span>
          <span v-else class="text-gray-400">-</span>
        </template>
      </DataTable>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3'
import AppLayout from '../../layouts/AppLayout.vue'
import { DataTable } from '../../components/DataTable'
import { formatDate } from '../../utils'
import type { UserInfo } from '../../types/navigation'
import type { DataTableColumn } from '../../types/datatable'

interface EventoLogistico {
  id: number
  processoNumero: string
  tipo: string
  tipoLabel: string
  dataEvento: string
  local: string | null
  descricao: string | null
  diasAtraso: number | null
  criadoPor: string
}

interface Props {
  usuario: UserInfo
  eventos: EventoLogistico[]
}

defineProps<Props>()

const columns: DataTableColumn[] = [
  { key: 'processoNumero', label: 'Processo' },
  { key: 'tipoLabel', label: 'Tipo' },
  { key: 'dataEvento', label: 'Data', formatter: (v) => formatDate(v) },
  { key: 'local', label: 'Local' },
  { key: 'descricao', label: 'Descricao' },
  { key: 'diasAtraso', label: 'Atraso' },
  { key: 'criadoPor', label: 'Registrado Por' }
]

function tipoClass(tipo: string): string {
  const classes: Record<string, string> = {
    embarque: 'bg-blue-100 text-blue-800',
    transito: 'bg-yellow-100 text-yellow-800',
    chegada_porto: 'bg-purple-100 text-purple-800',
    desembaraco: 'bg-indigo-100 text-indigo-800',
    liberacao: 'bg-green-100 text-green-800',
    entrega: 'bg-green-200 text-green-900',
    atraso: 'bg-red-100 text-red-800',
    avaria: 'bg-red-200 text-red-900'
  }
  return classes[tipo] || 'bg-gray-100 text-gray-800'
}
</script>
