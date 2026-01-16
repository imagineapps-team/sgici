<template>
  <Head title="Custos Reais" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Custos Reais</h1>
      </div>

      <div class="bg-white rounded-lg shadow p-4">
        <p class="text-gray-500">
          Os custos reais sao gerenciados dentro de cada processo de importacao.
          Acesse um processo para adicionar ou editar custos reais.
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
        <template #cell-statusLabel="{ row }">
          <span
            :class="[
              'inline-flex items-center px-2 py-0.5 rounded text-xs font-medium',
              statusClass(row.statusPagamento)
            ]"
          >
            {{ row.statusLabel }}
          </span>
        </template>
        <template #cell-desvioPercentual="{ row }">
          <span v-if="row.desvioPercentual" :class="desvioClass(row.desvioPercentual)">
            {{ row.desvioPercentual > 0 ? '+' : '' }}{{ row.desvioPercentual.toFixed(1) }}%
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
import type { UserInfo } from '../../types/navigation'
import type { DataTableColumn } from '../../types/datatable'

interface CustoReal {
  id: number
  processoNumero: string
  categoria: string
  prestador: string | null
  valorBrl: number
  statusPagamento: string
  statusLabel: string
  desvioPercentual: number | null
  dataVencimento: string | null
}

interface Props {
  usuario: UserInfo
  custos: CustoReal[]
}

defineProps<Props>()

const columns: DataTableColumn[] = [
  { key: 'processoNumero', label: 'Processo' },
  { key: 'categoria', label: 'Categoria' },
  { key: 'prestador', label: 'Prestador' },
  { key: 'valorBrl', label: 'Valor (BRL)', align: 'right' },
  { key: 'statusLabel', label: 'Status' },
  { key: 'desvioPercentual', label: 'Desvio', align: 'right' },
  { key: 'dataVencimento', label: 'Vencimento' }
]

function formatNumber(value: number | null): string {
  if (value === null) return '-'
  return new Intl.NumberFormat('pt-BR', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value)
}

function statusClass(status: string): string {
  const classes: Record<string, string> = {
    pendente: 'bg-yellow-100 text-yellow-800',
    aprovado: 'bg-blue-100 text-blue-800',
    pago: 'bg-green-100 text-green-800',
    cancelado: 'bg-red-100 text-red-800'
  }
  return classes[status] || 'bg-gray-100 text-gray-800'
}

function desvioClass(desvio: number): string {
  if (desvio > 10) return 'text-red-600 font-medium'
  if (desvio > 5) return 'text-yellow-600'
  if (desvio < -5) return 'text-green-600'
  return 'text-gray-600'
}
</script>
