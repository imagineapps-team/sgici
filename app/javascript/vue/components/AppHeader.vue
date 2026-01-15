<template>
  <header class="fixed top-0 left-0 right-0 h-16 bg-brand-primary text-white z-50 shadow-md">
    <div class="flex items-center justify-between h-full px-4">
      <div class="flex items-center gap-4">
        <button
          type="button"
          class="p-2 rounded-md text-white/80 hover:text-white hover:bg-white/10"
          @click="$emit('toggle-sidebar')"
        >
          <Bars3Icon class="h-6 w-6" />
        </button>
        <div class="flex items-center gap-2">
          <div class="w-8 h-8 bg-white/20 rounded-lg flex items-center justify-center">
            <BoltIcon class="h-5 w-5" />
          </div>
          <span class="text-xl font-semibold">{{ appName }}</span>
          <span
            v-if="tenantName"
            class="px-2 py-0.5 text-xs font-medium bg-white/20 rounded-full"
          >
            {{ tenantName }}
          </span>
        </div>
      </div>

      <div class="flex items-center gap-4">
        <span class="text-sm text-white/80">{{ usuario.nome }}</span>
        <div class="relative" ref="dropdownRef">
          <button
            type="button"
            class="flex items-center gap-2 p-2 rounded-md text-white/80 hover:text-white hover:bg-white/10"
            @click="dropdownOpen = !dropdownOpen"
          >
            <UserCircleIcon class="h-8 w-8" />
            <ChevronDownIcon class="h-4 w-4" />
          </button>

          <div
            v-if="dropdownOpen"
            class="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg border border-gray-200 py-1"
          >
            <Link
              href="/logout"
              method="delete"
              as="button"
              class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
            >
              <ArrowRightOnRectangleIcon class="h-4 w-4" />
              Sair
            </Link>
          </div>
        </div>
      </div>
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { Link } from '@inertiajs/vue3'
import { onClickOutside } from '@vueuse/core'
import {
  Bars3Icon,
  UserCircleIcon,
  ChevronDownIcon,
  ArrowRightOnRectangleIcon,
  BoltIcon
} from '@heroicons/vue/24/outline'
import type { UserInfo } from '../types/navigation'

interface Props {
  usuario: UserInfo
  appName?: string
  tenantName?: string | null
}

withDefaults(defineProps<Props>(), {
  appName: 'AVSI Ecoenel',
  tenantName: null
})

defineEmits<{
  'toggle-sidebar': []
}>()

const dropdownOpen = ref(false)
const dropdownRef = ref<HTMLElement | null>(null)

onClickOutside(dropdownRef, () => {
  dropdownOpen.value = false
})
</script>
