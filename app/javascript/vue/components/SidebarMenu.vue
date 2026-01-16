<template>
  <aside
    class="fixed left-0 top-16 h-[calc(100vh-4rem)] w-64 bg-brand-primary-dark text-white overflow-y-auto transition-transform duration-300"
    :class="{ '-translate-x-full': !isOpen, 'translate-x-0': isOpen }"
  >
    <nav class="p-4">
      <template v-for="section in sections" :key="section.id">
        <div v-if="section.title" class="mt-6 mb-2 first:mt-0">
          <span class="text-xs font-semibold uppercase tracking-wider text-white/50">
            {{ section.title }}
          </span>
        </div>

        <ul class="space-y-1">
          <li v-for="item in section.items" :key="item.id">
            <template v-if="item.children?.length">
              <button
                type="button"
                class="w-full flex items-center justify-between gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors"
                :class="isParentActive(item)
                  ? 'bg-white/20 text-white'
                  : 'text-white/70 hover:bg-white/10 hover:text-white'"
                @click="toggleSubmenu(item.id)"
              >
                <div class="flex items-center gap-3">
                  <component :is="getIcon(item.icon)" class="h-5 w-5" />
                  <span>{{ item.label }}</span>
                </div>
                <ChevronDownIcon
                  class="h-4 w-4 transition-transform duration-200"
                  :class="{ 'rotate-180': expandedMenus.has(item.id) }"
                />
              </button>

              <ul
                v-show="expandedMenus.has(item.id)"
                class="ml-4 mt-1 space-y-1 border-l border-white/20 pl-4"
              >
                <li v-for="child in item.children" :key="child.id">
                  <a
                    :href="child.href"
                    class="flex items-center gap-3 px-3 py-2 rounded-md text-sm transition-colors cursor-pointer"
                    :class="isActive(child.href)
                      ? 'bg-white/20 text-white'
                      : 'text-white/60 hover:bg-white/10 hover:text-white'"
                    @click.prevent="navigateTo(child.href)"
                  >
                    {{ child.label }}
                  </a>
                </li>
              </ul>
            </template>

            <template v-else>
              <a
                :href="item.href"
                class="flex items-center gap-3 px-3 py-2 rounded-md text-sm font-medium transition-colors cursor-pointer"
                :class="isActive(item.href)
                  ? 'bg-white/20 text-white'
                  : 'text-white/70 hover:bg-white/10 hover:text-white'"
                @click.prevent="navigateTo(item.href)"
              >
                <component :is="getIcon(item.icon)" class="h-5 w-5" />
                <span>{{ item.label }}</span>
                <span
                  v-if="item.badge"
                  class="ml-auto bg-brand-accent text-xs font-medium px-2 py-0.5 rounded-full text-white"
                >
                  {{ item.badge }}
                </span>
              </a>
            </template>
          </li>
        </ul>
      </template>
    </nav>
  </aside>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, type Component } from 'vue'
import { usePage, router } from '@inertiajs/vue3'
import type { MenuSection, MenuItem } from '../types/navigation'
import {
  HomeIcon,
  UsersIcon,
  Cog6ToothIcon,
  DocumentIcon,
  ChartBarIcon,
  FolderIcon,
  CalendarIcon,
  UserIcon,
  ChevronDownIcon,
  BuildingOfficeIcon,
  TrashIcon,
  MapPinIcon,
  MegaphoneIcon,
  TruckIcon,
  LockClosedIcon
} from '@heroicons/vue/24/outline'

interface Props {
  sections: MenuSection[]
  isOpen: boolean
}

const props = defineProps<Props>()

const page = usePage()
const expandedMenus = ref<Set<string>>(new Set())

// Cachear currentPath para evitar re-renders desnecessarios
const currentPath = computed(() => page.url)

// Pre-calcular quais items estao ativos (evita recalculo no template)
const activeItems = computed(() => {
  const path = currentPath.value
  const active = new Set<string>()

  props.sections.forEach(section => {
    section.items.forEach(item => {
      if (checkActive(item.href, path)) {
        active.add(item.href)
      }
      item.children?.forEach(child => {
        if (checkActive(child.href, path)) {
          active.add(child.href)
        }
      })
    })
  })

  return active
})

function checkActive(href: string, path: string): boolean {
  if (href === '/') return path === '/'
  return path.startsWith(href)
}

const iconMap: Record<string, Component> = {
  home: HomeIcon,
  users: UsersIcon,
  settings: Cog6ToothIcon,
  document: DocumentIcon,
  chart: ChartBarIcon,
  folder: FolderIcon,
  calendar: CalendarIcon,
  userCog: Cog6ToothIcon,
  user: UserIcon,
  building: BuildingOfficeIcon,
  trash: TrashIcon,
  mapPin: MapPinIcon,
  megaphone: MegaphoneIcon,
  truck: TruckIcon,
  lockClosed: LockClosedIcon
}

function getIcon(name?: string): Component {
  return iconMap[name ?? ''] ?? DocumentIcon
}

function isActive(href: string): boolean {
  return activeItems.value.has(href)
}

function isParentActive(item: MenuItem): boolean {
  if (activeItems.value.has(item.href)) return true
  return item.children?.some(child => activeItems.value.has(child.href)) ?? false
}

function toggleSubmenu(id: string): void {
  if (expandedMenus.value.has(id)) {
    expandedMenus.value.delete(id)
  } else {
    expandedMenus.value.add(id)
  }
}

function navigateTo(href: string): void {
  router.visit(href)
}

onMounted(() => {
  // Expandir submenus que contem item ativo
  const path = page.url
  props.sections.forEach(section => {
    section.items.forEach(item => {
      if (item.children?.length) {
        const hasActiveChild = item.children.some(child => checkActive(child.href, path))
        if (hasActiveChild || checkActive(item.href, path)) {
          expandedMenus.value.add(item.id)
        }
      }
    })
  })
})
</script>
