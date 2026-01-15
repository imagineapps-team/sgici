export type ModalSize = 'sm' | 'md' | 'lg' | 'xl' | 'full'

export interface ModalProps {
    /**
     * Controla a visibilidade do modal
     */
    modelValue: boolean

    /**
     * Título do modal (opcional - pode usar slot)
     */
    title?: string

    /**
     * Tamanho do modal
     * @default 'md'
     */
    size?: ModalSize

    /**
     * Se true, fecha ao clicar fora do modal
     * @default true
     */
    closeOnClickOutside?: boolean

    /**
     * Se true, fecha ao pressionar ESC
     * @default true
     */
    closeOnEscape?: boolean

    /**
     * Se true, mostra o botão de fechar (X)
     * @default true
     */
    showCloseButton?: boolean

    /**
     * Se true, mostra o overlay escuro atrás do modal
     * @default true
     */
    showOverlay?: boolean

    /**
     * Classes customizadas para o container do modal
     */
    modalClass?: string

    /**
     * Classes customizadas para o overlay
     */
    overlayClass?: string

    /**
     * Se true, o modal não pode ser fechado
     * @default false
     */
    persistent?: boolean

    /**
     * Z-index customizado
     * @default 50
     */
    zIndex?: number

    /**
     * Se true, remove padding do body e habilita flex layout
     * @default false
     */
    noPadding?: boolean
}

export interface ModalEmits {
    /**
     * Emitido quando o modal é fechado
     */
    'onClose': [value: boolean]

    /**
     * Emitido antes do modal abrir
     */
    'before-open': []

    /**
     * Emitido depois do modal abrir
     */
    'opened': []

    /**
     * Emitido antes do modal fechar
     */
    'before-close': []

    /**
     * Emitido depois do modal fechar
     */
    'closed': []

    /**
     * Emitido para atualizar o v-model
     */
    'update:modelValue': [value: boolean]
}