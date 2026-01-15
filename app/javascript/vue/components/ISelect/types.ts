export interface SelectOption {
  value: string | number
  label: string
  disabled?: boolean
}

export type SelectMode = 'single' | 'multiple'

export interface ISelectProps {
  /** Valor selecionado (v-model) - string/number para single, array para multiple */
  modelValue: string | number | null | (string | number)[]
  /** Lista de opções */
  options: SelectOption[]
  /** Modo de seleção */
  mode?: SelectMode
  /** Label do campo */
  label?: string
  /** Placeholder */
  placeholder?: string
  /** Campo obrigatório */
  required?: boolean
  /** Campo desabilitado */
  disabled?: boolean
  /** Mensagem de erro */
  error?: string
  /** ID do campo */
  id?: string
  /** Habilitar pesquisa nas opções */
  searchable?: boolean
  /** Texto quando não há opções */
  emptyText?: string
  /** Texto de pesquisa placeholder */
  searchPlaceholder?: string
  /** Texto do botão de ação (se definido, mostra o botão) */
  actionLabel?: string
  /** Callback executado ao clicar no botão de ação */
  onAction?: () => void
}

export interface ISelectEmits {
  (e: 'update:modelValue', value: string | number | null | (string | number)[]): void
  (e: 'change', value: string | number | null | (string | number)[]): void
}
