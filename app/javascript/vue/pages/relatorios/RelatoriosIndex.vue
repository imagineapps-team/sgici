<template>
  <Head title="Relatórios" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Relatórios</h1>
      </div>

      <!-- Grid de Relatórios -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <Link
          v-for="relatorio in relatorios"
          :key="relatorio.id"
          :href="relatorio.href"
          class="block p-6 bg-white rounded-lg border border-gray-200 shadow-sm hover:shadow-md hover:border-brand-primary transition-all"
        >
          <div class="flex items-center gap-4">
            <div class="flex-shrink-0 p-3 bg-brand-primary/10 rounded-lg">
              <component :is="getIcon(relatorio.id)" class="h-6 w-6 text-brand-primary" />
            </div>
            <div>
              <h3 class="text-lg font-semibold text-gray-900">{{ relatorio.nome }}</h3>
              <p class="mt-1 text-sm text-gray-500">{{ relatorio.descricao }}</p>
            </div>
          </div>
        </Link>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3'
import {
  DocumentChartBarIcon,
  CurrencyDollarIcon,
  BuildingOfficeIcon
} from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import type { UserInfo } from '../../types/navigation'

interface Relatorio {
  id: string
  nome: string
  descricao: string
  href: string
}

interface Props {
  usuario: UserInfo
  relatorios: Relatorio[]
}

defineProps<Props>()

const iconMap: Record<string, any> = {
  processos: DocumentChartBarIcon,
  custos: CurrencyDollarIcon,
  fornecedores: BuildingOfficeIcon
}

function getIcon(relatorioId: string) {
  return iconMap[relatorioId] || DocumentChartBarIcon
}
</script>
