import { formatCpf } from './formatCpf'
import { formatCnpj } from './formatCnpj'

/**
 * Formata CPF ou CNPJ automaticamente baseado no tamanho
 * CPF: 11 dígitos -> XXX.XXX.XXX-XX
 * CNPJ: 14 dígitos -> XX.XXX.XXX/XXXX-XX
 */
export function formatCpfCnpj(value: string | null | undefined): string {
  if (!value) return ''

  const cleaned = value.replace(/\D/g, '')

  if (cleaned.length === 11) {
    return formatCpf(cleaned)
  }

  if (cleaned.length === 14) {
    return formatCnpj(cleaned)
  }

  return value
}
