<template>
  <Teleport to="body">
    <div class="fixed top-6 left-1/2 -translate-x-1/2 z-[100] flex flex-col items-center gap-3 pointer-events-none">
      <TransitionGroup name="toast">
        <div
          v-for="notification in notifications"
          :key="notification.id"
          :class="[
            'pointer-events-auto flex items-center gap-3 px-5 py-3.5 rounded-xl shadow-2xl backdrop-blur-sm',
            typeClasses[notification.type]
          ]"
          role="alert"
        >
          <div :class="['flex items-center justify-center w-8 h-8 rounded-full', iconBgClasses[notification.type]]">
            <component
              :is="typeIcons[notification.type]"
              :class="['h-5 w-5', iconClasses[notification.type]]"
            />
          </div>
          <p class="text-sm font-medium text-gray-800 max-w-sm">{{ notification.message }}</p>
          <button
            type="button"
            class="flex-shrink-0 ml-2 p-1 rounded-full text-gray-400 hover:text-gray-600 hover:bg-gray-100 transition-all"
            @click="removeNotification(notification.id)"
          >
            <XMarkIcon class="h-4 w-4" />
          </button>
        </div>
      </TransitionGroup>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { watch } from 'vue'
import {
  CheckCircleIcon,
  ExclamationCircleIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon,
  XMarkIcon
} from '@heroicons/vue/24/solid'
import { useNotifications, type Notification } from '../../composables/useNotification'

const { notifications, removeNotification } = useNotifications()

const typeClasses: Record<Notification['type'], string> = {
  success: 'bg-white/95 border border-emerald-100 ring-1 ring-emerald-500/10',
  error: 'bg-white/95 border border-rose-100 ring-1 ring-rose-500/10',
  warning: 'bg-white/95 border border-amber-100 ring-1 ring-amber-500/10',
  alert: 'bg-white/95 border border-orange-100 ring-1 ring-orange-500/10',
  notice: 'bg-white/95 border border-sky-100 ring-1 ring-sky-500/10'
}

const iconBgClasses: Record<Notification['type'], string> = {
  success: 'bg-emerald-100',
  error: 'bg-rose-100',
  warning: 'bg-amber-100',
  alert: 'bg-orange-100',
  notice: 'bg-sky-100'
}

const iconClasses: Record<Notification['type'], string> = {
  success: 'text-emerald-600',
  error: 'text-rose-600',
  warning: 'text-amber-600',
  alert: 'text-orange-600',
  notice: 'text-sky-600'
}

const typeIcons: Record<Notification['type'], typeof CheckCircleIcon> = {
  success: CheckCircleIcon,
  error: ExclamationCircleIcon,
  warning: ExclamationTriangleIcon,
  alert: ExclamationTriangleIcon,
  notice: InformationCircleIcon
}

// Auto-remove após duração
const processedIds = new Set<number>()

watch(
  () => notifications.value.length,
  () => {
    notifications.value.forEach((notification) => {
      if (notification.duration && notification.duration > 0 && !processedIds.has(notification.id)) {
        processedIds.add(notification.id)
        setTimeout(() => {
          removeNotification(notification.id)
          processedIds.delete(notification.id)
        }, notification.duration)
      }
    })
  },
  { immediate: true }
)
</script>

<style scoped>
.toast-enter-active {
  transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

.toast-leave-active {
  transition: all 0.3s cubic-bezier(0.4, 0, 1, 1);
}

.toast-enter-from {
  opacity: 0;
  transform: translateY(-20px) scale(0.95);
}

.toast-leave-to {
  opacity: 0;
  transform: translateY(-10px) scale(0.98);
}

.toast-move {
  transition: transform 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}
</style>
