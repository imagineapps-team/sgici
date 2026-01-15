<template>
  <Head :title="`Permissões - ${perfil.nome}`" />

  <AppLayout :usuario="usuario">
    <div class="max-w-4xl mx-auto">
      <!-- Header -->
      <div class="mb-6">
        <Link
          href="/permissoes_menu"
          class="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700 mb-2"
        >
          <ArrowLeftIcon class="h-4 w-4" />
          Voltar para lista
        </Link>
        <h1 class="text-2xl font-bold text-gray-900">
          Permissões de Menu - {{ perfil.nome }}
        </h1>
      </div>

      <!-- Form -->
      <form @submit.prevent="handleSubmit" class="bg-white rounded-lg shadow">
        <!-- Toolbar -->
        <div class="px-6 py-4 border-b border-gray-200 flex items-center justify-between">
          <div class="flex items-center gap-4">
            <button
              type="button"
              @click="expandAll"
              class="inline-flex items-center gap-1 text-sm text-gray-600 hover:text-gray-900"
            >
              <ChevronDownIcon class="h-4 w-4" />
              Expandir Todos
            </button>
            <button
              type="button"
              @click="collapseAll"
              class="inline-flex items-center gap-1 text-sm text-gray-600 hover:text-gray-900"
            >
              <ChevronUpIcon class="h-4 w-4" />
              Colapsar Todos
            </button>
          </div>
          <div class="text-sm text-gray-500">
            {{ selectedCount }} menus selecionados
          </div>
        </div>

        <!-- Menu Tree -->
        <div class="p-6 space-y-2 max-h-[60vh] overflow-y-auto">
          <MenuTreeItem
            v-for="menu in menus"
            :key="menu.id"
            :menu="menu"
            :selected-ids="selectedMenuIds"
            :expanded-ids="expandedIds"
            @toggle-select="toggleMenuSelect"
            @toggle-expand="toggleExpand"
          />
        </div>

        <!-- Actions -->
        <div class="px-6 py-4 border-t border-gray-200 flex justify-end gap-3">
          <Link
            href="/permissoes_menu"
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
          >
            Cancelar
          </Link>
          <button
            type="submit"
            :disabled="processing"
            class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ processing ? 'Salvando...' : 'Salvar' }}
          </button>
        </div>
      </form>
    </div>
  </AppLayout>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { Head, Link, router } from '@inertiajs/vue3'
import {
  ArrowLeftIcon,
  ChevronDownIcon,
  ChevronUpIcon
} from '@heroicons/vue/24/outline'
import AppLayout from '../../layouts/AppLayout.vue'
import MenuTreeItem from './MenuTreeItem.vue'
import type { UserInfo } from '../../types/navigation'

interface MenuItem {
  id: number
  nome: string
  controller: string | null
  action: string | null
  ordem: number
  children: MenuItem[]
}

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
  perfil: PerfilItem
  menus: MenuItem[]
  menuIdsPermitidos: number[]
}

const props = defineProps<Props>()

const processing = ref(false)
const selectedMenuIds = ref<Set<number>>(new Set(props.menuIdsPermitidos))
const expandedIds = ref<Set<number>>(new Set())

const selectedCount = computed(() => selectedMenuIds.value.size)

function getAllMenuIds(menus: MenuItem[]): number[] {
  const ids: number[] = []
  for (const menu of menus) {
    ids.push(menu.id)
    if (menu.children?.length) {
      ids.push(...getAllMenuIds(menu.children))
    }
  }
  return ids
}

function expandAll() {
  const allIds = getAllMenuIds(props.menus)
  expandedIds.value = new Set(allIds)
}

function collapseAll() {
  expandedIds.value = new Set()
}

function toggleExpand(menuId: number) {
  if (expandedIds.value.has(menuId)) {
    expandedIds.value.delete(menuId)
  } else {
    expandedIds.value.add(menuId)
  }
  // Trigger reactivity
  expandedIds.value = new Set(expandedIds.value)
}

function toggleMenuSelect(menuId: number, menu: MenuItem) {
  const isCurrentlySelected = selectedMenuIds.value.has(menuId)

  if (isCurrentlySelected) {
    // Unselect this menu and all children
    selectedMenuIds.value.delete(menuId)
    unselectChildren(menu)
  } else {
    // Select this menu
    selectedMenuIds.value.add(menuId)
  }

  // Trigger reactivity
  selectedMenuIds.value = new Set(selectedMenuIds.value)
}

function unselectChildren(menu: MenuItem) {
  if (menu.children?.length) {
    for (const child of menu.children) {
      selectedMenuIds.value.delete(child.id)
      unselectChildren(child)
    }
  }
}

function handleSubmit() {
  processing.value = true

  router.put(`/permissoes_menu/${props.perfil.id}`, {
    menu_ids: Array.from(selectedMenuIds.value)
  }, {
    onFinish: () => { processing.value = false }
  })
}
</script>
