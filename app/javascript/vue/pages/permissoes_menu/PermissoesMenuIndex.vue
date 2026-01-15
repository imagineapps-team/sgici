<template>
  <Head title="Controle de Acesso - Menus" />

  <AppLayout :usuario="usuario">
    <div class="space-y-6">
      <!-- Header -->
      <div class="flex items-center justify-between">
        <h1 class="text-2xl font-bold text-gray-900">Controle de Acesso - Menus</h1>
      </div>

      <!-- Info Card -->
      <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
        <div class="flex">
          <InformationCircleIcon class="h-5 w-5 text-blue-400 mt-0.5" />
          <div class="ml-3">
            <p class="text-sm text-blue-700">
              Gerencie quais menus cada perfil pode acessar. Perfis com acesso total
              (Administrador, Diretoria, Gerente) possuem acesso a todos os menus automaticamente.
            </p>
          </div>
        </div>
      </div>

      <!-- Tabela de Perfis -->
      <div class="bg-white shadow rounded-lg overflow-hidden">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Perfil
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Status
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Menus Permitidos
              </th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Acesso
              </th>
              <th scope="col" class="relative px-6 py-3">
                <span class="sr-only">Ações</span>
              </th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            <tr v-for="perfil in perfis" :key="perfil.id" class="hover:bg-gray-50">
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="text-sm font-medium text-gray-900">{{ perfil.nome }}</div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  :class="[
                    'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium',
                    perfil.status === 'A' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                  ]"
                >
                  {{ perfil.statusLabel }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="text-sm text-gray-500">
                  {{ perfil.acessoTotal ? 'Todos' : perfil.menusCount }}
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span
                  v-if="perfil.acessoTotal"
                  class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800"
                >
                  <ShieldCheckIcon class="h-3.5 w-3.5 mr-1" />
                  Total
                </span>
                <span
                  v-else
                  class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800"
                >
                  Restrito
                </span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <Link
                  v-if="!perfil.acessoTotal"
                  :href="`/permissoes_menu/${perfil.id}/edit`"
                  class="inline-flex items-center gap-1 text-blue-600 hover:text-blue-900"
                >
                  <Cog6ToothIcon class="h-4 w-4" />
                  Gerenciar Permissões
                </Link>
                <span v-else class="text-gray-400 text-sm">
                  Acesso total automático
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { Head, Link } from '@inertiajs/vue3'
import {
  InformationCircleIcon,
  ShieldCheckIcon,
  Cog6ToothIcon
} from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import type { UserInfo } from '../../types/navigation'

interface PerfilItem {
  id: number
  nome: string
  status: string
  statusLabel: string
  acessoTotal: boolean
  menusCount: number
}

interface Props {
  usuario: UserInfo
  perfis: PerfilItem[]
}

defineProps<Props>()
</script>
