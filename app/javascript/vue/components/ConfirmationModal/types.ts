export type ConfirmationType = 'info' | 'success' | 'warning' | 'danger'

export interface ConfirmationOptions {
    /**
     * Título do modal de confirmação
     */
    title?: string

    /**
     * Mensagem principal a ser exibida
     */
    message: string

    /**
     * Texto do botão de confirmação
     * @default 'Confirmar'
     */
    confirmText?: string

    /**
     * Texto do botão de cancelamento
     * @default 'Cancelar'
     */
    cancelText?: string

    /**
     * Tipo visual do modal (afeta cores e ícone)
     * @default 'info'
     */
    type?: ConfirmationType

    /**
     * Se true, mostra ícone no modal
     * @default true
     */
    showIcon?: boolean

    /**
     * Se true, o botão de confirmação fica em foco
     * @default false
     */
    focusConfirm?: boolean

    /**
     * z-index do modal (útil para sobrepor outros modais/drawers)
     * @default 60
     */
    zIndex?: 10 | 20 | 30 | 40 | 50 | 60
}

export interface ConfirmationEmits {
    confirm: []
    cancel: []
}
