<template>
  <Head title="Custos Previstos" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Custos Previstos</h1>
      </div>

      <div class="bg-white rounded-lg shadow p-4">
        <p class="text-gray-500">
          Os custos previstos sao gerenciados dentro de cada processo de importacao.
          Acesse um processo para adicionar ou editar custos previstos.
        </p>
        <Link
          href="/processos_importacao"
          class="mt-4 inline-flex items-center text-brand-primary hover:underline"
        >
          Ir para Processos de Importacao &rarr;
        </Link>
      </div>

      <DataTable
        :data="custos"
        :columns="columns"
        row-key="id"
      >
        <template #cell-valorBrl="{ row }">
          R$ {{ formatNumber(row.valorBrl) }}
        </template>
      </DataTable>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3'
import AppLayout from '../../layouts/AppLayout.vue'
import { DataTable } from '../../components/DataTable'
import type { UserInfo } from '../../types/navigation'
import type { DataTableColumn } from '../../types/datatable'

interface CustoPrevisto {
  id: number
  processoNumero: string
  categoria: string
  descricao: string | null
  valorBrl: number
  dataPrevisao: string | null
  criadoPor: string
}

interface Props {
  usuario: UserInfo
  custos: CustoPrevisto[]
}

defineProps<Props>()

const columns: DataTableColumn[] = [
  { key: 'processoNumero', label: 'Processo' },
  { key: 'categoria', label: 'Categoria' },
  { key: 'descricao', label: 'Descricao' },
  { key: 'valorBrl', label: 'Valor (BRL)', align: 'right' },
  { key: 'dataPrevisao', label: 'Data Previsao' },
  { key: 'criadoPor', label: 'Criado Por' }
]

function formatNumber(value: number | null): string {
  if (value === null) return '-'
  return new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value)
}
</script>
