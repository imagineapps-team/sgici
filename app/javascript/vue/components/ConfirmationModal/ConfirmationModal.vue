<script setup lang="ts">
import { computed } from 'vue'
import {
  CheckCircleIcon,
  ExclamationTriangleIcon,
  InformationCircleIcon,
  XCircleIcon
} from '@heroicons/vue/24/outline'
import {ConfirmationEmits, ConfirmationOptions} from "@/vue/components/ConfirmationModal/types.ts";
import IModal from "@/vue/components/IModal/IModal.vue";

const props = withDefaults(defineProps<ConfirmationOptions>(), {
  type: 'info',
  confirmText: 'Confirmar',
  cancelText: 'Cancelar',
  showIcon: true,
  focusConfirm: false,
  zIndex: 60
})

const emit = defineEmits<ConfirmationEmits>()

const modelValue = defineModel<boolean>({ required: true })

const iconComponent = computed(() => {
  const icons = {
    info: InformationCircleIcon,
    success: CheckCircleIcon,
    warning: ExclamationTriangleIcon,
    danger: XCircleIcon
  }
  return icons[props.type]
})

const iconColorClass = computed(() => {
  const colors = {
    info: 'text-blue-600',
    success: 'text-green-600',
    warning: 'text-yellow-600',
    danger: 'text-red-600'
  }
  return colors[props.type]
})

const iconBgClass = computed(() => {
  const bgColors = {
    info: 'bg-blue-100',
    success: 'bg-green-100',
    warning: 'bg-yellow-100',
    danger: 'bg-red-100'
  }
  return bgColors[props.type]
})

const confirmButtonClass = computed(() => {
  const buttonClasses = {
    info: 'bg-blue-600 hover:bg-blue-700 focus:ring-blue-500',
    success: 'bg-green-600 hover:bg-green-700 focus:ring-green-500',
    warning: 'bg-yellow-600 hover:bg-yellow-700 focus:ring-yellow-500',
    danger: 'bg-red-600 hover:bg-red-700 focus:ring-red-500'
  }
  return buttonClasses[props.type]
})

const handleConfirm = () => {
  emit('confirm')
  modelValue.value = false
}

const handleCancel = () => {
  emit('cancel')
  modelValue.value = false
}
</script>

<template>
  <IModal
      v-model="modelValue"
      size="sm"
      :closeOnClickOutside="false"
      :closeOnEscape="true"
      :showCloseButton="false"
      :zIndex="zIndex"
  >
    <div class="flex items-start gap-4">
      <div
          v-if="showIcon"
          :class="['flex-shrink-0 rounded-full p-3', iconBgClass]"
      >
        <component
            :is="iconComponent"
            :class="['w-6 h-6', iconColorClass]"
        />
      </div>

      <div class="flex-1 pt-1">
        <h3
            v-if="title"
            class="text-lg font-semibold text-gray-900 mb-2"
        >
          {{ title }}
        </h3>
        <p class="text-sm text-gray-600">
          {{ message }}
        </p>
      </div>
    </div>

    <template #footer>
      <button
          type="button"
          @click="handleCancel"
          class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 transition-colors"
      >
        {{ cancelText }}
      </button>
      <button
          type="button"
          @click="handleConfirm"
          :class="[
            'px-4 py-2 text-sm font-medium text-white rounded-md focus:outline-none focus:ring-2 focus:ring-offset-2 transition-colors',
            confirmButtonClass
          ]"
          :autofocus="focusConfirm"
      >
        {{ confirmText }}
      </button>
    </template>
  </IModal>
</template>
