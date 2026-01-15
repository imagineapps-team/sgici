export type InputType = 'text' | 'number' | 'date' | 'money' | 'cpf_cnpj' | 'email' | 'password' | 'tel'

export interface IInputProps {
  /** Valor do input (v-model) */
  modelValue: string | number | null
  /** Tipo do input */
  type?: InputType
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
  /** Tamanho máximo de caracteres */
  maxlength?: number
  /** Valor mínimo (para number) */
  min?: number
  /** Valor máximo (para number) */
  max?: number
  /** Passo (para number) */
  step?: number
}

export interface IInputEmits {
  (e: 'update:modelValue', value: string | number | null): void
  (e: 'blur', event: FocusEvent): void
  (e: 'focus', event: FocusEvent): void
}
