export type DrawerPosition = 'left' | 'right' | 'top' | 'bottom'
export type DrawerSize = 'sm' | 'md' | 'lg' | 'xl' | '2xl' | '3xl' | 'full'

export interface DrawerProps {
    /**
     * Controla a visibilidade do drawer
     */
    modelValue: boolean

    /**
     * Título do drawer (opcional - pode usar slot)
     */
    title?: string

    /**
     * Posição do drawer na tela
     * @default 'right'
     */
    position?: DrawerPosition

    /**
     * Tamanho do drawer
     * @default 'md'
     */
    size?: DrawerSize

    /**
     * Se true, fecha ao clicar fora do drawer
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
     * Se true, mostra o overlay escuro atrás do drawer
     * @default true
     */
    showOverlay?: boolean

    /**
     * Classes customizadas para o container do drawer
     */
    drawerClass?: string

    /**
     * Classes customizadas para o overlay
     */
    overlayClass?: string

    /**
     * Se true, o drawer não pode ser fechado
     * @default false
     */
    persistent?: boolean

    /**
     * Z-index customizado
     * @default 50
     */
    zIndex?: number

    /**
     * Se true, o drawer ocupa toda a altura/largura disponível
     * @default true
     */
    fullHeight?: boolean
}

export interface DrawerEmits {
    /**
     * Emitido quando o drawer é fechado
     */
    (e: 'update:modelValue', value: boolean): void

    /**
     * Alias para update:modelValue (compatibilidade)
     */
    (e: 'close'): void

    /**
     * Emitido antes do drawer abrir
     */
    (e: 'before-open'): void

    /**
     * Emitido depois do drawer abrir
     */
    (e: 'opened'): void

    /**
     * Emitido antes do drawer fechar
     */
    (e: 'before-close'): void

    /**
     * Emitido depois do drawer fechar
     */
    (e: 'closed'): void
}