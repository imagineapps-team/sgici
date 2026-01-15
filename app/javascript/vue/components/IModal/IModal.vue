<script setup lang="ts">
import { computed } from 'vue'
import { XMarkIcon } from '@heroicons/vue/24/outline'
import type { ModalProps, ModalEmits } from './types.ts'
import {useOverlay} from "@/vue/composables/useOverlay.ts";

const props = withDefaults(defineProps<ModalProps>(), {
  size: 'md',
  closeOnClickOutside: true,
  closeOnEscape: true,
  showCloseButton: true,
  showOverlay: true,
  persistent: false,
  zIndex: 50
})

const emit = defineEmits<ModalEmits>()

const modelValue = defineModel<boolean>({ required: true })

const { overlayRef, contentRef, handleClickOutside, close } = useOverlay(
    modelValue,
    {
      closeOnEscape: props.persistent ? false : props.closeOnEscape,
      closeOnClickOutside: props.persistent ? false : props.closeOnClickOutside,
      onClose: () => {
        if (!props.persistent) {
          modelValue.value = false
          emit('onClose', false)
        }
      }
    }
)

// Computed para classes de tamanho do modal
const sizeClasses = computed(() => {
  const sizes = {
    sm: 'max-w-md',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl',
    full: 'max-w-7xl'
  }
  return sizes[props.size || 'md']
})

// Computed para classes de z-index
const zIndexClass = computed(() => {
  const zIndexMap: Record<number, string> = {
    10: 'z-10',
    20: 'z-20',
    30: 'z-30',
    40: 'z-40',
    50: 'z-50',
    60: 'z-60'
  }
  return zIndexMap[props.zIndex] || 'z-50'
})

const handleClose = () => {
  if (!props.persistent) {
    modelValue.value = false
  }
}
</script>

<template>
  <Teleport to="body">
    <!-- Overlay Background -->
    <Transition name="modal-overlay">
      <div
          v-if="modelValue && showOverlay"
          :class="['fixed inset-0 modal-overlay-bg', zIndexClass]"
          @click="handleClickOutside"
      />
    </Transition>

    <!-- Modal Container -->
    <Transition name="modal-content">
      <div
          v-if="modelValue"
          :class="['fixed inset-0 flex items-center justify-center p-4 modal-container', zIndexClass]"
          ref="overlayRef"
      >
        <div
            ref="contentRef"
            :class="[
            'relative bg-white rounded-lg shadow-xl w-full',
            sizeClasses,
            modalClass
          ]"
            role="dialog"
            aria-modal="true"
            :aria-labelledby="title ? 'modal-title' : undefined"
            @click.stop
        >
          <!-- Header -->
          <div
              v-if="title || $slots.header || showCloseButton"
              class="flex items-start justify-between p-5 border-b border-gray-200"
          >
            <div class="flex-1">
              <slot name="header">
                <h3
                    v-if="title"
                    id="modal-title"
                    class="text-lg font-semibold text-gray-900"
                >
                  {{ title }}
                </h3>
              </slot>
            </div>

            <button
                v-if="showCloseButton"
                type="button"
                class="ml-auto -m-2 p-2 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-brand-primary rounded-lg transition-colors"
                aria-label="Fechar"
                @click="handleClose"
            >
              <XMarkIcon class="w-5 h-5" />
            </button>
          </div>

          <!-- Body -->
          <div :class="props.noPadding ? 'flex-1 flex flex-col' : 'p-6'">
            <slot />
          </div>

          <!-- Footer -->
          <div
              v-if="$slots.footer"
              class="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-200"
          >
            <slot name="footer" />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style>
/* Sobrescreve o background branco global da classe .fixed */
.modal-overlay-bg {
  background-color: rgba(0, 0, 0, 0.5) !important;
}

.modal-container {
  background: transparent !important;
}


/* Transição do overlay */
.modal-overlay-enter-active,
.modal-overlay-leave-active {
  transition: opacity 0.3s ease;
}

.modal-overlay-enter-from,
.modal-overlay-leave-to {
  opacity: 0;
}

/* Transição do conteúdo do modal */
.modal-content-enter-active {
  transition: all 0.3s ease;
}

.modal-content-leave-active {
  transition: all 0.2s ease;
}

.modal-content-enter-from {
  opacity: 0;
  transform: scale(0.95) translateY(10px);
}

.modal-content-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>