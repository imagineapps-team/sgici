<script setup lang="ts">
import { computed, toRefs } from 'vue'
import { XMarkIcon } from '@heroicons/vue/24/outline'
import {DrawerEmits, DrawerProps} from "@/vue/components/IDrawer/types.ts";
import {useOverlay} from "@/vue/composables/useOverlay.ts";

const props = withDefaults(defineProps<DrawerProps>(), {
  position: 'right',
  size: 'md',
  closeOnClickOutside: true,
  closeOnEscape: true,
  showCloseButton: true,
  showOverlay: true,
  persistent: false,
  zIndex: 50,
  fullHeight: true
})

const emit = defineEmits<DrawerEmits>()

const { modelValue } = toRefs(props)

const { overlayRef, contentRef, handleClickOutside, close } = useOverlay(
    modelValue,
    {
      closeOnEscape: props.persistent ? false : props.closeOnEscape,
      closeOnClickOutside: props.persistent ? false : props.closeOnClickOutside,
      onClose: () => {
        if (!props.persistent) {
          emit('update:modelValue', false)
          emit('close')
        }
      }
    }
)

// Computed para classes de tamanho baseadas na posição
const sizeClasses = computed(() => {
  const isHorizontal = props.position === 'left' || props.position === 'right'
  const isVertical = props.position === 'top' || props.position === 'bottom'

  if (isHorizontal) {
    const widths = {
      sm: 'w-64',
      md: 'w-80',
      lg: 'w-96',
      xl: 'w-[32rem]',
      '2xl': 'w-[48rem]',
      '3xl': 'w-[64rem]',
      full: 'w-full'
    }
    return widths[props.size || 'md']
  }

  if (isVertical) {
    const heights = {
      sm: 'h-32',
      md: 'h-48',
      lg: 'h-64',
      xl: 'h-96',
      full: 'h-full'
    }
    return heights[props.size || 'md']
  }

  return ''
})

// Computed para classes de posição
const positionClasses = computed(() => {
  const positions = {
    left: 'left-0 top-0 bottom-0',
    right: 'right-0 top-0 bottom-0',
    top: 'top-0 left-0 right-0',
    bottom: 'bottom-0 left-0 right-0'
  }
  return positions[props.position || 'right']
})

// Computed para nome da transição baseado na posição
const transitionName = computed(() => {
  return `drawer-${props.position || 'right'}`
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

// Computed para direção do flex baseado na posição
const flexDirection = computed(() => {
  if (props.position === 'top' || props.position === 'bottom') {
    return 'flex-col'
  }
  return 'flex-col'
})

// Handlers para eventos
const handleTransitionBeforeEnter = () => {
  emit('before-open')
}

const handleTransitionAfterEnter = () => {
  emit('opened')
}

const handleTransitionBeforeLeave = () => {
  emit('before-close')
}

const handleTransitionAfterLeave = () => {
  emit('closed')
}

const handleClose = () => {
  if (!props.persistent) {
    close()
  }
}
</script>

<template>
  <Teleport to="body">
    <Transition
        name="drawer-overlay"
        @before-enter="handleTransitionBeforeEnter"
        @after-enter="handleTransitionAfterEnter"
        @before-leave="handleTransitionBeforeLeave"
        @after-leave="handleTransitionAfterLeave"
    >
      <div
          v-if="modelValue"
          ref="overlayRef"
          :class="[
          'fixed inset-0 drawer-container',
          zIndexClass,
          overlayClass
        ]"
      >
        <!-- Overlay -->
        <Transition name="drawer-backdrop">
          <div
              v-if="showOverlay && modelValue"
              class="absolute inset-0 bg-black/50"
              aria-hidden="true"
              @click="handleClickOutside"
          />
        </Transition>

        <!-- Drawer Content -->
        <Transition :name="transitionName">
          <div
              v-if="modelValue"
              ref="contentRef"
              :class="[
              'absolute bg-white shadow-2xl flex',
              flexDirection,
              positionClasses,
              sizeClasses,
              drawerClass
            ]"
              role="dialog"
              aria-modal="true"
              :aria-labelledby="title ? 'drawer-title' : undefined"
          >
            <!-- Header -->
            <div
                v-if="title || $slots.header || showCloseButton"
                class="flex items-center justify-between p-4 border-b border-gray-200 shrink-0"
            >
              <div class="flex-1">
                <slot name="header">
                  <h2
                      v-if="title"
                      id="drawer-title"
                      class="text-lg font-semibold text-gray-900"
                  >
                    {{ title }}
                  </h2>
                </slot>
              </div>

              <button
                  v-if="showCloseButton"
                  type="button"
                  class="ml-auto -m-2 p-2 text-gray-400 hover:text-gray-500 rounded-lg transition-colors"
                  aria-label="Fechar"
                  @click="handleClose"
              >
                <XMarkIcon class="w-5 h-5" />
              </button>
            </div>

            <!-- Body -->
            <div class="flex-1 overflow-y-auto p-4">
              <slot />
            </div>

            <!-- Footer -->
            <div
                v-if="$slots.footer"
                class="flex items-center justify-end gap-3 p-4 border-t border-gray-200 shrink-0"
            >
              <slot name="footer" />
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<!-- Transições com animações CSS puras -->
<style>
/* Sobrescreve o background branco do CSS global */
.drawer-container {
  background: transparent !important;
}

/* Transição do overlay */
.drawer-overlay-enter-active,
.drawer-overlay-leave-active {
  transition: opacity 0.3s ease;
}

.drawer-overlay-enter-from,
.drawer-overlay-leave-to {
  opacity: 0;
}

/* Transição do backdrop */
.drawer-backdrop-enter-active,
.drawer-backdrop-leave-active {
  transition: opacity 0.3s ease;
}

.drawer-backdrop-enter-from,
.drawer-backdrop-leave-to {
  opacity: 0;
}

/* Transições para drawer à esquerda */
.drawer-left-enter-active,
.drawer-left-leave-active {
  transition: transform 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.drawer-left-enter-from {
  transform: translateX(-100%);
}

.drawer-left-enter-to {
  transform: translateX(0);
}

.drawer-left-leave-from {
  transform: translateX(0);
}

.drawer-left-leave-to {
  transform: translateX(-100%);
}

/* Transições para drawer à direita */
.drawer-right-enter-active,
.drawer-right-leave-active {
  transition: transform 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.drawer-right-enter-from {
  transform: translateX(100%);
}

.drawer-right-enter-to {
  transform: translateX(0);
}

.drawer-right-leave-from {
  transform: translateX(0);
}

.drawer-right-leave-to {
  transform: translateX(100%);
}

/* Transições para drawer no topo */
.drawer-top-enter-active,
.drawer-top-leave-active {
  transition: transform 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.drawer-top-enter-from {
  transform: translateY(-100%);
}

.drawer-top-enter-to {
  transform: translateY(0);
}

.drawer-top-leave-from {
  transform: translateY(0);
}

.drawer-top-leave-to {
  transform: translateY(-100%);
}

/* Transições para drawer embaixo */
.drawer-bottom-enter-active,
.drawer-bottom-leave-active {
  transition: transform 0.3s cubic-bezier(0.25, 0.8, 0.25, 1);
}

.drawer-bottom-enter-from {
  transform: translateY(100%);
}

.drawer-bottom-enter-to {
  transform: translateY(0);
}

.drawer-bottom-leave-from {
  transform: translateY(0);
}

.drawer-bottom-leave-to {
  transform: translateY(100%);
}
</style>