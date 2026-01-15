import { ref, onMounted, onUnmounted, watch, type Ref } from 'vue'

export function useOverlay(isVisible: Ref<boolean>, options: {
    closeOnEscape?: boolean
    closeOnClickOutside?: boolean
    onClose?: () => void
} = {}) {
    const overlayRef = ref<HTMLElement | null>(null)
    const contentRef = ref<HTMLElement | null>(null)
    const lastActiveElement = ref<HTMLElement | null>(null)

    // Bloqueia o scroll do body quando o overlay está visível
    const toggleBodyScroll = (disable: boolean) => {
        if (disable) {
            document.body.style.overflow = 'hidden'
        } else {
            document.body.style.overflow = ''
        }
    }

    // Fecha o overlay
    const close = () => {
        if (options.onClose) {
            options.onClose()
        }
    }

    // Handler para tecla ESC
    const handleKeydown = (e: KeyboardEvent) => {
        if (options.closeOnEscape !== false && e.key === 'Escape' && isVisible.value) {
            e.preventDefault()
            close()
        }
    }

    // Handler para clique fora
    const handleClickOutside = (e: MouseEvent) => {
        if (
            options.closeOnClickOutside !== false &&
            overlayRef.value &&
            contentRef.value &&
            !contentRef.value.contains(e.target as Node)
        ) {
            close()
        }
    }

    // Focus trap - mantém o foco dentro do modal/drawer
    const trapFocus = (e: KeyboardEvent) => {
        if (!isVisible.value || !contentRef.value) return

        if (e.key !== 'Tab') return

        const focusableElements = contentRef.value.querySelectorAll<HTMLElement>(
            'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'
        )

        const firstFocusable = focusableElements[0]
        const lastFocusable = focusableElements[focusableElements.length - 1]

        if (e.shiftKey && document.activeElement === firstFocusable) {
            lastFocusable?.focus()
            e.preventDefault()
        } else if (!e.shiftKey && document.activeElement === lastFocusable) {
            firstFocusable?.focus()
            e.preventDefault()
        }
    }

    // Setup e cleanup dos event listeners
    onMounted(() => {
        if (options.closeOnEscape !== false) {
            document.addEventListener('keydown', handleKeydown)
        }
        document.addEventListener('keydown', trapFocus)
    })

    onUnmounted(() => {
        document.removeEventListener('keydown', handleKeydown)
        document.removeEventListener('keydown', trapFocus)
        toggleBodyScroll(false) // Garante que o scroll seja restaurado
    })

    // Watch para mudanças na visibilidade
    watch(isVisible, (newValue) => {
        toggleBodyScroll(newValue)

        if (newValue) {
            // Salva o elemento ativo atual
            lastActiveElement.value = document.activeElement as HTMLElement

            // Focus no primeiro elemento focável após um pequeno delay
            setTimeout(() => {
                if (contentRef.value) {
                    const firstFocusable = contentRef.value.querySelector<HTMLElement>(
                        'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])'
                    )
                    firstFocusable?.focus()
                }
            }, 50)
        } else {
            // Restaura o focus para o elemento anterior
            lastActiveElement.value?.focus()
        }
    })

    return {
        overlayRef,
        contentRef,
        handleClickOutside,
        close
    }
}