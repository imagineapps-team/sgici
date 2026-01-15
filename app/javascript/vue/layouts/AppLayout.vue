<template>
  <BrandingProvider>
    <div class="min-h-screen bg-gray-100">
      <AppHeader :usuario="usuario" :app-name="appName" :tenant-name="tenantName" @toggle-sidebar="sidebarOpen = !sidebarOpen" />
      <SidebarMenu :sections="filteredMenuSections" :is-open="sidebarOpen" />

      <div
        v-if="sidebarOpen"
        class="fixed inset-0 bg-black bg-opacity-50 z-30 lg:hidden"
        @click="sidebarOpen = false"
      />

      <main
        class="pt-16 transition-all duration-300"
        :class="sidebarOpen ? 'lg:ml-64' : ''"
      >
        <div class="p-6">
          <slot />
        </div>
      </main>

      <!-- Global Loading Overlay -->
      <ILoading />

      <!-- Global Toast Notifications -->
      <IToast />
    </div>
  </BrandingProvider>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { usePage } from '@inertiajs/vue3'
import AppHeader from '../components/AppHeader.vue'
import SidebarMenu from '../components/SidebarMenu.vue'
import BrandingProvider from '../components/BrandingProvider.vue'
import { ILoading } from '../components/ILoading'
import { IToast } from '../components/IToast'
import { menuSections, filterMenuByPermissions } from '../config/menu'
import { useNotifications } from '../composables/useNotification'
import { setupInertiaErrorHandler } from '../plugins/inertiaErrorHandler'
import { useBranding } from '../composables/useBranding'
import type { UserInfo } from '../types/navigation'

interface Props {
  usuario: UserInfo
}

defineProps<Props>()

const { appName } = useBranding()
const sidebarOpen = ref(true)
const page = usePage()

// Multi-tenancy: nome da regional atual (SP, CE) - só para EcoEnel
const tenantName = computed(() => page.props.tenantName as string | null)

// Filtra menu baseado nas permissoes do usuario
const filteredMenuSections = computed(() => {
  const allowedPaths = page.props.allowedPaths as string[] | null | undefined
  return filterMenuByPermissions(menuSections, allowedPaths ?? null)
})

// Setup global error handler
onMounted(() => {
  setupInertiaErrorHandler()
})

// Flash messages -> Toast notifications
const { success, error, notice, alert } = useNotifications()

const processedFlash = ref<string | null>(null)

watch(
  () => page.props.flash as Record<string, string> | undefined,
  (newFlash) => {
    if (!newFlash) return

    // Cria hash do flash para evitar duplicatas
    const flashHash = JSON.stringify(newFlash)
    if (flashHash === processedFlash.value || flashHash === '{}') return

    processedFlash.value = flashHash

    if (newFlash.notice) {
      success(newFlash.notice)
    }
    if (newFlash.alert) {
      error(newFlash.alert)
    }
    if (newFlash.warning) {
      alert(newFlash.warning)
    }
    if (newFlash.error) {
      error(newFlash.error)
    }
  },
  { immediate: true }
)
</script>
